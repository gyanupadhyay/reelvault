# ReelVault Frontend

Flutter app (iOS + Android). Talks to the deployed Render backend by default — `https://reelvault-umr4.onrender.com`. Override via `--dart-define=API_BASE_URL=...` when targeting a local backend.

## Setup

```bash
cd frontend
flutter pub get
dart run build_runner build   # Drift codegen
flutter run
```

That's it. The app fetches reels from the live backend out of the box.

## Backend URL by target

| Target | Command |
|---|---|
| **Default (deployed Render)** | `flutter run` |
| Android emulator → local | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000` |
| iOS simulator → local | `flutter run --dart-define=API_BASE_URL=http://localhost:3000` |
| Real device → local | `flutter run --dart-define=API_BASE_URL=http://<your-LAN-ip>:3000` |

## Architecture overview

```
lib/
├── core/             DI (get_it), router (go_router), networking (dio), storage (drift), connectivity
├── domain/           Pure-Dart entities + repository interfaces
├── data/             Repository implementations, remote data source, local cache
└── presentation/     Screens, BLoCs, widgets
```

The presentation layer talks only to the domain layer's repository interfaces. The data layer satisfies them. Swapping backend or storage engine never touches presentation code.

Detailed coverage of the controller pool, scroll-settle, preload strategy, lifecycle, monotonic progress, and offline sync is in the project-root [`ARCHITECTURE.md`](../ARCHITECTURE.md).

## Building a release APK

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

To target a custom backend at build time:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-staging-backend.com
```

## Project root README

For setup of both backend and frontend together, deployment to Render, and per-feature manual tests, see the [project-root README](../README.md).
