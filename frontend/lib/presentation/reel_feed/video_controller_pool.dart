// Controller pool. Keeps {prev, active, next}, but only the active slot
// actually decodes — neighbors are paused after init so we don't oversubscribe
// the hardware codec. Tried this naively once and ate 14 c2.qti.avc.decoder
// failures before realizing the failures only happened when all three were
// *playing* during a fast-scroll transition.
//
// Active starts initialize() first; neighbors deferred via microtask so they
// don't steal the first network slice. setActive() awaits only the active
// slot's ready future before play().
//
// Caller responsibilities: pauseActive() on background, disposeAll() on screen
// dispose, and don't fire setActive() per-page-change — debounce via the
// screen's 150ms scroll-settle.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';

import '../../main.dart' show kAppStartedAt;

class _Slot {
  final int index;
  final VideoPlayerController controller;
  Future<void> ready;
  bool disposed = false;
  // Fires when this slot is disposed so any concurrent `await s.ready` can race
  // and bail out. Without this, fast-scrolling past a slot that hasn't started
  // initialize() yet leaves the ready Future pending forever — disposing the
  // controller mid-init does NOT settle the platform initialize() future on
  // some Android builds.
  final Completer<void> disposeSignal = Completer<void>();

  _Slot(this.index, this.controller, this.ready);
}

class VideoControllerPool {
  final int backwardPreload;
  final int forwardPreload;
  final List<_Slot> _slots = [];
  int _activeIndex = -1;
  bool _firstPlayLogged = false;
  // Position-per-index so navigating away and back resumes mid-reel.
  final Map<int, Duration> _resumeByIndex = {};
  // One-shot retry guard — if a slot's hasError survives the first recreate,
  // we stop trying. Otherwise a permanently-bad URL would hang the pool.
  final Set<int> _retriedSlots = <int>{};

  VideoControllerPool({
    this.backwardPreload = 1,
    this.forwardPreload = 1,
  });

  VideoPlayerController? controllerAt(int index) =>
      _slots.firstWhereOrNull((s) => s.index == index)?.controller;

  Future<void>? readyAt(int index) =>
      _slots.firstWhereOrNull((s) => s.index == index)?.ready;

