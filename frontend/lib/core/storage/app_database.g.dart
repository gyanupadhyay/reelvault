// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedEpisodesTable extends CachedEpisodes
    with TableInfo<$CachedEpisodesTable, CachedEpisode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedEpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _seriesIdMeta =
      const VerificationMeta('seriesId');
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
      'series_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _videoUrlMeta =
      const VerificationMeta('videoUrl');
  @override
  late final GeneratedColumn<String> videoUrl = GeneratedColumn<String>(
      'video_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _thumbnailUrlMeta =
      const VerificationMeta('thumbnailUrl');
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
      'thumbnail_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _durationSecMeta =
      const VerificationMeta('durationSec');
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
      'duration_sec', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _episodeNumberMeta =
      const VerificationMeta('episodeNumber');
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
      'episode_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _seriesTitleMeta =
      const VerificationMeta('seriesTitle');
  @override
  late final GeneratedColumn<String> seriesTitle = GeneratedColumn<String>(
      'series_title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _seriesDescriptionMeta =
      const VerificationMeta('seriesDescription');
  @override
  late final GeneratedColumn<String> seriesDescription =
      GeneratedColumn<String>('series_description', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  static const VerificationMeta _seriesThumbMeta =
      const VerificationMeta('seriesThumb');
  @override
  late final GeneratedColumn<String> seriesThumb = GeneratedColumn<String>(
      'series_thumb', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        seriesId,
        title,
        description,
        videoUrl,
        thumbnailUrl,
        durationSec,
        episodeNumber,
        seriesTitle,
        seriesDescription,
        seriesThumb
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_episodes';
  @override
  VerificationContext validateIntegrity(Insertable<CachedEpisode> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(_seriesIdMeta,
          seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta));
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('video_url')) {
      context.handle(_videoUrlMeta,
          videoUrl.isAcceptableOrUnknown(data['video_url']!, _videoUrlMeta));
    } else if (isInserting) {
      context.missing(_videoUrlMeta);
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
          _thumbnailUrlMeta,
          thumbnailUrl.isAcceptableOrUnknown(
              data['thumbnail_url']!, _thumbnailUrlMeta));
    } else if (isInserting) {
      context.missing(_thumbnailUrlMeta);
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
          _durationSecMeta,
          durationSec.isAcceptableOrUnknown(
              data['duration_sec']!, _durationSecMeta));
    } else if (isInserting) {
      context.missing(_durationSecMeta);
    }
    if (data.containsKey('episode_number')) {
      context.handle(
          _episodeNumberMeta,
          episodeNumber.isAcceptableOrUnknown(
              data['episode_number']!, _episodeNumberMeta));
    } else if (isInserting) {
      context.missing(_episodeNumberMeta);
    }
    if (data.containsKey('series_title')) {
      context.handle(
          _seriesTitleMeta,
          seriesTitle.isAcceptableOrUnknown(
              data['series_title']!, _seriesTitleMeta));
    }
    if (data.containsKey('series_description')) {
      context.handle(
          _seriesDescriptionMeta,
          seriesDescription.isAcceptableOrUnknown(
              data['series_description']!, _seriesDescriptionMeta));
    }
    if (data.containsKey('series_thumb')) {
      context.handle(
          _seriesThumbMeta,
          seriesThumb.isAcceptableOrUnknown(
              data['series_thumb']!, _seriesThumbMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedEpisode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedEpisode(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      seriesId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}series_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      videoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}video_url'])!,
      thumbnailUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_url'])!,
      durationSec: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_sec'])!,
      episodeNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}episode_number'])!,
      seriesTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}series_title'])!,
      seriesDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}series_description'])!,
      seriesThumb: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}series_thumb'])!,
    );
  }

  @override
  $CachedEpisodesTable createAlias(String alias) {
    return $CachedEpisodesTable(attachedDatabase, alias);
  }
}

