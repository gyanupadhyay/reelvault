// lib/data/datasources/remote_data_source.dart
import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../domain/entities/episode.dart';
import '../../domain/entities/reel.dart';
import '../../domain/entities/series.dart';
import '../../domain/repositories/repositories.dart';

class RemoteDataSource {
  final ApiClient _client;
  RemoteDataSource(this._client);

  Dio get _dio => _client.dio;

  Future<({List<Reel> items, int? nextCursor})> fetchReels(
      {int cursor = 0, int limit = 20}) async {
    final r = await _dio.get('/reels', queryParameters: {'cursor': cursor, 'limit': limit});
    final items = (r.data['items'] as List).map<Reel>((j) => Reel(
          id: j['id'],
          seriesId: j['series_id'],
          episodeId: j['episode_id'],
          videoUrl: j['video_url'],
          durationSec: j['duration_sec'],
          seriesTitle: j['series_title'],
          episodeTitle: j['episode_title'],
          episodeNumber: j['episode_number'],
        )).toList();
    return (items: items, nextCursor: r.data['next_cursor'] as int?);
  }

  Future<Series> fetchSeries(String id) async {
    final r = await _dio.get('/series/$id');
    final j = r.data as Map<String, dynamic>;
    final episodes = (j['episodes'] as List).map((e) => Episode(
          id: e['id'],
          seriesId: e['series_id'],
          title: e['title'],
          description: e['description'],
          videoUrl: e['video_url'],
          thumbnailUrl: e['thumbnail_url'],
          durationSec: e['duration_sec'],
          episodeNumber: e['episode_number'],
          progressSeconds: (e['progress_seconds'] ?? 0) as int,
          completed: ((e['completed'] ?? 0) as int) != 0,
        )).toList();
    return Series(
      id: j['id'],
      title: j['title'],
      description: j['description'],
      thumbnailUrl: j['thumbnail_url'],
      episodeCount: j['episode_count'],
      episodes: episodes,
    );
  }

  Future<int> fetchProgress(String episodeId) async {
    final r = await _dio.get('/progress/$episodeId');
    return (r.data['progress_seconds'] ?? 0) as int;
  }

  Future<Map<String, dynamic>> putProgress({
    required String episodeId,
    required int progressSeconds,
    required DateTime lastWatchedAt,
    required bool completed,
  }) async {
    final r = await _dio.put('/progress/$episodeId', data: {
      'progress_seconds': progressSeconds,
      'last_watched_at': lastWatchedAt.toUtc().toIso8601String(),
      'completed': completed,
    });
    return r.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> bulkSync(List<Map<String, dynamic>> items) async {
    final r = await _dio.post('/progress/bulk-sync', data: {'items': items});
    return ((r.data['resolved'] ?? []) as List).cast<Map<String, dynamic>>();
  }

  Future<List<ContinueWatchingItem>> continueWatching() async {
    final r = await _dio.get('/continue-watching');
    return ((r.data['items'] ?? []) as List)
        .map((j) => ContinueWatchingItem(
              episodeId: j['episode_id'],
              episodeTitle: j['episode_title'],
              episodeNumber: j['episode_number'],
              durationSec: j['duration_sec'],
              seriesId: j['series_id'],
              seriesTitle: j['series_title'],
              seriesThumb: j['series_thumb'] ?? j['episode_thumb'] ?? '',
              progressSeconds: (j['progress_seconds'] ?? 0) as int,
            ))
        .toList();
  }
}
