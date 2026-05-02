// lib/domain/repositories/repositories.dart
import '../entities/episode.dart';
import '../entities/reel.dart';
import '../entities/series.dart';

abstract class ReelRepository {
  Future<({List<Reel> items, int? nextCursor})> fetchReels({int cursor = 0, int limit = 20});

  /// Returns the prefetched first page (started at app launch), if any. Null if
  /// the prefetch hasn't completed yet or wasn't attempted. Single-use: subsequent
  /// callers always go through fetchReels.
  ({List<Reel> items, int? nextCursor})? takePrefetched();

  /// Kicks off a background fetch of the first page so the reel feed has data
  /// ready by the time it mounts. Safe to call multiple times — only first wins.
  void startPrefetch({int limit = 20});
}

abstract class SeriesRepository {
  Future<Series> fetchSeries(String seriesId);
}

abstract class ProgressRepository {
  /// Save progress locally immediately. Sync to server in background.
  /// Monotonic — never overwrites a higher local value with a lower one.
  Future<void> saveProgress({
    required String episodeId,
    required int progressSeconds,
    required bool completed,
  });

  Future<int> getLocalProgress(String episodeId);

  /// Push all unsynced rows to /progress/bulk-sync. No-op if nothing pending.
  Future<void> syncPending();

  Future<List<ContinueWatchingItem>> continueWatching();
}

class ContinueWatchingItem {
  final String episodeId;
  final String episodeTitle;
  final int episodeNumber;
  final int durationSec;
  final String seriesId;
  final String seriesTitle;
  final String seriesThumb;
  final int progressSeconds;
  ContinueWatchingItem({
    required this.episodeId,
    required this.episodeTitle,
    required this.episodeNumber,
    required this.durationSec,
    required this.seriesId,
    required this.seriesTitle,
    required this.seriesThumb,
    required this.progressSeconds,
  });
}

abstract class DownloadRepository {
  Future<void> enqueue(Episode episode);
  Future<void> pause(String episodeId);
  Future<void> resume(String episodeId);
  Future<void> cancel(String episodeId);
  Future<void> deleteDownload(String episodeId);
  Future<String?> localPathFor(String episodeId);
  Stream<DownloadStatus> watch(String episodeId);
  Future<int> totalBytesUsed();
  Future<List<DownloadStatus>> all();
}

enum DownloadState { idle, queued, running, complete, failed, paused }

class DownloadStatus {
  final String episodeId;
  final DownloadState state;
  final double progress; // 0..1
  final int bytesDownloaded;
  final int? totalBytes;
  final String? localPath;
  DownloadStatus({
    required this.episodeId,
    required this.state,
    required this.progress,
    required this.bytesDownloaded,
    this.totalBytes,
    this.localPath,
  });
}
