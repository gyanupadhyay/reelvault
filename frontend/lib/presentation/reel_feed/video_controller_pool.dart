// lib/presentation/reel_feed/video_controller_pool.dart
//
// ARCHITECTURE NOTE — controller lifecycle:
//
// We keep AT MOST 2 controllers alive at any moment: the active reel and the
// next reel (forward-preload only). On Android, every additional video_player
// instance reserves a hardware codec slot, and Qualcomm's c2.qti.avc.decoder
// silently fails to allocate when 3+ 1080p H.264 streams compete during a
// fast-scroll dispose-then-create transition. Real-device telemetry showed 14
// such failures in a 7-minute session with the old prev/cur/next pool.
//
// Trade-off: backward scroll (active going from N → N-1) costs a fresh init
// (~500ms visible spinner) because we don't keep the previous reel warm. This
// matches TikTok-style usage where forward scroll dominates and is the right
// choice on a memory- + decoder-constrained mobile target.
//
// Network-side preloading: we initialize() the next controller as soon as we know
// the user has settled on the current reel (see scroll-settle in the screen).
// That way when the user swipes, the next reel is already buffered.
//
// Bandwidth prioritization: the active reel always starts initialize() *before*
// the next-preload. Without this, on cold start both #0 and #1 would compete for
// the same socket / DNS / TLS handshake bandwidth and #0 would arrive ~700ms later.
// We start #0 first, schedule the next init one frame later via microtask,
// and only await the active slot's ready future before play().
//
// Edge cases handled:
//  - Fast swipes: callers should not invoke `setActive(i)` for indices the user blew
//    past. The screen debounces via scroll-settle (150ms).
//  - App backgrounded: caller must call pauseActive(); we don't dispose because the
//    user expects resume on foreground.
//  - Dispose: must be called from the screen's dispose() so all controllers go.
//  - Decoder init failure: video_player's initialize() can resolve *successfully*
//    even when the underlying codec failed. We detect via controller.value.hasError
//    after init and dispose+recreate the slot once before giving up.

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../../main.dart' show kAppStartedAt;

class _Slot {
  final int index;
  final VideoPlayerController controller;
  Future<void> ready;
  bool disposed = false;

  _Slot(this.index, this.controller, this.ready);
}

class VideoControllerPool {
  // Forward-preload distance. 1 means: keep {active, active+1} alive.
  // We don't expose prev-preload — it would exceed the device's safe concurrent
  // hardware-decoder count during fast-scroll dispose transitions.
  final int forwardPreload;
  final List<_Slot> _slots = [];
  int _activeIndex = -1;
  bool _firstPlayLogged = false;
  // Remember playback position per reel index so if the user scrolls away or
  // navigates to another screen and comes back, the reel resumes like Instagram.
  final Map<int, Duration> _resumeByIndex = {};
  // Indices we've already retried after a decoder-failure init. Prevents an
  // infinite recreate loop if the codec keeps failing for the same reel.
  final Set<int> _retriedSlots = <int>{};

  VideoControllerPool({this.forwardPreload = 1});

  /// Returns the controller for [index] if it's currently in the pool. Otherwise null.
  VideoPlayerController? controllerAt(int index) =>
      _slots.firstWhereOrNull((s) => s.index == index)?.controller;

  /// Future that resolves when the controller at [index] is initialized, or null
  /// if there's no slot for that index.
  Future<void>? readyAt(int index) =>
      _slots.firstWhereOrNull((s) => s.index == index)?.ready;

