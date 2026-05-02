// lib/domain/entities/series.dart
import 'package:equatable/equatable.dart';
import 'episode.dart';

class Series extends Equatable {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final int episodeCount;
  final List<Episode> episodes;

  const Series({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.episodeCount,
    this.episodes = const [],
  });

  Series copyWith({List<Episode>? episodes}) => Series(
        id: id,
        title: title,
        description: description,
        thumbnailUrl: thumbnailUrl,
        episodeCount: episodeCount,
        episodes: episodes ?? this.episodes,
      );

  @override
  List<Object?> get props => [id, title, episodeCount, episodes];
}
