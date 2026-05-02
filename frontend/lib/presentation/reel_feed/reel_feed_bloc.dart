// lib/presentation/reel_feed/reel_feed_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/reel.dart';
import '../../domain/repositories/repositories.dart';

// Events
sealed class ReelFeedEvent extends Equatable {
  const ReelFeedEvent();
  @override
  List<Object?> get props => [];
}

class ReelFeedStarted extends ReelFeedEvent {
  const ReelFeedStarted();
}

class ReelIndexChanged extends ReelFeedEvent {
  final int index;
  const ReelIndexChanged(this.index);
  @override
  List<Object?> get props => [index];
}

class ReelFeedLoadMore extends ReelFeedEvent {
  const ReelFeedLoadMore();
}

// State
class ReelFeedState extends Equatable {
  final List<Reel> reels;
  final int? nextCursor;
  final int activeIndex;
  final bool loading;
  final String? error;

  const ReelFeedState({
    this.reels = const [],
    this.nextCursor = 0,
    this.activeIndex = 0,
    this.loading = false,
    this.error,
  });

  ReelFeedState copyWith({
    List<Reel>? reels,
    int? nextCursor,
    int? activeIndex,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      ReelFeedState(
        reels: reels ?? this.reels,
        nextCursor: nextCursor ?? this.nextCursor,
        activeIndex: activeIndex ?? this.activeIndex,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [reels, nextCursor, activeIndex, loading, error];
}

class ReelFeedBloc extends Bloc<ReelFeedEvent, ReelFeedState> {
  final ReelRepository _repo;

  ReelFeedBloc(this._repo) : super(const ReelFeedState()) {
    on<ReelFeedStarted>(_onStarted);
    on<ReelIndexChanged>(_onIndexChanged);
    on<ReelFeedLoadMore>(_onLoadMore);
  }

  Future<void> _onStarted(ReelFeedStarted e, Emitter<ReelFeedState> emit) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final r = await _repo.fetchReels(cursor: 0, limit: 20);
      emit(state.copyWith(reels: r.items, nextCursor: r.nextCursor, loading: false));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

  Future<void> _onIndexChanged(ReelIndexChanged e, Emitter<ReelFeedState> emit) async {
    // Always update the index immediately so PageView state is consistent.
    emit(state.copyWith(activeIndex: e.index));

    // Trigger pagination when within 3 of the end.
    if (state.nextCursor != null && e.index >= state.reels.length - 3) {
      add(const ReelFeedLoadMore());
    }
  }

  Future<void> _onLoadMore(ReelFeedLoadMore e, Emitter<ReelFeedState> emit) async {
    if (state.loading || state.nextCursor == null) return;
    emit(state.copyWith(loading: true));
    try {
      final r = await _repo.fetchReels(cursor: state.nextCursor!, limit: 20);
      emit(state.copyWith(
        reels: [...state.reels, ...r.items],
        nextCursor: r.nextCursor,
        loading: false,
      ));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

}