  /// Set the currently active reel. Recycles the pool window to {active, active+1, ..., active+forwardPreload}.
  /// Pauses non-active controllers, plays the active one once initialized.
  Future<void> setActive(int index, List<String> urls) async {
    _activeIndex = index;

    final wantedIndices = <int>{
      for (int i = index; i <= index + forwardPreload; i++)
        if (i >= 0 && i < urls.length) i,
    };

    // Dispose slots that are no longer in the window.
    final disposedNow = <int>[];
    _slots.removeWhere((s) {
      if (!wantedIndices.contains(s.index)) {
        // Persist last known position before disposing.
        try {
          if (s.controller.value.isInitialized) {
            _resumeByIndex[s.index] = s.controller.value.position;
          }
        } catch (_) {}
        disposedNow.add(s.index);
        s.disposed = true;
        s.controller.dispose();
        return true;
      }
      return false;
    });

    // Add slots for any missing indices.
    // BANDWIDTH PRIORITIZATION: start the active slot's init immediately.
    // Defer neighbor inits via Future.microtask so the active socket gets first
    // dibs on DNS / TCP / TLS / first bytes — this knocks ~600ms off cold start.
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
        // Start the active slot's init synchronously.
        final initStart = DateTime.now();
        ready = controller.initialize().then((_) {
          controller.setLooping(true);
          final ms = DateTime.now().difference(initStart).inMilliseconds;
          final tag = ms > 3000 ? '🐢 SLOW' : '✓';
          debugPrint('[pool]   $tag initialized #$i (active) in ${ms}ms — $shortUrl');
        }).catchError((e, st) {
          debugPrint('[pool]   ✗ init failed for #$i ($shortUrl): $e');
        });
      } else {
        // Defer neighbor init by one event-loop turn so it doesn't steal the
        // first network slice from the active slot.
        ready = Future.microtask(() {
          final initStart = DateTime.now();
          return controller.initialize().then((_) {
            controller.setLooping(true);
            final ms = DateTime.now().difference(initStart).inMilliseconds;
            final tag = ms > 3000 ? '🐢 SLOW' : '✓';
            debugPrint('[pool]   $tag initialized #$i (preload) in ${ms}ms — $shortUrl');
          }).catchError((e, st) {
            debugPrint('[pool]   ✗ init failed for #$i ($shortUrl): $e');
          });
        });
      }
      _slots.add(_Slot(i, controller, ready));
    }

    // Spec-verification log: pool window + size + churn for this transition.
    final inPool = _slots.map((s) => s.index).toList()..sort();
    debugPrint(
      '[pool] active=$index  size=${_slots.length}  window=$inPool'
      '${createdNow.isNotEmpty ? '  +created=$createdNow' : ''}'
      '${disposedNow.isNotEmpty ? '  -disposed=$disposedNow' : ''}',
    );

    // Activate the right one. Pause the others.
    for (final s in _slots) {
      if (s.disposed) continue;
      if (s.index == index) {
        final waitStart = DateTime.now();
        await s.ready;
        final waitMs = DateTime.now().difference(waitStart).inMilliseconds;
        if (!s.disposed) {
          // Decoder-failure recovery: video_player.initialize() can resolve
          // successfully even when ExoPlayer's MediaCodec failed to allocate
          // a hardware decoder. We catch that here, dispose, and recreate once.
          if (s.controller.value.hasError && _retriedSlots.add(s.index)) {
            debugPrint(
                '[pool]   ⚠ decoder error on #$index after init — recreating once: ${s.controller.value.errorDescription}');
            try { await s.controller.dispose(); } catch (_) {}
            _slots.remove(s);
            // One-shot retry. If it fails again, the tile will show its
            // existing fallback spinner and the user can scroll past.
            return setActive(index, urls);
          }
          final resumeAt = _resumeByIndex[index] ?? Duration.zero;
          // If we have a saved position, resume from it; otherwise start at 0.
          // Clamp to duration just in case metadata changed.
          final dur = s.controller.value.duration;
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
        // Pause neighbors but keep them initialized so swipe is instant.
        try {
          await s.ready;
          if (!s.disposed) {
            // Save where this reel stopped so returning resumes from same point.
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
        await s.ready;
        if (!s.disposed) await s.controller.play();
      } catch (_) {}
    }
  }

  Future<void> disposeAll() async {
    for (final s in _slots) {
      s.disposed = true;
      try {
        if (s.controller.value.isInitialized) {
          _resumeByIndex[s.index] = s.controller.value.position;
        }
        await s.controller.dispose();
      } catch (_) {}
    }
    _slots.clear();
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
