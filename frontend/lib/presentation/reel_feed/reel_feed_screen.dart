// lib/presentation/reel_feed/reel_feed_screen.dart
import 'dart:async';

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
  final _pool = VideoControllerPool(forwardPreload: 1);
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
      _pool.setActive(index, reels.map((r) => r.videoUrl).toList());
      _warmAhead(reels, index);
      setState(() {}); // rebuild to bind new active controller widget
    });
  }

  /// Best-effort warmup of upcoming reels so swipes feel instant:
  ///   1. Issue HTTP Range prefetch for the first 256KB of N+2..N+4 video URLs.
  ///      Pool already initializes a real VideoPlayerController for N+1, so
  ///      we skip that index and warm the OS cache for the ones beyond.
  ///   2. Precache thumbnails for N+1..N+5 into Flutter's image cache so they
  ///      render instantly when the user lands on those reels (no white spinner).
  /// All errors swallowed — prefetch is opportunistic.
  void _warmAhead(List<Reel> reels, int activeIndex) {
    final api = sl<ApiClient>();
    // Range prefetch for video bytes (skip activeIndex+1, pool covers it).
    for (int i = activeIndex + 2; i <= activeIndex + 4; i++) {
      if (i < 0 || i >= reels.length) continue;
      api.prefetchRange(reels[i].videoUrl);
    }
    // Thumbnail precache — don't skip activeIndex+1 here, image cache is cheap.
    for (int i = activeIndex; i <= activeIndex + 5; i++) {
      if (i < 0 || i >= reels.length) continue;
      final url = reels[i].thumbnailUrl;
      if (url == null || url.isEmpty) continue;
      // precacheImage requires a context; mounted check above already passed.
      precacheImage(NetworkImage(url), context).catchError((_) {
        // Thumb fetch failed — gradient underlay handles it. Silent.
      });
    }
    debugPrint(
        '[feed] 🔥 warm-ahead from #$activeIndex → range[N+2..N+4], thumbs[N..N+5]');
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
    // Push overlays above the system gesture bar / 3-button nav.
    // viewPadding.bottom is non-zero on devices with a system inset at the bottom
    // (most modern Androids + iPhones with home indicator).
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: dark gradient — ultimate fallback if even the thumbnail
        // can't load (offline + thumbnail host unreachable). Better than pure
        // black because the user gets a hint that something will appear.
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A1F), Color(0xFF000000)],
            ),
          ),
        ),

        // Layer 2: per-reel thumbnail. Renders the moment bytes arrive and
        // covers the gradient. Stays visible underneath the video — when the
        // VideoPlayer paints, it occludes the thumbnail at the same Z order.
        // gaplessPlayback: true keeps the previous thumb visible until the
        // new one loads (no white flash on rapid scroll).
        if (reel.thumbnailUrl != null && reel.thumbnailUrl!.isNotEmpty)
          Image.network(
            reel.thumbnailUrl!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),

        // Layer 3: the actual video, shown only once the controller settles.
        // The thumbnail under it remains visible during init — no spinner.
        if (showVideo && controller != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // Instagram-style tap-to-pause / tap-to-play.
              final c = controller!;
              if (!c.value.isInitialized) return;
              if (c.value.isPlaying) {
                c.pause();
              } else {
                c.play();
              }
            },
            child: Center(
              child: AspectRatio(
                aspectRatio:
                    controller!.value.aspectRatio == 0 ? 9 / 16 : controller!.value.aspectRatio,
                child: VideoPlayer(controller!),
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
