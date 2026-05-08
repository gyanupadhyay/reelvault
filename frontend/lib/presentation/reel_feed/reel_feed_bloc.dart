// lib/presentation/reel_feed/reel_feed_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
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

  // The router constructs us with `..add(ReelFeedStarted())`, so the very
  // first state emitted is "loading"-true with no reels yet. Without this,
  // the screen's first paint catches `loading=false reels=[]` and flashes
  // the "No reels yet" empty-state for a frame before the cache read fires.
  ReelFeedBloc(this._repo) : super(const ReelFeedState(loading: true)) {
    on<ReelFeedStarted>(_onStarted);
    on<ReelIndexChanged>(_onIndexChanged);
    on<ReelFeedLoadMore>(_onLoadMore);
  }

  Future<void> _onStarted(ReelFeedStarted e, Emitter<ReelFeedState> emit) async {
    // Phase 1 — fast path. Read cached reels from Drift and emit immediately so
    // the feed renders before the network responds. nextCursor stays null
    // (=> "we don't know yet") so pagination is gated on the network result.
    try {
      final cached = await _repo.getCachedReels();
      if (cached.isNotEmpty) {
        debugPrint('[reels] ⚡ rendering ${cached.length} cached reels (network refresh in flight)');
        emit(state.copyWith(reels: cached, loading: true, clearError: true));
      } else {
        emit(state.copyWith(loading: true, clearError: true));
      }
    } catch (_) {
      // Cache read failed — go straight to network.
      emit(state.copyWith(loading: true, clearError: true));
    }

    // Phase 2 — network refresh. Always run; on success, replace state with
    // fresh data + real nextCursor. On error, keep cached reels visible (don't
    // surface a red banner if we already showed something).
    try {
      final r = await _repo.fetchReels(cursor: 0, limit: 20);
      emit(state.copyWith(reels: r.items, nextCursor: r.nextCursor, loading: false));
    } catch (err) {
      if (state.reels.isEmpty) {
        emit(state.copyWith(loading: false, error: err.toString()));
      } else {
        debugPrint('[reels] ⚠ network refresh failed; keeping cached reels visible: $err');
        emit(state.copyWith(loading: false));
      }
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
