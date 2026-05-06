import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/di/service_locator.dart';
import '../../core/network/connectivity_service.dart';
import '../../domain/entities/episode.dart';
import '../../domain/entities/series.dart';
import '../../domain/repositories/repositories.dart';

class PlayerScreen extends StatefulWidget {
  final String seriesId;
  final String episodeId;
  const PlayerScreen({super.key, required this.seriesId, required this.episodeId});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  Series? _series;
  Episode? _episode;
  Timer? _saveTimer;
  double _speed = 1.0;
  bool _showControls = true;
  bool _fullscreen = false;
  String? _loadError;
  bool _wasPlayingBeforeBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      debugPrint('[player] $state → pause+save (controllerReady=$ready)');
      if (ready) {
        _wasPlayingBeforeBackground = c.value.isPlaying;
        c.pause();
        // Sync save in addition to the 5s timer — gives us ~0s of loss on
        // background-then-OS-kill, vs ~5s if we relied on the timer alone.
        _saveProgress();
      }
    } else if (state == AppLifecycleState.resumed) {
      // ModalRoute.of can throw mid-teardown. Default to false on error and
      // skip auto-resume rather than crashing the lifecycle callback.
      bool isCurrent = false;
      try {
        isCurrent = mounted && (ModalRoute.of(context)?.isCurrent ?? false);
      } catch (_) {}
      debugPrint(
          '[player] resumed (current=$isCurrent, wasPlaying=$_wasPlayingBeforeBackground, ready=$ready)');
      if (ready && _wasPlayingBeforeBackground && isCurrent) {
        c.play();
      }
    }
  }

  Future<void> _load() async {
    try {
      final series = await sl<SeriesRepository>().fetchSeries(widget.seriesId);
      final episode = series.episodes.firstWhere((e) => e.id == widget.episodeId);
      final localPath = await sl<DownloadRepository>().localPathFor(episode.id);

      // Spec: "If offline and a non-downloaded episode is tapped, show a clear message."
      if (localPath == null && !sl<ConnectivityService>().isOnline) {
        debugPrint(
            '[player] ⚠ offline + not downloaded → showing offline message ep=${episode.id}');
        if (!mounted) return;
        setState(() {
          _series = series;
          _episode = episode;
          _loadError =
              "You're offline and this episode isn't downloaded.\nDownload it first to watch without internet.";
        });
        return;
      }

      debugPrint(
          '[player] ▶ source = ${localPath != null ? "LOCAL ($localPath)" : "NETWORK (${episode.videoUrl})"} ep=${episode.id}');
      final controller = localPath != null
          ? VideoPlayerController.file(File(localPath))
          : VideoPlayerController.networkUrl(Uri.parse(episode.videoUrl));

      try {
        await controller.initialize();
      } catch (_) {
        await controller.dispose();
        if (!mounted) return;
        setState(() {
          _series = series;
          _episode = episode;
          _loadError = localPath == null
              ? "Couldn't load this episode. Check your connection or download it for offline."
              : "Couldn't open the downloaded file.";
        });
        return;
      }

      final localProgress = await sl<ProgressRepository>().getLocalProgress(episode.id);
      final resumeAt =
          localProgress > episode.progressSeconds ? localProgress : episode.progressSeconds;
      if (resumeAt > 0 && resumeAt < episode.durationSec - 5) {
        debugPrint(
            '[player] ⏯ resuming ep=${episode.id} at ${resumeAt}s / ${episode.durationSec}s (local=${localProgress}s remote=${episode.progressSeconds}s)');
        await controller.seekTo(Duration(seconds: resumeAt));
      } else {
        debugPrint('[player] ▶ starting from 0 ep=${episode.id} (no resume position)');
      }
      controller.addListener(_onTick);
      await controller.play();

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _series = series;
        _episode = episode;
        _controller = controller;
      });

      _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) => _saveProgress());
    } catch (err) {
      if (!mounted) return;
      setState(() => _loadError = 'Failed to load: $err');
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || _episode == null) return;
    if (c.value.position >= c.value.duration && c.value.duration > Duration.zero) {
      _onCompleted();
    }
  }

  Future<void> _saveProgress({bool completed = false}) async {
    final c = _controller;
    final ep = _episode;
    if (c == null || ep == null || !c.value.isInitialized) return;
    final secs = c.value.position.inSeconds;
    if (secs <= 0 && !completed) return;
    await sl<ProgressRepository>().saveProgress(
      episodeId: ep.id,
      progressSeconds: secs,
      completed: completed,
    );
  }

  Future<void> _onCompleted() async {
    if (_episode == null || _series == null) return;
    await _saveProgress(completed: true);
    final next = _nextEpisode();
    if (!mounted) return;
    if (next != null) {
      context.pushReplacement('/player/${_series!.id}/${next.id}');
    } else if (context.canPop()) {
      context.pop();
    } else {
      // Player was opened directly (e.g. from Continue Watching) and there's
      // nothing to pop back to. Send the user to the feed.
      context.go('/feed');
    }
  }

  Episode? _nextEpisode() {
    if (_episode == null || _series == null) return null;
    final idx = _series!.episodes.indexWhere((e) => e.id == _episode!.id);
    if (idx < 0 || idx + 1 >= _series!.episodes.length) return null;
    return _series!.episodes[idx + 1];
  }

  Episode? _prevEpisode() {
    if (_episode == null || _series == null) return null;
    final idx = _series!.episodes.indexWhere((e) => e.id == _episode!.id);
    if (idx <= 0) return null;
    return _series!.episodes[idx - 1];
  }

  void _goNext() {
    final n = _nextEpisode();
    if (n != null) context.pushReplacement('/player/${_series!.id}/${n.id}');
  }

  void _goPrev() {
    final p = _prevEpisode();
    if (p != null) context.pushReplacement('/player/${_series!.id}/${p.id}');
  }

  Future<void> _toggleFullscreen() async {
    setState(() => _fullscreen = !_fullscreen);
    if (_fullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    _saveProgress(); // final save (fire-and-forget; periodic + lifecycle saves are the durable bound)
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    // Restore portrait + normal UI on exit (in case user left while in fullscreen).
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }

  void _doubleTap(TapDownDetails d, BoxConstraints c) {
    final left = d.localPosition.dx < c.maxWidth / 2;
    final pos = _controller!.value.position;
    const delta = Duration(seconds: 10);
    _controller!.seekTo(left ? pos - delta : pos + delta);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, color: Colors.white54, size: 64),
                const SizedBox(height: 16),
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to series'),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: !_fullscreen,
        bottom: !_fullscreen,
        left: !_fullscreen,
        right: !_fullscreen,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  onTap: () => setState(() => _showControls = !_showControls),
                  onDoubleTapDown: (d) => _doubleTap(d, constraints),
                  onDoubleTap: () {},
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: c.value.aspectRatio,
                          child: VideoPlayer(c),
                        ),
                      ),
                      if (_showControls)
                        _Controls(
                          controller: c,
                          speed: _speed,
                          onSpeed: (v) {
                            debugPrint(
                                '[player] ⏩ playback speed change: ${_speed}x → ${v}x');
                            setState(() => _speed = v);
                            c.setPlaybackSpeed(v);
                          },
                          fullscreen: _fullscreen,
                          onToggleFullscreen: _toggleFullscreen,
                          onPrev: _prevEpisode() != null ? _goPrev : null,
                          onNext: _nextEpisode() != null ? _goNext : null,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Seek bar + elapsed/remaining time
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  VideoProgressIndicator(c, allowScrubbing: true),
                  const SizedBox(height: 4),
                  ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: c,
                    builder: (_, v, __) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_fmt(v.position),
                            style:
                                const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('-${_fmt(v.duration - v.position)}',
                            style:
                                const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final mm = m.toString().padLeft(h > 0 ? 2 : 1, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }
}

class _Controls extends StatelessWidget {
  final VideoPlayerController controller;
  final double speed;
  final ValueChanged<double> onSpeed;
  final bool fullscreen;
  final VoidCallback onToggleFullscreen;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _Controls({
    required this.controller,
    required this.speed,
    required this.onSpeed,
    required this.fullscreen,
    required this.onToggleFullscreen,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black38,
      child: Stack(
        children: [
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.skip_previous,
                      color: onPrev == null ? Colors.white24 : Colors.white, size: 32),
                  onPressed: onPrev,
                  tooltip: 'Previous episode',
                ),
                IconButton(
                  icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                  onPressed: () => controller
                      .seekTo(controller.value.position - const Duration(seconds: 10)),
                ),
                ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (_, v, __) => IconButton(
                    iconSize: 56,
                    icon: Icon(
                      v.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.white,
                    ),
                    onPressed: () => v.isPlaying ? controller.pause() : controller.play(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                  onPressed: () => controller
                      .seekTo(controller.value.position + const Duration(seconds: 10)),
                ),
                IconButton(
                  icon: Icon(Icons.skip_next,
                      color: onNext == null ? Colors.white24 : Colors.white, size: 32),
                  onPressed: onNext,
                  tooltip: 'Next episode',
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                PopupMenuButton<double>(
                  initialValue: speed,
                  icon: Text('${speed}x',
                      style: const TextStyle(color: Colors.white, fontSize: 16)),
                  onSelected: onSpeed,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 0.5, child: Text('0.5x')),
                    PopupMenuItem(value: 1.0, child: Text('1x')),
                    PopupMenuItem(value: 1.25, child: Text('1.25x')),
                    PopupMenuItem(value: 1.5, child: Text('1.5x')),
                    PopupMenuItem(value: 2.0, child: Text('2x')),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: Colors.white,
                  ),
                  onPressed: onToggleFullscreen,
                  tooltip: fullscreen ? 'Exit fullscreen' : 'Fullscreen',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