  Future<void> setActive(int index, List<String> urls) async {
    _activeIndex = index;

    final wantedIndices = <int>{
      for (int i = index - backwardPreload; i <= index + forwardPreload; i++)
        if (i >= 0 && i < urls.length) i,
    };

    final disposedNow = <int>[];
    _slots.removeWhere((s) {
      if (!wantedIndices.contains(s.index)) {
        try {
          if (s.controller.value.isInitialized) {
            _resumeByIndex[s.index] = s.controller.value.position;
          }
        } catch (_) {}
        disposedNow.add(s.index);
        s.disposed = true;
        // Unblock any concurrent setActive awaiting this slot's ready BEFORE
        // disposing the controller, otherwise a pending platform initialize()
        // future never settles and those awaits deadlock forever.
        if (!s.disposeSignal.isCompleted) s.disposeSignal.complete();
        s.controller.dispose();
        return true;
      }
      return false;
    });

    // Active inits inline; neighbors are deferred by one microtask so they
    // don't compete with the active slot for DNS/TLS/first bytes.
    final createdNow = <int>[];
    final sortedToCreate = wantedIndices
        .where((i) => !_slots.any((s) => s.index == i))
        .toList()
      ..sort((a, b) {
        if (a == index) return -1;
        if (b == index) return 1;
        return a.compareTo(b);
      });
    for (final i in sortedToCreate) {
      createdNow.add(i);
      final controller = VideoPlayerController.networkUrl(Uri.parse(urls[i]));
      final shortUrl =
          urls[i].length > 60 ? '...${urls[i].substring(urls[i].length - 60)}' : urls[i];
      late final Future<void> ready;
      if (i == index) {
        final initStart = DateTime.now();
        ready = controller.initialize().then((_) {
          controller.setLooping(true);
          final ms = DateTime.now().difference(initStart).inMilliseconds;
          final tag = ms > 3000 ? '🐢 SLOW' : '✓';
          final dur = controller.value.duration;
          final durTag = dur <= Duration.zero ? '⚠ ZERO' : '${dur.inSeconds}s';
          debugPrint('[pool]   $tag initialized #$i (active) in ${ms}ms  player_dur=$durTag — $shortUrl');
        }).catchError((e, st) {
          debugPrint('[pool]   ✗ init failed for #$i ($shortUrl): $e');
        });
      } else {
        ready = Future.microtask(() {
          final initStart = DateTime.now();
          return controller.initialize().then((_) {
            controller.setLooping(true);
            final ms = DateTime.now().difference(initStart).inMilliseconds;
            final tag = ms > 3000 ? '🐢 SLOW' : '✓';
            final dur = controller.value.duration;
            final durTag = dur <= Duration.zero ? '⚠ ZERO' : '${dur.inSeconds}s';
            debugPrint('[pool]   $tag initialized #$i (preload) in ${ms}ms  player_dur=$durTag — $shortUrl');
          }).catchError((e, st) {
            debugPrint('[pool]   ✗ init failed for #$i ($shortUrl): $e');
          });
        });
      }
      _slots.add(_Slot(i, controller, ready));
    }

    final inPool = _slots.map((s) => s.index).toList()..sort();
    debugPrint(
      '[pool] active=$index  size=${_slots.length}  window=$inPool'
      '${createdNow.isNotEmpty ? '  +created=$createdNow' : ''}'
      '${disposedNow.isNotEmpty ? '  -disposed=$disposedNow' : ''}',
    );

    // Snapshot _slots before iterating. If disposeAll() runs concurrently
    // (user taps a navigation while we're mid-await), it clears _slots and
    // a live for-each would throw ConcurrentModificationError. The snapshot
    // is just a list of references; the per-slot s.disposed guard handles
    // mutation of individual slots inside the loop.
    final slotsSnapshot = List<_Slot>.from(_slots);
    // Activate the right one. Pause the others.
    for (final s in slotsSnapshot) {
      if (s.disposed) continue;
      if (s.index == index) {
        final waitStart = DateTime.now();
        // Race against disposeSignal — if a later setActive disposes this
        // slot mid-init, we'd otherwise hang forever.
        await Future.any([s.ready, s.disposeSignal.future]);
        final waitMs = DateTime.now().difference(waitStart).inMilliseconds;
        if (!s.disposed) {
          // initialize() can resolve "successfully" while the underlying codec
          // failed (hasError set, no surface). Recreate once before giving up.
          if (s.controller.value.hasError && _retriedSlots.add(s.index)) {
            debugPrint(
                '[pool]   ⚠ decoder error on #$index after init — recreating once: ${s.controller.value.errorDescription}');
            try { await s.controller.dispose(); } catch (_) {}
            _slots.remove(s);
            return setActive(index, urls);
          }
          final resumeAt = _resumeByIndex[index] ?? Duration.zero;
          final dur = s.controller.value.duration;
          // Clamp in case the saved position is past the end (metadata change).
          final clamped = (dur > Duration.zero && resumeAt > dur)
              ? Duration.zero
              : resumeAt;
          if (clamped != Duration.zero) {
            try {
              await s.controller.seekTo(clamped);
            } catch (_) {}
          }
          await s.controller.play();
          debugPrint('[pool]   ▶ playing #$index '
              '(waited ${waitMs}ms — 0 means already buffered)');
          if (!_firstPlayLogged) {
            _firstPlayLogged = true;
            final cold = DateTime.now().difference(kAppStartedAt).inMilliseconds;
            debugPrint(
                '[startup] 🚀 cold start to first reel playing: ${cold}ms (target <2000ms)');
          }
        }
      } else {
        try {
          await Future.any([s.ready, s.disposeSignal.future]);
          if (!s.disposed) {
            if (s.controller.value.isInitialized) {
              _resumeByIndex[s.index] = s.controller.value.position;
            }
            await s.controller.pause();
          }
        } catch (_) {}
      }
    }
  }

  Future<void> pauseActive() async {
    final s = _slots.firstWhereOrNull((s) => s.index == _activeIndex);
    if (s != null && !s.disposed) {
      try {
        if (s.controller.value.isInitialized) {
          _resumeByIndex[s.index] = s.controller.value.position;
        }
        await s.controller.pause();
      } catch (_) {}
    }
  }

  Future<void> resumeActive() async {
    final s = _slots.firstWhereOrNull((s) => s.index == _activeIndex);
    if (s != null && !s.disposed) {
      try {
        await Future.any([s.ready, s.disposeSignal.future]);
        if (!s.disposed) await s.controller.play();
      } catch (_) {}
    }
  }

  Future<void> disposeAll() async {
    // Two-phase dispose. The screen has live ValueListenableBuilders pointing
    // at these controllers; if we tore them down right now, the next frame's
    // widget unmounts would call removeListener on a disposed ChangeNotifier
    // and throw "used after being disposed."
    //
    // Phase 1 (sync): clear _slots and set disposed=true. controllerAt() now
    // returns null, so the next build removes the conditional widgets cleanly.
    // Persist resume positions before we lose access to the controllers.
    final toDispose = List<_Slot>.from(_slots);
    _slots.clear();
    for (final s in toDispose) {
      s.disposed = true;
      if (!s.disposeSignal.isCompleted) s.disposeSignal.complete();
      try {
        if (s.controller.value.isInitialized) {
          _resumeByIndex[s.index] = s.controller.value.position;
        }
      } catch (_) {}
    }
    // Phase 2 (post-frame): controller.dispose() runs after the framework has
    // unmounted any widgets that were listening to these controllers.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      for (final s in toDispose) {
        try {
          s.controller.dispose();
        } catch (_) {}
      }
    });
  }

  /// Used for assertions during tests / profiling.
  int get activeControllerCount => _slots.length;
}

extension _FirstWhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
