// lib/data/repositories/repositories_impl.dart
import 'dart:async';

import 'package:drift/drift.dart' as d;
import 'package:flutter/foundation.dart';

import '../../core/storage/app_database.dart';
import '../../domain/entities/episode.dart';
import '../../domain/entities/reel.dart';
import '../../domain/entities/series.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/remote_data_source.dart';

class ReelRepositoryImpl implements ReelRepository {
  final RemoteDataSource _remote;
  Future<({List<Reel> items, int? nextCursor})>? _prefetchFuture;
  ({List<Reel> items, int? nextCursor})? _prefetchResult;
  bool _prefetchTaken = false;

  ReelRepositoryImpl(this._remote);

  @override
  Future<({List<Reel> items, int? nextCursor})> fetchReels({int cursor = 0, int limit = 20}) async {
    // If the bloc is asking for the very first page and a prefetch is in flight
    // or completed, hand that result over. Cuts cold start by overlapping the
    // network roundtrip with Flutter framework bootstrap.
    if (cursor == 0 && !_prefetchTaken) {
      if (_prefetchResult != null) {
        _prefetchTaken = true;
        debugPrint('[reels] ⚡ serving from prefetch cache (instant)');
        return _prefetchResult!;
      }
      if (_prefetchFuture != null) {
        _prefetchTaken = true;
        debugPrint('[reels] ⌛ awaiting in-flight prefetch');
        return _prefetchFuture!;
      }
    }
    return _remote.fetchReels(cursor: cursor, limit: limit);
  }

  @override
  ({List<Reel> items, int? nextCursor})? takePrefetched() {
    if (_prefetchTaken) return null;
    final r = _prefetchResult;
    if (r == null) return null;
    _prefetchTaken = true;
    return r;
  }

  @override
  void startPrefetch({int limit = 20}) {
    if (_prefetchFuture != null || _prefetchResult != null) return;
    debugPrint('[reels] 🚀 prefetch started (limit=$limit)');
    final start = DateTime.now();
    _prefetchFuture = _remote.fetchReels(cursor: 0, limit: limit).then((r) {
      _prefetchResult = r;
      final ms = DateTime.now().difference(start).inMilliseconds;
      debugPrint('[reels] ✓ prefetch landed in ${ms}ms (${r.items.length} reels)');
      return r;
    }).catchError((e) {
      debugPrint('[reels] ✗ prefetch failed ($e) — bloc will retry');
      _prefetchFuture = null;
      throw e;
    });
  }
}

class SeriesRepositoryImpl implements SeriesRepository {
  final RemoteDataSource _remote;
  final AppDatabase _db;
  SeriesRepositoryImpl(this._remote, this._db);

  @override
  Future<Series> fetchSeries(String seriesId) async {
    try {
      final series = await _remote.fetchSeries(seriesId);
      // Cache episodes for offline reads.
      await _db.batch((b) {
        for (final e in series.episodes) {
          b.insert(
            _db.cachedEpisodes,
            CachedEpisodesCompanion.insert(
              id: e.id,
              seriesId: e.seriesId,
              title: e.title,
              description: e.description,
              videoUrl: e.videoUrl,
              thumbnailUrl: e.thumbnailUrl,
              durationSec: e.durationSec,
              episodeNumber: e.episodeNumber,
              seriesTitle: d.Value(series.title),
              seriesDescription: d.Value(series.description),
              seriesThumb: d.Value(series.thumbnailUrl),
            ),
            mode: d.InsertMode.insertOrReplace,
          );
        }
      });
      // Merge local progress on top — local is authoritative.
      return _mergeLocalProgress(series);
    } catch (_) {
      // Offline path: serve from cache.
      final rows = await (_db.select(_db.cachedEpisodes)
            ..where((t) => t.seriesId.equals(seriesId))
            ..orderBy([(t) => d.OrderingTerm(expression: t.episodeNumber)]))
          .get();
      if (rows.isEmpty) rethrow;
      final episodes = rows.map(_episodeFromRow).toList();
      final s = Series(
        id: seriesId,
        title: rows.first.seriesTitle,
        description: rows.first.seriesDescription,
        thumbnailUrl: rows.first.seriesThumb,
        episodeCount: episodes.length,
        episodes: episodes,
      );
      return _mergeLocalProgress(s);
    }
  }

