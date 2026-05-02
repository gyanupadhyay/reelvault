// lib/domain/entities/episode.dart
import 'package:equatable/equatable.dart';

class Episode extends Equatable {
  final String id;
  final String seriesId;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final int durationSec;
  final int episodeNumber;
  final int progressSeconds;
  final bool completed;
  final String? localPath; // set when downloaded

  const Episode({
    required this.id,
    required this.seriesId,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.durationSec,
    required this.episodeNumber,
    this.progressSeconds = 0,
    this.completed = false,
    this.localPath,
  });

  bool get isDownloaded => localPath != null;
  double get progressFraction => durationSec == 0 ? 0 : (progressSeconds / durationSec).clamp(0.0, 1.0);

  Episode copyWith({
    int? progressSeconds,
    bool? completed,
    String? localPath,
  }) =>
      Episode(
        id: id,
        seriesId: seriesId,
        title: title,
        description: description,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        durationSec: durationSec,
        episodeNumber: episodeNumber,
        progressSeconds: progressSeconds ?? this.progressSeconds,
        completed: completed ?? this.completed,
        localPath: localPath ?? this.localPath,
      );

  @override
  List<Object?> get props => [id, progressSeconds, completed, localPath];
}
