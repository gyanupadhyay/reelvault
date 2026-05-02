import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/service_locator.dart';
import '../../domain/repositories/repositories.dart';

class ContinueWatchingScreen extends StatefulWidget {
  const ContinueWatchingScreen({super.key});

  @override
  State<ContinueWatchingScreen> createState() => _ContinueWatchingScreenState();
}

class _ContinueWatchingScreenState extends State<ContinueWatchingScreen> {
  late Future<List<ContinueWatchingItem>> _future;

  @override
  void initState() {
    super.initState();
    debugPrint('[continue] 📺 screen opened — fetching items');
    _future = sl<ProgressRepository>().continueWatching().then((items) {
      debugPrint(
          '[continue] ✓ loaded ${items.length} item(s)${items.isEmpty ? '' : ': ${items.map((i) => "${i.episodeId}@${i.progressSeconds}s").join(", ")}'}');
      return items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Continue Watching')),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<ContinueWatchingItem>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data!;
            if (items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    "Nothing in progress yet.\nStart watching an episode and it'll show up here.",
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final item = items[i];
                final fraction = item.durationSec == 0
                    ? 0.0
                    : (item.progressSeconds / item.durationSec).clamp(0.0, 1.0);
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      item.seriesThumb,
                      width: 56,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(width: 56, height: 80, color: Colors.grey),
                    ),
                  ),
                  title: Text(item.seriesTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ep ${item.episodeNumber}: ${item.episodeTitle}'),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                              value: fraction, minHeight: 4),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_fmt(item.progressSeconds)} / ${_fmt(item.durationSec)}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.play_circle_outline),
                  onTap: () =>
                      context.push('/player/${item.seriesId}/${item.episodeId}'),
                );
              },
            );
          },
        ),
      ),
    );
  }

  static String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