  Future<Series> _mergeLocalProgress(Series s) async {
    final ids = s.episodes.map((e) => e.id).toList();
    if (ids.isEmpty) return s;
    final progressRows = await (_db.select(_db.progressLocal)
          ..where((t) => t.episodeId.isIn(ids)))
        .get();
    final byId = {for (final r in progressRows) r.episodeId: r};
    final downloads = await (_db.select(_db.downloads)
          ..where((t) => t.episodeId.isIn(ids) & t.localPath.isNotNull()))
        .get();
    final downloadById = {for (final d in downloads) d.episodeId: d};

    final merged = s.episodes.map((e) {
      final p = byId[e.id];
      final d = downloadById[e.id];
      return e.copyWith(
        progressSeconds: p?.progressSeconds ?? e.progressSeconds,
        completed: p?.completed ?? e.completed,
        localPath: d?.localPath,
      );
    }).toList();
    return s.copyWith(episodes: merged);
  }

  Episode _episodeFromRow(CachedEpisode r) => Episode(
        id: r.id,
        seriesId: r.seriesId,
        title: r.title,
        description: r.description,
        videoUrl: r.videoUrl,
        thumbnailUrl: r.thumbnailUrl,
        durationSec: r.durationSec,
        episodeNumber: r.episodeNumber,
      );
}

class ProgressRepositoryImpl implements ProgressRepository {
  final RemoteDataSource _remote;
  final AppDatabase _db;
  ProgressRepositoryImpl(this._remote, this._db);

  @override
  Future<void> saveProgress({
    required String episodeId,
    required int progressSeconds,
    required bool completed,
  }) async {
    // MONOTONIC GUARD: if existing local progress is higher and we're not marking
    // completed, keep the local value. This prevents stale callers from rewinding.
    final existing = await (_db.select(_db.progressLocal)
          ..where((t) => t.episodeId.equals(episodeId)))
        .getSingleOrNull();

    final resolvedProgress = existing == null
        ? progressSeconds
        : (progressSeconds > existing.progressSeconds ? progressSeconds : existing.progressSeconds);
    final resolvedCompleted = (existing?.completed ?? false) || completed;

    if (existing != null && progressSeconds < existing.progressSeconds) {
      debugPrint(
          '[progress] 🛡 monotonic guard: ep=$episodeId incoming=${progressSeconds}s < local=${existing.progressSeconds}s → kept local');
    }

    await _db.into(_db.progressLocal).insertOnConflictUpdate(ProgressLocalCompanion.insert(
          episodeId: episodeId,
          progressSeconds: d.Value(resolvedProgress),
          lastWatchedAt: DateTime.now().toUtc(),
          completed: d.Value(resolvedCompleted),
          synced: const d.Value(false),
        ));
    debugPrint(
        '[progress] 💾 local save ep=$episodeId at=${resolvedProgress}s completed=$resolvedCompleted');

    // Fire-and-forget remote PUT. If it fails (offline), bulk sync will catch it.
    unawaited(_remote
        .putProgress(
            episodeId: episodeId,
            progressSeconds: resolvedProgress,
            lastWatchedAt: DateTime.now().toUtc(),
            completed: resolvedCompleted)
        .then((_) {
      debugPrint('[progress] ☁ PUT ok ep=$episodeId at=${resolvedProgress}s');
      return _markSynced(episodeId);
    }).catchError((e) {
      debugPrint('[progress] ⚠ PUT failed ep=$episodeId — stays unsynced ($e)');
    }));
  }

  Future<void> _markSynced(String episodeId) async {
    await (_db.update(_db.progressLocal)..where((t) => t.episodeId.equals(episodeId)))
        .write(const ProgressLocalCompanion(synced: d.Value(true)));
  }

