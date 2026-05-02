// lib/core/di/service_locator.dart
import 'package:get_it/get_it.dart';

import '../../data/datasources/remote_data_source.dart';
import '../../data/repositories/download_repository_impl.dart';
import '../../data/repositories/repositories_impl.dart';
import '../../domain/repositories/repositories.dart';
import '../network/api_client.dart';
import '../network/connectivity_service.dart';
import '../storage/app_database.dart';

final sl = GetIt.instance;

/// Set the API base URL for your environment.
/// Android emulator: http://10.0.2.2:3000
/// iOS simulator:    http://localhost:3000
/// Real device:      http://<your-mac-lan-ip>:3000
const kBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000');

Future<void> setupLocator() async {
  // Core
  sl.registerLazySingleton<ApiClient>(() => ApiClient(baseUrl: kBaseUrl));
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());

  // Data sources
  sl.registerLazySingleton<RemoteDataSource>(() => RemoteDataSource(sl()));

  // Repositories
  sl.registerLazySingleton<ReelRepository>(() => ReelRepositoryImpl(sl()));
  sl.registerLazySingleton<SeriesRepository>(() => SeriesRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<ProgressRepository>(() => ProgressRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<DownloadRepository>(() => DownloadRepositoryImpl(sl()));

  // Sync on reconnect.
  sl<ConnectivityService>().changes.listen((online) {
    if (online) sl<ProgressRepository>().syncPending();
  });

  // Eager prefetch of the reel feed first page. Overlaps the HTTP roundtrip
  // with Flutter bootstrap + first frame so the bloc has data the instant the
  // feed screen mounts. Saves 200–700ms off cold start in real-device testing.
  sl<ReelRepository>().startPrefetch();
}
