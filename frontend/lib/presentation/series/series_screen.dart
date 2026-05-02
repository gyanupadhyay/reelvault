import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/service_locator.dart';
import '../../domain/entities/episode.dart';
import '../../domain/repositories/repositories.dart';
import 'series_bloc.dart';

class SeriesScreen extends StatelessWidget {
  final String seriesId;
  final String? fromEpisodeId;
  const SeriesScreen({super.key, required this.seriesId, this.fromEpisodeId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SeriesBloc, SeriesState>(
      builder: (context, state) {
        if (state.loading && state.series == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final s = state.series;
        if (s == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(state.error ?? 'Failed to load')),
          );
        }
        final continueFrom = s.episodes.firstWhere(
          (e) => !e.completed && e.progressSeconds > 0,
          orElse: () => s.episodes.first,
        );
        final totalSec = s.episodes.fold<int>(0, (sum, e) => sum + e.durationSec);
        final downloadedCount = s.episodes.where((e) => e.localPath != null).length;

        return Scaffold(
          appBar: AppBar(
            title: Text(s.title),
            actions: [
              if (downloadedCount > 0)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: 'Delete all $downloadedCount download${downloadedCount == 1 ? '' : 's'}',
                  onPressed: () => _confirmDeleteAll(context, s.id, downloadedCount),
                ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(s.thumbnailUrl, fit: BoxFit.cover),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text('${s.episodeCount} episodes · ${_fmtTotal(totalSec)}',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 12),
                      Text(s.description),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: Text(
                            continueFrom.progressSeconds > 0
                                ? 'Continue Ep ${continueFrom.episodeNumber}'
                                : 'Start Ep ${continueFrom.episodeNumber}',
                          ),
                          onPressed: () =>
                              context.push('/player/${s.id}/${continueFrom.id}'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ...s.episodes.map((e) => _EpisodeTile(
                      seriesId: s.id,
                      episode: e,
                      fromReel: e.id == fromEpisodeId,
                    )),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _fmtTotal(int seconds) {
    final m = (seconds / 60).round();
    if (m < 60) return '~$m min total';
    final h = m ~/ 60;
    final mm = m % 60;
    return '~${h}h ${mm}m total';
  }

  Future<void> _confirmDeleteAll(BuildContext context, String seriesId, int count) async {
    final bloc = context.read<SeriesBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete all downloads?'),
        content: Text(
            'This will free up $count downloaded episode${count == 1 ? '' : 's'} for this series.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      bloc.add(DeleteAllSeriesDownloads(seriesId));
    }
  }
}

class _EpisodeTile extends StatelessWidget {
  final String seriesId;
  final Episode episode;
  final bool fromReel;
  const _EpisodeTile({
    required this.seriesId,
    required this.episode,
    this.fromReel = false,
  });

  @override
  Widget build(BuildContext context) {
    final downloads = sl<DownloadRepository>();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: fromReel ? scheme.primaryContainer.withValues(alpha: 0.4) : null,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            episode.thumbnailUrl,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(width: 64, height: 64, color: Colors.grey),
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text('Ep ${episode.episodeNumber}: ${episode.title}')),
            if (fromReel) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'From reel',
                  style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${(episode.durationSec / 60).toStringAsFixed(1)} min'),
            if (episode.progressSeconds > 0) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: episode.progressFraction,
                  minHeight: 3,
                ),
              ),
            ],
          ],
        ),
        trailing: StreamBuilder<DownloadStatus>(
          stream: downloads.watch(episode.id),
          builder: (context, snap) {
            final s = snap.data;
            if (s == null || s.state == DownloadState.idle) {
              return IconButton(
                icon: const Icon(Icons.download_outlined),
                onPressed: () => context
                    .read<SeriesBloc>()
                    .add(DownloadEpisodeRequested(episode.id)),
              );
            }
            if (s.state == DownloadState.complete) {
              return IconButton(
                icon: const Icon(Icons.download_done, color: Colors.green),
                onPressed: () => context
                    .read<SeriesBloc>()
                    .add(DeleteEpisodeDownload(episode.id)),
              );
            }
            if (s.state == DownloadState.failed) {
              return IconButton(
                icon: const Icon(Icons.refresh, color: Colors.red),
                onPressed: () => context
                    .read<SeriesBloc>()
                    .add(DownloadEpisodeRequested(episode.id)),
              );
            }
            return SizedBox(
              width: 36,
              height: 36,
              child:
                  CircularProgressIndicator(value: s.progress > 0 ? s.progress : null),
            );
          },
        ),
        onTap: () => context.push('/player/$seriesId/${episode.id}'),
      ),
    );
  }
}
