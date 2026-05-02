// lib/domain/entities/reel.dart
import 'package:equatable/equatable.dart';

class Reel extends Equatable {
  final String id;
  final String seriesId;
  final String episodeId;
  final String videoUrl;
  final int durationSec;
  final String seriesTitle;
  final String episodeTitle;
  final int episodeNumber;

  const Reel({
    required this.id,
    required this.seriesId,
    required this.episodeId,
    required this.videoUrl,
    required this.durationSec,
    required this.seriesTitle,
    required this.episodeTitle,
    required this.episodeNumber,
  });

  @override
  List<Object?> get props => [id, seriesId, episodeId, videoUrl];
}
