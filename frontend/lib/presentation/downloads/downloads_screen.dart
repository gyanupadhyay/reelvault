import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/storage/app_database.dart';
import '../../domain/repositories/repositories.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  late Future<_LoadResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_LoadResult> _load() async {
    final downloads = await sl<DownloadRepository>().all();
    final totalBytes = await sl<DownloadRepository>().totalBytesUsed();

    final db = sl<AppDatabase>();
    final ids = downloads.map((d) => d.episodeId).toList();
    final episodes = ids.isEmpty
        ? <CachedEpisode>[]
        : await (db.select(db.cachedEpisodes)..where((t) => t.id.isIn(ids))).get();
    final byId = {for (final e in episodes) e.id: e};
    return _LoadResult(downloads: downloads, episodes: byId, totalBytes: totalBytes);
  }

  void _refresh() {
    if (mounted) setState(() => _future = _load());
  }

  String _fmtBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<_LoadResult>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final r = snap.data!;
            if (r.downloads.isEmpty) {
              return const Center(child: Text('No downloads yet'));
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Storage used',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_fmtBytes(r.totalBytes)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: r.downloads.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final initial = r.downloads[i];
                      final ep = r.episodes[initial.episodeId];
                      return StreamBuilder<DownloadStatus>(
                        initialData: initial,
                        stream: sl<DownloadRepository>().watch(initial.episodeId),
                        builder: (context, statusSnap) {
                          final d = statusSnap.data ?? initial;
                          return _DownloadRow(
                            status: d,
                            title: ep != null
                                ? '${ep.seriesTitle} · Ep ${ep.episodeNumber}'
                                : d.episodeId,
                            subtitle: _subtitle(d),
                            onPause: () async {
                              await sl<DownloadRepository>().pause(d.episodeId);
                            },
                            onResume: () async {
                              await sl<DownloadRepository>().resume(d.episodeId);
                            },
                            onCancel: () async {
                              await sl<DownloadRepository>().cancel(d.episodeId);
                              _refresh();
                            },
                            onDelete: () async {
                              await sl<DownloadRepository>().deleteDownload(d.episodeId);
                              _refresh();
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _subtitle(DownloadStatus d) {
    switch (d.state) {
      case DownloadState.complete:
        return 'Ready · ${(d.totalBytes ?? d.bytesDownloaded) > 0 ? _fmtBytes(d.totalBytes ?? d.bytesDownloaded) : ''}';
      case DownloadState.running:
        return 'Downloading · ${(d.progress * 100).toStringAsFixed(0)}%';
      case DownloadState.queued:
        return 'Queued';
      case DownloadState.paused:
        return 'Paused · ${(d.progress * 100).toStringAsFixed(0)}%';
      case DownloadState.failed:
        return 'Failed';
      case DownloadState.idle:
        return '';
    }
  }
}

class _DownloadRow extends StatelessWidget {
  final DownloadStatus status;
  final String title;
  final String subtitle;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const _DownloadRow({
    required this.status,
    required this.title,
    required this.subtitle,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            if (status.state == DownloadState.running ||
                status.state == DownloadState.paused) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: status.progress > 0 ? status.progress : null,
                  minHeight: 3,
                ),
              ),
            ],
          ],
        ),
      ),
      trailing: _actions(),
    );
  }

  Widget _actions() {
    final buttons = <Widget>[];
    switch (status.state) {
      case DownloadState.running:
        buttons.add(_iconBtn(Icons.pause, 'Pause', onPause));
        buttons.add(_iconBtn(Icons.close, 'Cancel', onCancel));
        break;
      case DownloadState.paused:
        buttons.add(_iconBtn(Icons.play_arrow, 'Resume', onResume));
        buttons.add(_iconBtn(Icons.close, 'Cancel', onCancel));
        break;
      case DownloadState.queued:
        buttons.add(_iconBtn(Icons.close, 'Cancel', onCancel));
        break;
      case DownloadState.complete:
        buttons.add(_iconBtn(Icons.delete_outline, 'Delete', onDelete));
        break;
      case DownloadState.failed:
        buttons.add(_iconBtn(Icons.delete_outline, 'Remove', onDelete));
        break;
      case DownloadState.idle:
        break;
    }
    return Row(mainAxisSize: MainAxisSize.min, children: buttons);
  }

  Widget _iconBtn(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: onPressed);
  }
}

class _LoadResult {
  final List<DownloadStatus> downloads;
  final Map<String, CachedEpisode> episodes;
  final int totalBytes;
  _LoadResult({
    required this.downloads,
    required this.episodes,
    required this.totalBytes,
  });
}
