// lib/data/repositories/download_repository_impl.dart
import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:drift/drift.dart' as d;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/storage/app_database.dart';
import '../../domain/entities/episode.dart';
import '../../domain/repositories/repositories.dart';

class DownloadRepositoryImpl implements DownloadRepository {
  final AppDatabase _db;
  final _streams = <String, StreamController<DownloadStatus>>{};
  // background_downloader pause/resume needs the Task object, not just the id.
  final _tasks = <String, DownloadTask>{};
  // Completer instead of a bool so two concurrent callers don't both register
  // the FileDownloader listener and double every callback.
  Completer<void>? _initCompleter;

  DownloadRepositoryImpl(this._db);

  Future<void> _ensureInit() async {
    if (_initCompleter != null) return _initCompleter!.future;
    final completer = Completer<void>();
    _initCompleter = completer;

    try {
      try {
        final all = await FileDownloader().allTasks();
        for (final t in all) {
          if (t is DownloadTask) _tasks[t.taskId] = t;
        }
        debugPrint('[download] init: rehydrated ${_tasks.length} task(s) from disk');
      } catch (e) {
        debugPrint('[download] init: no prior tasks ($e)');
      }

      FileDownloader().updates.listen((event) async {
        if (event is TaskStatusUpdate) {
          await _onStatus(event);
        } else if (event is TaskProgressUpdate) {
          await _onProgress(event);
        }
      });
      completer.complete();
    } catch (e, st) {
      completer.completeError(e, st);
      _initCompleter = null;
      rethrow;
    }
  }

