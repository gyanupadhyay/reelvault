// lib/domain/entities/watch_progress.dart
import 'package:equatable/equatable.dart';

class WatchProgress extends Equatable {
  final String episodeId;
  final int progressSeconds;
  final DateTime lastWatchedAt;
  final bool completed;
  final bool synced;

  const WatchProgress({
    required this.episodeId,
    required this.progressSeconds,
    required this.lastWatchedAt,
    required this.completed,
    this.synced = false,
  });

  @override
  List<Object?> get props => [episodeId, progressSeconds, lastWatchedAt, completed, synced];
}