  @override
  Future<int> getLocalProgress(String episodeId) async {
    final r = await (_db.select(_db.progressLocal)
          ..where((t) => t.episodeId.equals(episodeId)))
        .getSingleOrNull();
    return r?.progressSeconds ?? 0;
  }

  // Chunk size for bulk sync. Keeps individual requests under a reasonable
  // payload size and avoids a single huge write blocking other clients.
  static const int _bulkSyncChunkSize = 200;

  @override
  Future<void> syncPending() async {
    final pending = await (_db.select(_db.progressLocal)
          ..where((t) => t.synced.equals(false)))
        .get();
    if (pending.isEmpty) {
      debugPrint('[progress] 🔄 syncPending: nothing to sync');
      return;
    }
    debugPrint(
        '[progress] 🔄 syncPending: ${pending.length} item(s) → ${(pending.length / _bulkSyncChunkSize).ceil()} chunk(s) of $_bulkSyncChunkSize');

    for (int start = 0; start < pending.length; start += _bulkSyncChunkSize) {
      final end = (start + _bulkSyncChunkSize < pending.length)
          ? start + _bulkSyncChunkSize
          : pending.length;
      final chunk = pending.sublist(start, end);
      final items = chunk
          .map((p) => {
                'episode_id': p.episodeId,
                'progress_seconds': p.progressSeconds,
                'last_watched_at': p.lastWatchedAt.toUtc().toIso8601String(),
                'completed': p.completed,
              })
          .toList();
      try {
        final resolved = await _remote.bulkSync(items);
        debugPrint(
            '[progress] ✅ bulk sync chunk ${start ~/ _bulkSyncChunkSize + 1} resolved ${resolved.length} item(s)');
        // Apply server-resolved values (could equal or exceed ours due to merge).
        for (final r in resolved) {
          final episodeId = r['episode_id'] as String;
          final serverProgress = (r['progress_seconds'] ?? 0) as int;
          final local = await (_db.select(_db.progressLocal)
                ..where((t) => t.episodeId.equals(episodeId)))
              .getSingleOrNull();
          if (local == null) continue;
          final finalProgress =
              serverProgress > local.progressSeconds ? serverProgress : local.progressSeconds;
          await (_db.update(_db.progressLocal)..where((t) => t.episodeId.equals(episodeId)))
              .write(ProgressLocalCompanion(
            progressSeconds: d.Value(finalProgress),
            synced: const d.Value(true),
          ));
        }
      } catch (e) {
        debugPrint(
            '[progress] ⚠ bulk sync chunk ${start ~/ _bulkSyncChunkSize + 1} failed — remaining items stay unsynced ($e)');
        // Stop after first failure: remaining unsynced rows will be retried
        // on the next reconnect tick. No point spamming the network.
        return;
      }
    }
  }

  @override
  Future<List<ContinueWatchingItem>> continueWatching() async {
    try {
      return await _remote.continueWatching();
    } catch (_) {
      // Offline: build from local progress + cached episodes.
      final progress = await (_db.select(_db.progressLocal)
            ..where((t) => t.completed.equals(false) & t.progressSeconds.isBiggerThanValue(0))
            ..orderBy([(t) => d.OrderingTerm(expression: t.lastWatchedAt, mode: d.OrderingMode.desc)])
            ..limit(10))
          .get();
      final ids = progress.map((p) => p.episodeId).toList();
      if (ids.isEmpty) return [];
      final eps = await (_db.select(_db.cachedEpisodes)..where((t) => t.id.isIn(ids))).get();
      final byId = {for (final e in eps) e.id: e};
      return progress.where((p) => byId.containsKey(p.episodeId)).map((p) {
        final e = byId[p.episodeId]!;
        return ContinueWatchingItem(
          episodeId: e.id,
          episodeTitle: e.title,
          episodeNumber: e.episodeNumber,
          durationSec: e.durationSec,
          seriesId: e.seriesId,
          seriesTitle: e.seriesTitle,
          seriesThumb: e.seriesThumb,
          progressSeconds: p.progressSeconds,
        );
      }).toList();
    }
  }
}
