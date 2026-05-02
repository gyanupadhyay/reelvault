import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/repositories/repositories.dart';
import '../../presentation/continue_watching/continue_watching_screen.dart';
import '../../presentation/downloads/downloads_screen.dart';
import '../../presentation/player/player_screen.dart';
import '../../presentation/reel_feed/reel_feed_bloc.dart';
import '../../presentation/reel_feed/reel_feed_screen.dart';
import '../../presentation/series/series_bloc.dart';
import '../../presentation/series/series_screen.dart';
import '../di/service_locator.dart';

GoRouter buildRouter() => GoRouter(
      initialLocation: '/feed',
      routes: [
        // Shell keeps ReelFeedBloc alive so the feed retains scroll position when
        // the user dives into a series and comes back.
        ShellRoute(
          builder: (context, state, child) => BlocProvider(
            create: (_) =>
                ReelFeedBloc(sl<ReelRepository>())..add(const ReelFeedStarted()),
            child: child,
          ),
          routes: [
            GoRoute(path: '/feed', builder: (_, __) => const ReelFeedScreen()),
            GoRoute(
              path: '/series/:seriesId',
              builder: (_, state) => BlocProvider(
                create: (_) =>
                    SeriesBloc(sl<SeriesRepository>(), sl<DownloadRepository>())
                      ..add(SeriesRequested(state.pathParameters['seriesId']!)),
                child: SeriesScreen(
                  seriesId: state.pathParameters['seriesId']!,
                  fromEpisodeId: state.uri.queryParameters['fromEpisodeId'],
                ),
              ),
            ),
            GoRoute(
              path: '/player/:seriesId/:episodeId',
              builder: (_, state) => PlayerScreen(
                seriesId: state.pathParameters['seriesId']!,
                episodeId: state.pathParameters['episodeId']!,
              ),
            ),
            GoRoute(path: '/downloads', builder: (_, __) => const DownloadsScreen()),
            GoRoute(
                path: '/continue-watching',
                builder: (_, __) => const ContinueWatchingScreen()),
          ],
        ),
      ],
    );
