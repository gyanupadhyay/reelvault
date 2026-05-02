// lib/presentation/series/series_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/series.dart';
import '../../domain/repositories/repositories.dart';

sealed class SeriesEvent extends Equatable {
  const SeriesEvent();
  @override
  List<Object?> get props => [];
}

class SeriesRequested extends SeriesEvent {
  final String seriesId;
  const SeriesRequested(this.seriesId);
  @override
  List<Object?> get props => [seriesId];
}

class DownloadEpisodeRequested extends SeriesEvent {
  final String episodeId;
  const DownloadEpisodeRequested(this.episodeId);
}

class DeleteEpisodeDownload extends SeriesEvent {
  final String episodeId;
  const DeleteEpisodeDownload(this.episodeId);
}

class DeleteAllSeriesDownloads extends SeriesEvent {
  final String seriesId;
  const DeleteAllSeriesDownloads(this.seriesId);
  @override
  List<Object?> get props => [seriesId];
}

class SeriesState extends Equatable {
  final Series? series;
  final bool loading;
  final String? error;

  const SeriesState({this.series, this.loading = false, this.error});

  SeriesState copyWith({Series? series, bool? loading, String? error, bool clearError = false}) =>
      SeriesState(
        series: series ?? this.series,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [series, loading, error];
}

class SeriesBloc extends Bloc<SeriesEvent, SeriesState> {
  final SeriesRepository _series;
  final DownloadRepository _downloads;

  SeriesBloc(this._series, this._downloads) : super(const SeriesState()) {
    on<SeriesRequested>((e, emit) async {
      emit(state.copyWith(loading: true, clearError: true));
      try {
        final s = await _series.fetchSeries(e.seriesId);
        emit(state.copyWith(series: s, loading: false));
      } catch (err) {
        emit(state.copyWith(loading: false, error: err.toString()));
      }
    });
    on<DownloadEpisodeRequested>((e, emit) async {
      final ep = state.series?.episodes.firstWhere((x) => x.id == e.episodeId);
      if (ep == null) return;
      await _downloads.enqueue(ep);
    });
    on<DeleteEpisodeDownload>((e, emit) async {
      await _downloads.deleteDownload(e.episodeId);
      add(SeriesRequested(state.series!.id));
    });
    on<DeleteAllSeriesDownloads>((e, emit) async {
      final downloaded =
          state.series?.episodes.where((ep) => ep.localPath != null).toList() ?? const [];
      for (final ep in downloaded) {
        await _downloads.deleteDownload(ep.id);
      }
      add(SeriesRequested(e.seriesId));
    });
  }
}