  Future<File> _fileFor(String episodeId) async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory(p.join(dir.path, 'downloads'));
    if (!await downloadsDir.exists()) await downloadsDir.create(recursive: true);
    return File(p.join(downloadsDir.path, '$episodeId.mp4'));
  }

  @override
  Future<void> enqueue(Episode episode) async {
    await _ensureInit();
    final file = await _fileFor(episode.id);
    if (await file.exists()) {
      // Already downloaded.
      await _db.into(_db.downloads).insertOnConflictUpdate(DownloadsCompanion.insert(
            episodeId: episode.id,
            taskId: episode.id,
            state: 'complete',
            progress: const d.Value(1.0),
            localPath: d.Value(file.path),
          ));
      _streams[episode.id]?.add(DownloadStatus(
        episodeId: episode.id,
        state: DownloadState.complete,
        progress: 1.0,
        bytesDownloaded: await file.length(),
        localPath: file.path,
      ));
      return;
    }

    final task = DownloadTask(
      taskId: episode.id,
      url: episode.videoUrl,
      filename: '${episode.id}.mp4',
      directory: 'downloads',
      baseDirectory: BaseDirectory.applicationDocuments,
      updates: Updates.statusAndProgress,
      requiresWiFi: false,
      retries: 3,
      allowPause: true,
    );

    await _db.into(_db.downloads).insertOnConflictUpdate(DownloadsCompanion.insert(
          episodeId: episode.id,
          taskId: task.taskId,
          state: 'queued',
          progress: const d.Value(0.0),
        ));

    _tasks[episode.id] = task;
    await FileDownloader().enqueue(task);
    debugPrint('[download] ⬇ enqueue ep=${episode.id} url=${episode.videoUrl}');
  }

  @override
  Future<void> pause(String episodeId) async {
    await _ensureInit();
    final task = _tasks[episodeId];
    if (task == null) {
      debugPrint('[download] ⏸ pause skipped — no task cached for ep=$episodeId');
      return;
    }
    final ok = await FileDownloader().pause(task);
    debugPrint('[download] ⏸ pause ep=$episodeId ok=$ok');
    if (ok) {
      await (_db.update(_db.downloads)..where((t) => t.episodeId.equals(episodeId)))
          .write(const DownloadsCompanion(state: d.Value('paused')));
      _streams[episodeId]?.add(await _currentStatus(episodeId));
    }
  }

  @override
  Future<void> resume(String episodeId) async {
    await _ensureInit();
    final task = _tasks[episodeId];
    if (task == null) {
      debugPrint('[download] ▶ resume skipped — no task cached for ep=$episodeId');
      return;
    }
    final ok = await FileDownloader().resume(task);
    debugPrint('[download] ▶ resume ep=$episodeId ok=$ok (resumable, not restarted)');
    if (ok) {
      await (_db.update(_db.downloads)..where((t) => t.episodeId.equals(episodeId)))
          .write(const DownloadsCompanion(state: d.Value('running')));
      _streams[episodeId]?.add(await _currentStatus(episodeId));
    }
  }

  @override
  Future<void> cancel(String episodeId) async {
    debugPrint('[download] ✗ cancel ep=$episodeId');
    await FileDownloader().cancelTaskWithId(episodeId);
    await (_db.update(_db.downloads)..where((t) => t.episodeId.equals(episodeId)))
        .write(const DownloadsCompanion(state: d.Value('failed')));
    _streams[episodeId]?.add(await _currentStatus(episodeId));
  }

  @override
  Future<void> deleteDownload(String episodeId) async {
    final file = await _fileFor(episodeId);
    final existed = await file.exists();
    if (existed) await file.delete();
    await (_db.delete(_db.downloads)..where((t) => t.episodeId.equals(episodeId))).go();
    debugPrint('[download] 🗑 delete ep=$episodeId (file existed: $existed)');
    _streams[episodeId]?.add(DownloadStatus(
      episodeId: episodeId,
      state: DownloadState.idle,
      progress: 0,
      bytesDownloaded: 0,
    ));
  }

  @override
  Future<String?> localPathFor(String episodeId) async {
    final row = await (_db.select(_db.downloads)..where((t) => t.episodeId.equals(episodeId)))
        .getSingleOrNull();
    if (row?.localPath == null) return null;
    final f = File(row!.localPath!);
    if (!await f.exists()) return null;
    return row.localPath;
  }

  @override
  Stream<DownloadStatus> watch(String episodeId) {
    final ctrl = _streams.putIfAbsent(
        episodeId, () => StreamController<DownloadStatus>.broadcast());
    // Seed with current state.
    _currentStatus(episodeId).then((s) {
      if (!ctrl.isClosed) ctrl.add(s);
    });
    return ctrl.stream;
  }

  Future<DownloadStatus> _currentStatus(String episodeId) async {
    final r = await (_db.select(_db.downloads)..where((t) => t.episodeId.equals(episodeId)))
        .getSingleOrNull();
    if (r == null) {
      return DownloadStatus(
          episodeId: episodeId, state: DownloadState.idle, progress: 0, bytesDownloaded: 0);
    }
    return DownloadStatus(
      episodeId: episodeId,
      state: _stateFromString(r.state),
      progress: r.progress,
      bytesDownloaded: r.bytesDownloaded,
      totalBytes: r.totalBytes,
      localPath: r.localPath,
    );
  }

  DownloadState _stateFromString(String s) => switch (s) {
        'queued' => DownloadState.queued,
        'running' => DownloadState.running,
        'complete' => DownloadState.complete,
        'failed' => DownloadState.failed,
        'paused' => DownloadState.paused,
        _ => DownloadState.idle,
      };

  Future<void> _onStatus(TaskStatusUpdate event) async {
    final episodeId = event.task.taskId;
    String state;
    String? localPath;
    switch (event.status) {
      case TaskStatus.complete:
        state = 'complete';
        final file = await _fileFor(episodeId);
        localPath = file.path;
        break;
      case TaskStatus.running:
        state = 'running';
        break;
      case TaskStatus.enqueued:
        state = 'queued';
        break;
      case TaskStatus.paused:
        state = 'paused';
        break;
      case TaskStatus.failed:
      case TaskStatus.canceled:
      case TaskStatus.notFound:
        state = 'failed';
        break;
      default:
        state = 'queued';
    }
    await (_db.update(_db.downloads)..where((t) => t.episodeId.equals(episodeId)))
        .write(DownloadsCompanion(
      state: d.Value(state),
      localPath: localPath != null ? d.Value(localPath) : const d.Value.absent(),
      progress: state == 'complete' ? const d.Value(1.0) : const d.Value.absent(),
    ));
    final status = await _currentStatus(episodeId);
    debugPrint(
        '[download] ↪ status ep=$episodeId → $state${localPath != null ? "  saved=$localPath" : ""}');
    _streams[episodeId]?.add(status);
  }

  Future<void> _onProgress(TaskProgressUpdate event) async {
    final episodeId = event.task.taskId;
    await (_db.update(_db.downloads)..where((t) => t.episodeId.equals(episodeId)))
        .write(DownloadsCompanion(
      progress: d.Value(event.progress),
      bytesDownloaded: d.Value(event.expectedFileSize > 0
          ? (event.progress * event.expectedFileSize).round()
          : 0),
      totalBytes: event.expectedFileSize > 0 ? d.Value(event.expectedFileSize) : const d.Value.absent(),
    ));
    final status = await _currentStatus(episodeId);
    _streams[episodeId]?.add(status);
  }

  @override
  Future<int> totalBytesUsed() async {
    final rows = await (_db.select(_db.downloads)..where((t) => t.localPath.isNotNull())).get();
    int total = 0;
    for (final r in rows) {
      try {
        final f = File(r.localPath!);
        if (await f.exists()) total += await f.length();
      } catch (_) {}
    }
    return total;
  }

  @override
  Future<List<DownloadStatus>> all() async {
    final rows = await _db.select(_db.downloads).get();
    return [
      for (final r in rows)
        DownloadStatus(
          episodeId: r.episodeId,
          state: _stateFromString(r.state),
          progress: r.progress,
          bytesDownloaded: r.bytesDownloaded,
          totalBytes: r.totalBytes,
          localPath: r.localPath,
        )
    ];
  }
}
