// lib/core/storage/app_database.dart
//
// Drift schema. Run `dart run build_runner build` after pubspec install to generate
// `app_database.g.dart`. The generated file is intentionally not included here — it's
// produced at build time.
//
// Tables:
//  - cached_reels:     for instant cold-start of the reel feed (v2)
//  - cached_episodes:  for offline reads of series/episode metadata
//  - progress_local:   our source of truth for watch progress, with `synced` flag
//  - downloads:        local download tracking
//
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class CachedReels extends Table {
  TextColumn get id => text()();
  TextColumn get seriesId => text()();
  TextColumn get episodeId => text()();
  TextColumn get videoUrl => text()();
  IntColumn get durationSec => integer()();
  IntColumn get rank => integer()();
  TextColumn get seriesTitle => text()();
  TextColumn get episodeTitle => text()();
  IntColumn get episodeNumber => integer()();
  TextColumn get thumbnailUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedEpisodes extends Table {
  TextColumn get id => text()();
  TextColumn get seriesId => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get videoUrl => text()();
  TextColumn get thumbnailUrl => text()();
  IntColumn get durationSec => integer()();
  IntColumn get episodeNumber => integer()();
  TextColumn get seriesTitle => text().withDefault(const Constant(''))();
  TextColumn get seriesDescription => text().withDefault(const Constant(''))();
  TextColumn get seriesThumb => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

class ProgressLocal extends Table {
  TextColumn get episodeId => text()();
  IntColumn get progressSeconds => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastWatchedAt => dateTime()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {episodeId};
}

class Downloads extends Table {
  TextColumn get episodeId => text()();
  TextColumn get taskId => text()();
  TextColumn get state => text()();
  RealColumn get progress => real().withDefault(const Constant(0))();
  IntColumn get bytesDownloaded => integer().withDefault(const Constant(0))();
  IntColumn get totalBytes => integer().nullable()();
  TextColumn get localPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {episodeId};
}

@DriftDatabase(tables: [CachedReels, CachedEpisodes, ProgressLocal, Downloads])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'reelvault'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // v1 → v2: add cached_reels for instant cold-start of the reel feed.
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(cachedReels);
          }
        },
      );
}