class CachedEpisode extends DataClass implements Insertable<CachedEpisode> {
  final String id;
  final String seriesId;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final int durationSec;
  final int episodeNumber;
  final String seriesTitle;
  final String seriesDescription;
  final String seriesThumb;
  const CachedEpisode(
      {required this.id,
      required this.seriesId,
      required this.title,
      required this.description,
      required this.videoUrl,
      required this.thumbnailUrl,
      required this.durationSec,
      required this.episodeNumber,
      required this.seriesTitle,
      required this.seriesDescription,
      required this.seriesThumb});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['series_id'] = Variable<String>(seriesId);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['video_url'] = Variable<String>(videoUrl);
    map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    map['duration_sec'] = Variable<int>(durationSec);
    map['episode_number'] = Variable<int>(episodeNumber);
    map['series_title'] = Variable<String>(seriesTitle);
    map['series_description'] = Variable<String>(seriesDescription);
    map['series_thumb'] = Variable<String>(seriesThumb);
    return map;
  }

  CachedEpisodesCompanion toCompanion(bool nullToAbsent) {
    return CachedEpisodesCompanion(
      id: Value(id),
      seriesId: Value(seriesId),
      title: Value(title),
      description: Value(description),
      videoUrl: Value(videoUrl),
      thumbnailUrl: Value(thumbnailUrl),
      durationSec: Value(durationSec),
      episodeNumber: Value(episodeNumber),
      seriesTitle: Value(seriesTitle),
      seriesDescription: Value(seriesDescription),
      seriesThumb: Value(seriesThumb),
    );
  }

  factory CachedEpisode.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedEpisode(
      id: serializer.fromJson<String>(json['id']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      videoUrl: serializer.fromJson<String>(json['videoUrl']),
      thumbnailUrl: serializer.fromJson<String>(json['thumbnailUrl']),
      durationSec: serializer.fromJson<int>(json['durationSec']),
      episodeNumber: serializer.fromJson<int>(json['episodeNumber']),
      seriesTitle: serializer.fromJson<String>(json['seriesTitle']),
      seriesDescription: serializer.fromJson<String>(json['seriesDescription']),
      seriesThumb: serializer.fromJson<String>(json['seriesThumb']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'seriesId': serializer.toJson<String>(seriesId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'videoUrl': serializer.toJson<String>(videoUrl),
      'thumbnailUrl': serializer.toJson<String>(thumbnailUrl),
      'durationSec': serializer.toJson<int>(durationSec),
      'episodeNumber': serializer.toJson<int>(episodeNumber),
      'seriesTitle': serializer.toJson<String>(seriesTitle),
      'seriesDescription': serializer.toJson<String>(seriesDescription),
      'seriesThumb': serializer.toJson<String>(seriesThumb),
    };
  }

  CachedEpisode copyWith(
          {String? id,
          String? seriesId,
          String? title,
          String? description,
          String? videoUrl,
          String? thumbnailUrl,
          int? durationSec,
          int? episodeNumber,
          String? seriesTitle,
          String? seriesDescription,
          String? seriesThumb}) =>
      CachedEpisode(
        id: id ?? this.id,
        seriesId: seriesId ?? this.seriesId,
        title: title ?? this.title,
        description: description ?? this.description,
        videoUrl: videoUrl ?? this.videoUrl,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        durationSec: durationSec ?? this.durationSec,
        episodeNumber: episodeNumber ?? this.episodeNumber,
        seriesTitle: seriesTitle ?? this.seriesTitle,
        seriesDescription: seriesDescription ?? this.seriesDescription,
        seriesThumb: seriesThumb ?? this.seriesThumb,
      );
  CachedEpisode copyWithCompanion(CachedEpisodesCompanion data) {
    return CachedEpisode(
      id: data.id.present ? data.id.value : this.id,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      videoUrl: data.videoUrl.present ? data.videoUrl.value : this.videoUrl,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      durationSec:
          data.durationSec.present ? data.durationSec.value : this.durationSec,
      episodeNumber: data.episodeNumber.present
          ? data.episodeNumber.value
          : this.episodeNumber,
      seriesTitle:
          data.seriesTitle.present ? data.seriesTitle.value : this.seriesTitle,
      seriesDescription: data.seriesDescription.present
          ? data.seriesDescription.value
          : this.seriesDescription,
      seriesThumb:
          data.seriesThumb.present ? data.seriesThumb.value : this.seriesThumb,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedEpisode(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('durationSec: $durationSec, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('seriesTitle: $seriesTitle, ')
          ..write('seriesDescription: $seriesDescription, ')
          ..write('seriesThumb: $seriesThumb')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      seriesId,
      title,
      description,
      videoUrl,
      thumbnailUrl,
      durationSec,
      episodeNumber,
      seriesTitle,
      seriesDescription,
      seriesThumb);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedEpisode &&
          other.id == this.id &&
          other.seriesId == this.seriesId &&
          other.title == this.title &&
          other.description == this.description &&
          other.videoUrl == this.videoUrl &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.durationSec == this.durationSec &&
          other.episodeNumber == this.episodeNumber &&
          other.seriesTitle == this.seriesTitle &&
          other.seriesDescription == this.seriesDescription &&
          other.seriesThumb == this.seriesThumb);
}

class CachedEpisodesCompanion extends UpdateCompanion<CachedEpisode> {
  final Value<String> id;
  final Value<String> seriesId;
  final Value<String> title;
  final Value<String> description;
  final Value<String> videoUrl;
  final Value<String> thumbnailUrl;
  final Value<int> durationSec;
  final Value<int> episodeNumber;
  final Value<String> seriesTitle;
  final Value<String> seriesDescription;
  final Value<String> seriesThumb;
  final Value<int> rowid;
  const CachedEpisodesCompanion({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.seriesTitle = const Value.absent(),
    this.seriesDescription = const Value.absent(),
    this.seriesThumb = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedEpisodesCompanion.insert({
    required String id,
    required String seriesId,
    required String title,
    required String description,
    required String videoUrl,
    required String thumbnailUrl,
    required int durationSec,
    required int episodeNumber,
    this.seriesTitle = const Value.absent(),
    this.seriesDescription = const Value.absent(),
    this.seriesThumb = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        seriesId = Value(seriesId),
        title = Value(title),
        description = Value(description),
        videoUrl = Value(videoUrl),
        thumbnailUrl = Value(thumbnailUrl),
        durationSec = Value(durationSec),
        episodeNumber = Value(episodeNumber);
  static Insertable<CachedEpisode> custom({
    Expression<String>? id,
    Expression<String>? seriesId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? videoUrl,
    Expression<String>? thumbnailUrl,
    Expression<int>? durationSec,
    Expression<int>? episodeNumber,
    Expression<String>? seriesTitle,
    Expression<String>? seriesDescription,
    Expression<String>? seriesThumb,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesId != null) 'series_id': seriesId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (videoUrl != null) 'video_url': videoUrl,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (durationSec != null) 'duration_sec': durationSec,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (seriesTitle != null) 'series_title': seriesTitle,
      if (seriesDescription != null) 'series_description': seriesDescription,
      if (seriesThumb != null) 'series_thumb': seriesThumb,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedEpisodesCompanion copyWith(
      {Value<String>? id,
      Value<String>? seriesId,
      Value<String>? title,
      Value<String>? description,
      Value<String>? videoUrl,
      Value<String>? thumbnailUrl,
      Value<int>? durationSec,
      Value<int>? episodeNumber,
      Value<String>? seriesTitle,
      Value<String>? seriesDescription,
      Value<String>? seriesThumb,
      Value<int>? rowid}) {
    return CachedEpisodesCompanion(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSec: durationSec ?? this.durationSec,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      seriesTitle: seriesTitle ?? this.seriesTitle,
      seriesDescription: seriesDescription ?? this.seriesDescription,
      seriesThumb: seriesThumb ?? this.seriesThumb,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (videoUrl.present) {
      map['video_url'] = Variable<String>(videoUrl.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (seriesTitle.present) {
      map['series_title'] = Variable<String>(seriesTitle.value);
    }
    if (seriesDescription.present) {
      map['series_description'] = Variable<String>(seriesDescription.value);
    }
    if (seriesThumb.present) {
      map['series_thumb'] = Variable<String>(seriesThumb.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedEpisodesCompanion(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('durationSec: $durationSec, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('seriesTitle: $seriesTitle, ')
          ..write('seriesDescription: $seriesDescription, ')
          ..write('seriesThumb: $seriesThumb, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProgressLocalTable extends ProgressLocal
    with TableInfo<$ProgressLocalTable, ProgressLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _episodeIdMeta =
      const VerificationMeta('episodeId');
  @override
  late final GeneratedColumn<String> episodeId = GeneratedColumn<String>(
      'episode_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _progressSecondsMeta =
      const VerificationMeta('progressSeconds');
  @override
  late final GeneratedColumn<int> progressSeconds = GeneratedColumn<int>(
      'progress_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastWatchedAtMeta =
      const VerificationMeta('lastWatchedAt');
  @override
  late final GeneratedColumn<DateTime> lastWatchedAt =
      GeneratedColumn<DateTime>('last_watched_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _completedMeta =
      const VerificationMeta('completed');
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
      'completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [episodeId, progressSeconds, lastWatchedAt, completed, synced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progress_local';
  @override
  VerificationContext validateIntegrity(Insertable<ProgressLocalData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('episode_id')) {
      context.handle(_episodeIdMeta,
          episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta));
    } else if (isInserting) {
      context.missing(_episodeIdMeta);
    }
    if (data.containsKey('progress_seconds')) {
      context.handle(
          _progressSecondsMeta,
          progressSeconds.isAcceptableOrUnknown(
              data['progress_seconds']!, _progressSecondsMeta));
    }
    if (data.containsKey('last_watched_at')) {
      context.handle(
          _lastWatchedAtMeta,
          lastWatchedAt.isAcceptableOrUnknown(
              data['last_watched_at']!, _lastWatchedAtMeta));
    } else if (isInserting) {
      context.missing(_lastWatchedAtMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(_completedMeta,
          completed.isAcceptableOrUnknown(data['completed']!, _completedMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {episodeId};
  @override
  ProgressLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgressLocalData(
      episodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}episode_id'])!,
      progressSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}progress_seconds'])!,
      lastWatchedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_watched_at'])!,
      completed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}completed'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $ProgressLocalTable createAlias(String alias) {
    return $ProgressLocalTable(attachedDatabase, alias);
  }
}

class ProgressLocalData extends DataClass
    implements Insertable<ProgressLocalData> {
  final String episodeId;
  final int progressSeconds;
  final DateTime lastWatchedAt;
  final bool completed;
  final bool synced;
  const ProgressLocalData(
      {required this.episodeId,
      required this.progressSeconds,
      required this.lastWatchedAt,
      required this.completed,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['episode_id'] = Variable<String>(episodeId);
    map['progress_seconds'] = Variable<int>(progressSeconds);
    map['last_watched_at'] = Variable<DateTime>(lastWatchedAt);
    map['completed'] = Variable<bool>(completed);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  ProgressLocalCompanion toCompanion(bool nullToAbsent) {
    return ProgressLocalCompanion(
      episodeId: Value(episodeId),
      progressSeconds: Value(progressSeconds),
      lastWatchedAt: Value(lastWatchedAt),
      completed: Value(completed),
      synced: Value(synced),
    );
  }

  factory ProgressLocalData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgressLocalData(
      episodeId: serializer.fromJson<String>(json['episodeId']),
      progressSeconds: serializer.fromJson<int>(json['progressSeconds']),
      lastWatchedAt: serializer.fromJson<DateTime>(json['lastWatchedAt']),
      completed: serializer.fromJson<bool>(json['completed']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'episodeId': serializer.toJson<String>(episodeId),
      'progressSeconds': serializer.toJson<int>(progressSeconds),
      'lastWatchedAt': serializer.toJson<DateTime>(lastWatchedAt),
      'completed': serializer.toJson<bool>(completed),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  ProgressLocalData copyWith(
          {String? episodeId,
          int? progressSeconds,
          DateTime? lastWatchedAt,
          bool? completed,
          bool? synced}) =>
      ProgressLocalData(
        episodeId: episodeId ?? this.episodeId,
        progressSeconds: progressSeconds ?? this.progressSeconds,
        lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
        completed: completed ?? this.completed,
        synced: synced ?? this.synced,
      );
  ProgressLocalData copyWithCompanion(ProgressLocalCompanion data) {
    return ProgressLocalData(
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      progressSeconds: data.progressSeconds.present
          ? data.progressSeconds.value
          : this.progressSeconds,
      lastWatchedAt: data.lastWatchedAt.present
          ? data.lastWatchedAt.value
          : this.lastWatchedAt,
      completed: data.completed.present ? data.completed.value : this.completed,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgressLocalData(')
          ..write('episodeId: $episodeId, ')
          ..write('progressSeconds: $progressSeconds, ')
          ..write('lastWatchedAt: $lastWatchedAt, ')
          ..write('completed: $completed, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(episodeId, progressSeconds, lastWatchedAt, completed, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgressLocalData &&
          other.episodeId == this.episodeId &&
          other.progressSeconds == this.progressSeconds &&
          other.lastWatchedAt == this.lastWatchedAt &&
          other.completed == this.completed &&
          other.synced == this.synced);
}

class ProgressLocalCompanion extends UpdateCompanion<ProgressLocalData> {
  final Value<String> episodeId;
  final Value<int> progressSeconds;
  final Value<DateTime> lastWatchedAt;
  final Value<bool> completed;
  final Value<bool> synced;
  final Value<int> rowid;
  const ProgressLocalCompanion({
    this.episodeId = const Value.absent(),
    this.progressSeconds = const Value.absent(),
    this.lastWatchedAt = const Value.absent(),
    this.completed = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgressLocalCompanion.insert({
    required String episodeId,
    this.progressSeconds = const Value.absent(),
    required DateTime lastWatchedAt,
    this.completed = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : episodeId = Value(episodeId),
        lastWatchedAt = Value(lastWatchedAt);
  static Insertable<ProgressLocalData> custom({
    Expression<String>? episodeId,
    Expression<int>? progressSeconds,
    Expression<DateTime>? lastWatchedAt,
    Expression<bool>? completed,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (episodeId != null) 'episode_id': episodeId,
      if (progressSeconds != null) 'progress_seconds': progressSeconds,
      if (lastWatchedAt != null) 'last_watched_at': lastWatchedAt,
      if (completed != null) 'completed': completed,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgressLocalCompanion copyWith(
      {Value<String>? episodeId,
      Value<int>? progressSeconds,
      Value<DateTime>? lastWatchedAt,
      Value<bool>? completed,
      Value<bool>? synced,
      Value<int>? rowid}) {
    return ProgressLocalCompanion(
      episodeId: episodeId ?? this.episodeId,
      progressSeconds: progressSeconds ?? this.progressSeconds,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      completed: completed ?? this.completed,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (episodeId.present) {
      map['episode_id'] = Variable<String>(episodeId.value);
    }
    if (progressSeconds.present) {
      map['progress_seconds'] = Variable<int>(progressSeconds.value);
    }
    if (lastWatchedAt.present) {
      map['last_watched_at'] = Variable<DateTime>(lastWatchedAt.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgressLocalCompanion(')
          ..write('episodeId: $episodeId, ')
          ..write('progressSeconds: $progressSeconds, ')
          ..write('lastWatchedAt: $lastWatchedAt, ')
          ..write('completed: $completed, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadsTable extends Downloads
    with TableInfo<$DownloadsTable, Download> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _episodeIdMeta =
      const VerificationMeta('episodeId');
  @override
  late final GeneratedColumn<String> episodeId = GeneratedColumn<String>(
      'episode_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
      'task_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
      'state', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _progressMeta =
      const VerificationMeta('progress');
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
      'progress', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _bytesDownloadedMeta =
      const VerificationMeta('bytesDownloaded');
  @override
  late final GeneratedColumn<int> bytesDownloaded = GeneratedColumn<int>(
      'bytes_downloaded', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalBytesMeta =
      const VerificationMeta('totalBytes');
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
      'total_bytes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        episodeId,
        taskId,
        state,
        progress,
        bytesDownloaded,
        totalBytes,
        localPath
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(Insertable<Download> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('episode_id')) {
      context.handle(_episodeIdMeta,
          episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta));
    } else if (isInserting) {
      context.missing(_episodeIdMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta,
          taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(_progressMeta,
          progress.isAcceptableOrUnknown(data['progress']!, _progressMeta));
    }
    if (data.containsKey('bytes_downloaded')) {
      context.handle(
          _bytesDownloadedMeta,
          bytesDownloaded.isAcceptableOrUnknown(
              data['bytes_downloaded']!, _bytesDownloadedMeta));
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
          _totalBytesMeta,
          totalBytes.isAcceptableOrUnknown(
              data['total_bytes']!, _totalBytesMeta));
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {episodeId};
  @override
  Download map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Download(
      episodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}episode_id'])!,
      taskId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_id'])!,
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state'])!,
      progress: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}progress'])!,
      bytesDownloaded: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bytes_downloaded'])!,
      totalBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_bytes']),
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path']),
    );
  }

  @override
  $DownloadsTable createAlias(String alias) {
    return $DownloadsTable(attachedDatabase, alias);
  }
}

class Download extends DataClass implements Insertable<Download> {
  final String episodeId;
  final String taskId;
  final String state;
  final double progress;
  final int bytesDownloaded;
  final int? totalBytes;
  final String? localPath;
  const Download(
      {required this.episodeId,
      required this.taskId,
      required this.state,
      required this.progress,
      required this.bytesDownloaded,
      this.totalBytes,
      this.localPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['episode_id'] = Variable<String>(episodeId);
    map['task_id'] = Variable<String>(taskId);
    map['state'] = Variable<String>(state);
    map['progress'] = Variable<double>(progress);
    map['bytes_downloaded'] = Variable<int>(bytesDownloaded);
    if (!nullToAbsent || totalBytes != null) {
      map['total_bytes'] = Variable<int>(totalBytes);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      episodeId: Value(episodeId),
      taskId: Value(taskId),
      state: Value(state),
      progress: Value(progress),
      bytesDownloaded: Value(bytesDownloaded),
      totalBytes: totalBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalBytes),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
    );
  }

  factory Download.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Download(
      episodeId: serializer.fromJson<String>(json['episodeId']),
      taskId: serializer.fromJson<String>(json['taskId']),
      state: serializer.fromJson<String>(json['state']),
      progress: serializer.fromJson<double>(json['progress']),
      bytesDownloaded: serializer.fromJson<int>(json['bytesDownloaded']),
      totalBytes: serializer.fromJson<int?>(json['totalBytes']),
      localPath: serializer.fromJson<String?>(json['localPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'episodeId': serializer.toJson<String>(episodeId),
      'taskId': serializer.toJson<String>(taskId),
      'state': serializer.toJson<String>(state),
      'progress': serializer.toJson<double>(progress),
      'bytesDownloaded': serializer.toJson<int>(bytesDownloaded),
      'totalBytes': serializer.toJson<int?>(totalBytes),
      'localPath': serializer.toJson<String?>(localPath),
    };
  }

  Download copyWith(
          {String? episodeId,
          String? taskId,
          String? state,
          double? progress,
          int? bytesDownloaded,
          Value<int?> totalBytes = const Value.absent(),
          Value<String?> localPath = const Value.absent()}) =>
      Download(
        episodeId: episodeId ?? this.episodeId,
        taskId: taskId ?? this.taskId,
        state: state ?? this.state,
        progress: progress ?? this.progress,
        bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
        totalBytes: totalBytes.present ? totalBytes.value : this.totalBytes,
        localPath: localPath.present ? localPath.value : this.localPath,
      );
  Download copyWithCompanion(DownloadsCompanion data) {
    return Download(
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      state: data.state.present ? data.state.value : this.state,
      progress: data.progress.present ? data.progress.value : this.progress,
      bytesDownloaded: data.bytesDownloaded.present
          ? data.bytesDownloaded.value
          : this.bytesDownloaded,
      totalBytes:
          data.totalBytes.present ? data.totalBytes.value : this.totalBytes,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Download(')
          ..write('episodeId: $episodeId, ')
          ..write('taskId: $taskId, ')
          ..write('state: $state, ')
          ..write('progress: $progress, ')
          ..write('bytesDownloaded: $bytesDownloaded, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('localPath: $localPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(episodeId, taskId, state, progress,
      bytesDownloaded, totalBytes, localPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Download &&
          other.episodeId == this.episodeId &&
          other.taskId == this.taskId &&
          other.state == this.state &&
          other.progress == this.progress &&
          other.bytesDownloaded == this.bytesDownloaded &&
          other.totalBytes == this.totalBytes &&
          other.localPath == this.localPath);
}

class DownloadsCompanion extends UpdateCompanion<Download> {
  final Value<String> episodeId;
  final Value<String> taskId;
  final Value<String> state;
  final Value<double> progress;
  final Value<int> bytesDownloaded;
  final Value<int?> totalBytes;
  final Value<String?> localPath;
  final Value<int> rowid;
  const DownloadsCompanion({
    this.episodeId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.state = const Value.absent(),
    this.progress = const Value.absent(),
    this.bytesDownloaded = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.localPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadsCompanion.insert({
    required String episodeId,
    required String taskId,
    required String state,
    this.progress = const Value.absent(),
    this.bytesDownloaded = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.localPath = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : episodeId = Value(episodeId),
        taskId = Value(taskId),
        state = Value(state);
  static Insertable<Download> custom({
    Expression<String>? episodeId,
    Expression<String>? taskId,
    Expression<String>? state,
    Expression<double>? progress,
    Expression<int>? bytesDownloaded,
    Expression<int>? totalBytes,
    Expression<String>? localPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (episodeId != null) 'episode_id': episodeId,
      if (taskId != null) 'task_id': taskId,
      if (state != null) 'state': state,
      if (progress != null) 'progress': progress,
      if (bytesDownloaded != null) 'bytes_downloaded': bytesDownloaded,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (localPath != null) 'local_path': localPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadsCompanion copyWith(
      {Value<String>? episodeId,
      Value<String>? taskId,
      Value<String>? state,
      Value<double>? progress,
      Value<int>? bytesDownloaded,
      Value<int?>? totalBytes,
      Value<String?>? localPath,
      Value<int>? rowid}) {
    return DownloadsCompanion(
      episodeId: episodeId ?? this.episodeId,
      taskId: taskId ?? this.taskId,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytes: totalBytes ?? this.totalBytes,
      localPath: localPath ?? this.localPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (episodeId.present) {
      map['episode_id'] = Variable<String>(episodeId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (bytesDownloaded.present) {
      map['bytes_downloaded'] = Variable<int>(bytesDownloaded.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsCompanion(')
          ..write('episodeId: $episodeId, ')
          ..write('taskId: $taskId, ')
          ..write('state: $state, ')
          ..write('progress: $progress, ')
          ..write('bytesDownloaded: $bytesDownloaded, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('localPath: $localPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedEpisodesTable cachedEpisodes = $CachedEpisodesTable(this);
  late final $ProgressLocalTable progressLocal = $ProgressLocalTable(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [cachedEpisodes, progressLocal, downloads];
}

typedef $$CachedEpisodesTableCreateCompanionBuilder = CachedEpisodesCompanion
    Function({
  required String id,
  required String seriesId,
  required String title,
  required String description,
  required String videoUrl,
  required String thumbnailUrl,
  required int durationSec,
  required int episodeNumber,
  Value<String> seriesTitle,
  Value<String> seriesDescription,
  Value<String> seriesThumb,
  Value<int> rowid,
});
typedef $$CachedEpisodesTableUpdateCompanionBuilder = CachedEpisodesCompanion
    Function({
  Value<String> id,
  Value<String> seriesId,
  Value<String> title,
  Value<String> description,
  Value<String> videoUrl,
  Value<String> thumbnailUrl,
  Value<int> durationSec,
  Value<int> episodeNumber,
  Value<String> seriesTitle,
  Value<String> seriesDescription,
  Value<String> seriesThumb,
  Value<int> rowid,
});

class $$CachedEpisodesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedEpisodesTable> {
  $$CachedEpisodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get seriesId => $composableBuilder(
      column: $table.seriesId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get videoUrl => $composableBuilder(
      column: $table.videoUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
      column: $table.thumbnailUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSec => $composableBuilder(
      column: $table.durationSec, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get seriesTitle => $composableBuilder(
      column: $table.seriesTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get seriesDescription => $composableBuilder(
      column: $table.seriesDescription,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get seriesThumb => $composableBuilder(
      column: $table.seriesThumb, builder: (column) => ColumnFilters(column));
}

class $$CachedEpisodesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedEpisodesTable> {
  $$CachedEpisodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get seriesId => $composableBuilder(
      column: $table.seriesId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get videoUrl => $composableBuilder(
      column: $table.videoUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
      column: $table.thumbnailUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSec => $composableBuilder(
      column: $table.durationSec, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get seriesTitle => $composableBuilder(
      column: $table.seriesTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get seriesDescription => $composableBuilder(
      column: $table.seriesDescription,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get seriesThumb => $composableBuilder(
      column: $table.seriesThumb, builder: (column) => ColumnOrderings(column));
}

class $$CachedEpisodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedEpisodesTable> {
  $$CachedEpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get videoUrl =>
      $composableBuilder(column: $table.videoUrl, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
      column: $table.thumbnailUrl, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
      column: $table.durationSec, builder: (column) => column);

  GeneratedColumn<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber, builder: (column) => column);

  GeneratedColumn<String> get seriesTitle => $composableBuilder(
      column: $table.seriesTitle, builder: (column) => column);

  GeneratedColumn<String> get seriesDescription => $composableBuilder(
      column: $table.seriesDescription, builder: (column) => column);

  GeneratedColumn<String> get seriesThumb => $composableBuilder(
      column: $table.seriesThumb, builder: (column) => column);
}

class $$CachedEpisodesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedEpisodesTable,
    CachedEpisode,
    $$CachedEpisodesTableFilterComposer,
    $$CachedEpisodesTableOrderingComposer,
    $$CachedEpisodesTableAnnotationComposer,
    $$CachedEpisodesTableCreateCompanionBuilder,
    $$CachedEpisodesTableUpdateCompanionBuilder,
    (
      CachedEpisode,
      BaseReferences<_$AppDatabase, $CachedEpisodesTable, CachedEpisode>
    ),
    CachedEpisode,
    PrefetchHooks Function()> {
  $$CachedEpisodesTableTableManager(
      _$AppDatabase db, $CachedEpisodesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedEpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedEpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedEpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> seriesId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> videoUrl = const Value.absent(),
            Value<String> thumbnailUrl = const Value.absent(),
            Value<int> durationSec = const Value.absent(),
            Value<int> episodeNumber = const Value.absent(),
            Value<String> seriesTitle = const Value.absent(),
            Value<String> seriesDescription = const Value.absent(),
            Value<String> seriesThumb = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedEpisodesCompanion(
            id: id,
            seriesId: seriesId,
            title: title,
            description: description,
            videoUrl: videoUrl,
            thumbnailUrl: thumbnailUrl,
            durationSec: durationSec,
            episodeNumber: episodeNumber,
            seriesTitle: seriesTitle,
            seriesDescription: seriesDescription,
            seriesThumb: seriesThumb,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String seriesId,
            required String title,
            required String description,
            required String videoUrl,
            required String thumbnailUrl,
            required int durationSec,
            required int episodeNumber,
            Value<String> seriesTitle = const Value.absent(),
            Value<String> seriesDescription = const Value.absent(),
            Value<String> seriesThumb = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedEpisodesCompanion.insert(
            id: id,
            seriesId: seriesId,
            title: title,
            description: description,
            videoUrl: videoUrl,
            thumbnailUrl: thumbnailUrl,
            durationSec: durationSec,
            episodeNumber: episodeNumber,
            seriesTitle: seriesTitle,
            seriesDescription: seriesDescription,
            seriesThumb: seriesThumb,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedEpisodesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedEpisodesTable,
    CachedEpisode,
    $$CachedEpisodesTableFilterComposer,
    $$CachedEpisodesTableOrderingComposer,
    $$CachedEpisodesTableAnnotationComposer,
    $$CachedEpisodesTableCreateCompanionBuilder,
    $$CachedEpisodesTableUpdateCompanionBuilder,
    (
      CachedEpisode,
      BaseReferences<_$AppDatabase, $CachedEpisodesTable, CachedEpisode>
    ),
    CachedEpisode,
    PrefetchHooks Function()>;
typedef $$ProgressLocalTableCreateCompanionBuilder = ProgressLocalCompanion
    Function({
  required String episodeId,
  Value<int> progressSeconds,
  required DateTime lastWatchedAt,
  Value<bool> completed,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$ProgressLocalTableUpdateCompanionBuilder = ProgressLocalCompanion
    Function({
  Value<String> episodeId,
  Value<int> progressSeconds,
  Value<DateTime> lastWatchedAt,
  Value<bool> completed,
  Value<bool> synced,
  Value<int> rowid,
});

class $$ProgressLocalTableFilterComposer
    extends Composer<_$AppDatabase, $ProgressLocalTable> {
  $$ProgressLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get episodeId => $composableBuilder(
      column: $table.episodeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get progressSeconds => $composableBuilder(
      column: $table.progressSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastWatchedAt => $composableBuilder(
      column: $table.lastWatchedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$ProgressLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgressLocalTable> {
  $$ProgressLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get episodeId => $composableBuilder(
      column: $table.episodeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get progressSeconds => $composableBuilder(
      column: $table.progressSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastWatchedAt => $composableBuilder(
      column: $table.lastWatchedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$ProgressLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgressLocalTable> {
  $$ProgressLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get episodeId =>
      $composableBuilder(column: $table.episodeId, builder: (column) => column);

  GeneratedColumn<int> get progressSeconds => $composableBuilder(
      column: $table.progressSeconds, builder: (column) => column);

  GeneratedColumn<DateTime> get lastWatchedAt => $composableBuilder(
      column: $table.lastWatchedAt, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$ProgressLocalTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProgressLocalTable,
    ProgressLocalData,
    $$ProgressLocalTableFilterComposer,
    $$ProgressLocalTableOrderingComposer,
    $$ProgressLocalTableAnnotationComposer,
    $$ProgressLocalTableCreateCompanionBuilder,
    $$ProgressLocalTableUpdateCompanionBuilder,
    (
      ProgressLocalData,
      BaseReferences<_$AppDatabase, $ProgressLocalTable, ProgressLocalData>
    ),
    ProgressLocalData,
    PrefetchHooks Function()> {
  $$ProgressLocalTableTableManager(_$AppDatabase db, $ProgressLocalTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgressLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgressLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgressLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> episodeId = const Value.absent(),
            Value<int> progressSeconds = const Value.absent(),
            Value<DateTime> lastWatchedAt = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProgressLocalCompanion(
            episodeId: episodeId,
            progressSeconds: progressSeconds,
            lastWatchedAt: lastWatchedAt,
            completed: completed,
            synced: synced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String episodeId,
            Value<int> progressSeconds = const Value.absent(),
            required DateTime lastWatchedAt,
            Value<bool> completed = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProgressLocalCompanion.insert(
            episodeId: episodeId,
            progressSeconds: progressSeconds,
            lastWatchedAt: lastWatchedAt,
            completed: completed,
            synced: synced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProgressLocalTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProgressLocalTable,
    ProgressLocalData,
    $$ProgressLocalTableFilterComposer,
    $$ProgressLocalTableOrderingComposer,
    $$ProgressLocalTableAnnotationComposer,
    $$ProgressLocalTableCreateCompanionBuilder,
    $$ProgressLocalTableUpdateCompanionBuilder,
    (
      ProgressLocalData,
      BaseReferences<_$AppDatabase, $ProgressLocalTable, ProgressLocalData>
    ),
    ProgressLocalData,
    PrefetchHooks Function()>;
typedef $$DownloadsTableCreateCompanionBuilder = DownloadsCompanion Function({
  required String episodeId,
  required String taskId,
  required String state,
  Value<double> progress,
  Value<int> bytesDownloaded,
  Value<int?> totalBytes,
  Value<String?> localPath,
  Value<int> rowid,
});
typedef $$DownloadsTableUpdateCompanionBuilder = DownloadsCompanion Function({
  Value<String> episodeId,
  Value<String> taskId,
  Value<String> state,
  Value<double> progress,
  Value<int> bytesDownloaded,
  Value<int?> totalBytes,
  Value<String?> localPath,
  Value<int> rowid,
});

class $$DownloadsTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get episodeId => $composableBuilder(
      column: $table.episodeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taskId => $composableBuilder(
      column: $table.taskId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bytesDownloaded => $composableBuilder(
      column: $table.bytesDownloaded,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));
}

class $$DownloadsTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get episodeId => $composableBuilder(
      column: $table.episodeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taskId => $composableBuilder(
      column: $table.taskId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bytesDownloaded => $composableBuilder(
      column: $table.bytesDownloaded,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));
}

class $$DownloadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get episodeId =>
      $composableBuilder(column: $table.episodeId, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get bytesDownloaded => $composableBuilder(
      column: $table.bytesDownloaded, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);
}

class $$DownloadsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DownloadsTable,
    Download,
    $$DownloadsTableFilterComposer,
    $$DownloadsTableOrderingComposer,
    $$DownloadsTableAnnotationComposer,
    $$DownloadsTableCreateCompanionBuilder,
    $$DownloadsTableUpdateCompanionBuilder,
    (Download, BaseReferences<_$AppDatabase, $DownloadsTable, Download>),
    Download,
    PrefetchHooks Function()> {
  $$DownloadsTableTableManager(_$AppDatabase db, $DownloadsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> episodeId = const Value.absent(),
            Value<String> taskId = const Value.absent(),
            Value<String> state = const Value.absent(),
            Value<double> progress = const Value.absent(),
            Value<int> bytesDownloaded = const Value.absent(),
            Value<int?> totalBytes = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DownloadsCompanion(
            episodeId: episodeId,
            taskId: taskId,
            state: state,
            progress: progress,
            bytesDownloaded: bytesDownloaded,
            totalBytes: totalBytes,
            localPath: localPath,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String episodeId,
            required String taskId,
            required String state,
            Value<double> progress = const Value.absent(),
            Value<int> bytesDownloaded = const Value.absent(),
            Value<int?> totalBytes = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DownloadsCompanion.insert(
            episodeId: episodeId,
            taskId: taskId,
            state: state,
            progress: progress,
            bytesDownloaded: bytesDownloaded,
            totalBytes: totalBytes,
            localPath: localPath,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DownloadsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DownloadsTable,
    Download,
    $$DownloadsTableFilterComposer,
    $$DownloadsTableOrderingComposer,
    $$DownloadsTableAnnotationComposer,
    $$DownloadsTableCreateCompanionBuilder,
    $$DownloadsTableUpdateCompanionBuilder,
    (Download, BaseReferences<_$AppDatabase, $DownloadsTable, Download>),
    Download,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedEpisodesTableTableManager get cachedEpisodes =>
      $$CachedEpisodesTableTableManager(_db, _db.cachedEpisodes);
  $$ProgressLocalTableTableManager get progressLocal =>
      $$ProgressLocalTableTableManager(_db, _db.progressLocal);
  $$DownloadsTableTableManager get downloads =>
      $$DownloadsTableTableManager(_db, _db.downloads);
}
