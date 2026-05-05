import 'package:get_it/get_it.dart';

import '../../data/datasources/remote_data_source.dart';
import '../../data/repositories/download_repository_impl.dart';
import '../../data/repositories/repositories_impl.dart';
import '../../domain/repositories/repositories.dart';
import '../network/api_client.dart';
import '../network/connectivity_service.dart';
import '../storage/app_database.dart';

final sl = GetIt.instance;

/// Override with `--dart-define=API_BASE_URL=http://10.0.2.2:3000` (emulator),
/// `http://localhost:3000` (iOS sim), or `http://<lan-ip>:3000` (real device
/// on LAN).
const kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://reelvault-umr4.onrender.com',
);

Future<void> setupLocator() async {
  sl.registerLazySingleton<ApiClient>(() => ApiClient(baseUrl: kBaseUrl));
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerLazySingleton<RemoteDataSource>(() => RemoteDataSource(sl()));
  sl.registerLazySingleton<ReelRepository>(() => ReelRepositoryImpl(sl()));
  sl.registerLazySingleton<SeriesRepository>(() => SeriesRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<ProgressRepository>(() => ProgressRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<DownloadRepository>(() => DownloadRepositoryImpl(sl()));

  sl<ConnectivityService>().changes.listen((online) {
    if (online) sl<ProgressRepository>().syncPending();
  });

  // Kick the /reels HTTP off before the bloc mounts so it overlaps with
  // framework boot. The bloc's first fetchReels(cursor:0) hands back this
  // future instead of doing a duplicate request.
  sl<ReelRepository>().startPrefetch();
}
