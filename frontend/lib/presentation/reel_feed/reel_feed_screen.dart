import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/di/service_locator.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/reel.dart';
import 'reel_feed_bloc.dart';
import 'video_controller_pool.dart';

class ReelFeedScreen extends StatefulWidget {
  const ReelFeedScreen({super.key});

  @override
  State<ReelFeedScreen> createState() => _ReelFeedScreenState();
}

class _ReelFeedScreenState extends State<ReelFeedScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  // backwardPreload + forwardPreload = 1/1: pool keeps {N-1, N, N+1}.
  // Only the active slot actively decodes; neighbors are paused after init,
  // so we hold 3 decoder slots but only 1 is doing work — safe on Qualcomm.
  final _pool = VideoControllerPool(backwardPreload: 1, forwardPreload: 1);
  late final PageController _page;
  Timer? _settleTimer;
  int _settledIndex = 0;

  @override
  bool get wantKeepAlive => true;

  bool get _isCurrentRoute {
    if (!mounted) return false;
    return ModalRoute.of(context)?.isCurrent ?? false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final initial = context.read<ReelFeedBloc>().state.activeIndex;
    _page = PageController(initialPage: initial);
    _settledIndex = initial;
    debugPrint(
        '[feed] 🌱 initState — restored to reel #$initial from bloc (this should fire ONCE per app launch)');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settleTimer?.cancel();
    _page.dispose();
    _pool.disposeAll();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      debugPrint('[lifecycle] $state → pausing active reel');
      _pool.pauseActive();
    } else if (state == AppLifecycleState.resumed && _isCurrentRoute) {
      debugPrint('[lifecycle] resumed → resuming active reel (feed is current route)');
      _pool.resumeActive();
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('[lifecycle] resumed → feed is NOT current route, skipping resume to avoid audio bleed');
    }
  }

  void _onPageChanged(int index, List<Reel> reels) {
    // Update bloc immediately for pagination, but defer activation until scroll settles.
    debugPrint('[feed] page changed → $index (settle pending 150ms)');
    context.read<ReelFeedBloc>().add(ReelIndexChanged(index));

    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      debugPrint('[feed] settled on $index — activating');
      _settledIndex = index;
      // setActive resolves *after* the controller is initialized and play() has
      // fired. We need a setState at that point — the immediate one below
      // updates the thumbnail layer, but `showVideo` won't flip true until the
      // controller reports isInitialized, and there's nothing else in the tree
      // listening for that. Without this rebuild, fast-scrolled reels (where
      // the active slot needs fresh init) get stuck on the thumbnail.
      _pool.setActive(index, reels.map((r) => r.videoUrl).toList()).then((_) {
        if (mounted) setState(() {});
      });
      _warmAhead(reels, index);
      setState(() {}); // immediate rebuild for thumbnail/active-index swap
    });
  }

  /// Skip activeIndex±1 — the pool already keeps real controllers for those.
  /// Range prefetch covers ±2..±4 (warms OS cache), thumbnails are wider since
  /// the image cache is cheap.
  void _warmAhead(List<Reel> reels, int activeIndex) {
    final api = sl<ApiClient>();
    for (int i = activeIndex + 2; i <= activeIndex + 4; i++) {
      if (i < 0 || i >= reels.length) continue;
      api.prefetchRange(reels[i].videoUrl, bytes: 524287);
    }
    for (int i = activeIndex - 2; i >= activeIndex - 3; i--) {
      if (i < 0 || i >= reels.length) continue;
      api.prefetchRange(reels[i].videoUrl, bytes: 524287);
    }
    for (int i = activeIndex - 2; i <= activeIndex + 5; i++) {
      if (i < 0 || i >= reels.length) continue;
      final url = reels[i].thumbnailUrl;
      if (url == null || url.isEmpty) continue;
      // CachedNetworkImageProvider so the precache populates the disk cache,
      // not just the in-memory ImageCache. Subsequent cold starts hit disk.
      precacheImage(CachedNetworkImageProvider(url), context).catchError((_) {
        // Thumb fetch failed — gradient underlay handles it. Silent.
      });
    }
    debugPrint(
        '[feed] 🔥 warm-ahead from #$activeIndex → range[N-3..N-2, N+2..N+4], thumbs[N-2..N+5]');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<ReelFeedBloc, ReelFeedState>(
        buildWhen: (a, b) => a.reels != b.reels || a.loading != b.loading || a.error != b.error,
        builder: (context, state) {
          if (state.loading && state.reels.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (state.error != null && state.reels.isEmpty) {
            return _ErrorView(message: state.error!);
          }
          if (state.reels.isEmpty) {
            return const Center(
                child: Text('No reels yet', style: TextStyle(color: Colors.white)));
          }

          // Trigger initial activation once we have data.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_pool.controllerAt(_settledIndex) == null) {
              _pool.setActive(_settledIndex, state.reels.map((r) => r.videoUrl).toList())
                  .then((_) {
                if (mounted) setState(() {});
              });
            }
          });

          return PageView.builder(
            controller: _page,
            scrollDirection: Axis.vertical,
            itemCount: state.reels.length,
            onPageChanged: (i) => _onPageChanged(i, state.reels),
            itemBuilder: (context, index) {
              final reel = state.reels[index];
              final controller = _pool.controllerAt(index);
              final isSettled = index == _settledIndex;
              return _ReelTile(
                reel: reel,
                controller: controller,
                showVideo: isSettled && controller != null && controller.value.isInitialized,
                onTapSeries: () {
                  // Leaving the feed: pause and persist current reel position.
                  _pool.pauseActive();
                  debugPrint(
                      '[feed] 🔖 navigating to series from reel #$index (ep=${reel.episodeId}) — position will be preserved');
                  context.push(
                      '/series/${reel.seriesId}?fromEpisodeId=${reel.episodeId}');
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ReelTile extends StatelessWidget {
  final Reel reel;
  final VideoPlayerController? controller;
  final bool showVideo;
  final VoidCallback onTapSeries;

  const _ReelTile({
    required this.reel,
    required this.controller,
    required this.showVideo,
    required this.onTapSeries,
  });

  static String _fmt(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Lift overlays above the gesture bar / 3-button nav.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient under everything — fallback if both thumbnail and video fail.
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A1F), Color(0xFF000000)],
            ),
          ),
        ),

        // Thumbnail. fadeInDuration: zero so we don't trade the spinner for a
        // fade — placeholder is the gradient layer beneath, errors fall back
        // to it too.
        if (reel.thumbnailUrl != null && reel.thumbnailUrl!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: reel.thumbnailUrl!,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            placeholder: (_, __) => const SizedBox.shrink(),
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),

        // Video, full-bleed via FittedBox.cover. Anything else (Center +
        // AspectRatio) letterboxes 16:9 sources on a portrait phone and the
        // thumbnail underneath bleeds through the black bars.
        if (showVideo && controller != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              final c = controller!;
              if (!c.value.isInitialized) return;
              if (c.value.isPlaying) {
                c.pause();
              } else {
                c.play();
              }
            },
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller!.value.size.width == 0
                      ? 9
                      : controller!.value.size.width,
                  height: controller!.value.size.height == 0
                      ? 16
                      : controller!.value.size.height,
                  child: VideoPlayer(controller!),
                ),
              ),
            ),
          ),

        // Big play icon when paused (Insta-style feedback).
        if (showVideo && controller != null)
          Center(
            child: IgnorePointer(
              // Let taps pass through to the underlying GestureDetector.
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller!,
                builder: (_, v, __) {
                  if (!v.isInitialized || v.isPlaying) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 54),
                  );
                },
              ),
            ),
          ),

        // Reel timestamp + progress (only for the active/settled reel).
        if (showVideo && controller != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + 0,
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller!,
              builder: (context, v, _) {
                final dur = v.duration;
                final pos = v.position;
                final value = dur.inMilliseconds <= 0
                    ? null
                    : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 3,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_fmt(pos)} / ${_fmt(dur)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        // Bottom-left overlay
        Positioned(
          left: 16,
          right: 80,
          bottom: bottomInset + 24,
          child: GestureDetector(
            onTap: onTapSeries,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(reel.seriesTitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Ep ${reel.episodeNumber} · ${reel.episodeTitle}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ),

        // Right rail — tap-to-enter button + continue watching + downloads
        Positioned(
          right: 12,
          bottom: bottomInset + 24,
          child: Column(
            children: [
              IconButton(
                onPressed: onTapSeries,
                icon: const Icon(Icons.playlist_play, color: Colors.white, size: 36),
                tooltip: 'Open series',
              ),
              IconButton(
                onPressed: () => context.push('/continue-watching'),
                icon: const Icon(Icons.history, color: Colors.white, size: 30),
                tooltip: 'Continue watching',
              ),
              IconButton(
                onPressed: () => context.push('/downloads'),
                icon: const Icon(Icons.download_outlined, color: Colors.white, size: 30),
                tooltip: 'Downloads',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<ReelFeedBloc>().add(const ReelFeedStarted()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
