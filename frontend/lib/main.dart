// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';

// Process start time, used to measure cold-start-to-first-reel latency.
// Read by VideoControllerPool when the first reel actually starts playing.
final DateTime kAppStartedAt = DateTime.now();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[startup] main() entered (t=0)');
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  // Edge-to-edge + transparent system bars so Flutter receives the real
  // top/bottom system insets via MediaQuery.viewPadding. Without this, the
  // Android gesture bar can sit on top of our overlays and our SafeArea /
  // viewPadding math reports zero.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await setupLocator();
  debugPrint(
      '[startup] DI ready @ ${DateTime.now().difference(kAppStartedAt).inMilliseconds}ms — runApp()');
  runApp(const ReelVaultApp());
}

class ReelVaultApp extends StatelessWidget {
  const ReelVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = buildRouter();
    return MaterialApp.router(
      title: 'ReelVault',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
