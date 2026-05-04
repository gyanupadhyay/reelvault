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
  // Thumbnail of the episode this reel previews. Used as a placeholder under
  // the VideoPlayer so the user never sees a white spinner during init.
  // Nullable because the backend may omit it; UI falls back to a gradient.
  final String? thumbnailUrl;

  const Reel({
    required this.id,
    required this.seriesId,
    required this.episodeId,
    required this.videoUrl,
    required this.durationSec,
    required this.seriesTitle,
    required this.episodeTitle,
    required this.episodeNumber,
    this.thumbnailUrl,
  });

  @override
  List<Object?> get props =>
      [id, seriesId, episodeId, videoUrl, thumbnailUrl];
}
