import '../json.dart';
import 'difficulty.dart';

/// A TUF level. The API returns many more fields; only the needed ones are read.
class Level {
  const Level({
    required this.id,
    required this.song,
    required this.artist,
    this.creator,
    this.team,
    this.diffId = 0,
    this.difficulty,
    this.baseScore,
    this.dlLink,
    this.fileId,
    this.legacyDllink,
    this.workshopLink,
    this.videoLink,
    this.bpm,
    this.tilecount,
    this.levelLengthInMs,
    this.clears = 0,
    this.uniqueClears = 0,
    this.likes = 0,
    this.downloadCount = 0,
    this.isDeleted = false,
    this.tags = const [],
    this.credits = const [],
    this.curationTypeIds = const [],
    this.ratedDifficultyId,
    this.aliases = const [],
    this.createdAt,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    final difficulty = json['difficulty'];
    return Level(
      id: asInt(json['id']),
      song: json['song'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      creator: asStringOrNull(json['creator']),
      // Detail responses leave team empty and only send teamObject.
      team:
          asStringOrNull(json['team']) ??
          switch (json['teamObject']) {
            final Map<String, dynamic> team => asStringOrNull(team['name']),
            _ => null,
          },
      diffId: asInt(json['diffId']),
      difficulty: difficulty is Map<String, dynamic> ? Difficulty.fromJson(difficulty) : null,
      baseScore: asIntOrNull(json['baseScore']),
      dlLink: asStringOrNull(json['dlLink']),
      fileId: asStringOrNull(json['fileId']),
      legacyDllink: asStringOrNull(json['legacyDllink']),
      workshopLink: asStringOrNull(json['workshopLink']),
      videoLink: asStringOrNull(json['videoLink']),
      bpm: asDoubleOrNull(json['bpm']),
      tilecount: asIntOrNull(json['tilecount']),
      levelLengthInMs: asDoubleOrNull(json['levelLengthInMs']),
      clears: asInt(json['clears']),
      uniqueClears: asInt(json['uniqueClears']),
      likes: asInt(json['likes']),
      downloadCount: asInt(json['downloadCount']),
      isDeleted: asBool(json['isDeleted']),
      tags: asObjectList(json['tags']).map(LevelTag.fromJson).toList(),
      credits: asObjectList(json['levelCredits']).map(LevelCredit.fromJson).toList(),
      curationTypeIds: _readCurationTypeIds(json),
      aliases: asObjectList(json['aliases']).map(LevelAlias.fromJson).toList(),
      createdAt: DateTime.tryParse(asStringOrNull(json['createdAt']) ?? ''),
      ratedDifficultyId: switch (json['rating']) {
        final Map<String, dynamic> rating => asIntOrNull(rating['averageDifficultyId']),
        _ => null,
      },
    );
  }

  final int id;
  final String song;
  final String artist;

  /// Creator string from search results, joined like "charter | VFX".
  final String? creator;
  final String? team;
  final int diffId;
  final Difficulty? difficulty;

  /// Base score (PP) set for this level only, replacing the difficulty's default.
  final int? baseScore;

  /// TUF CDN download link (zip). Without it, check the Workshop or legacy links.
  final String? dlLink;

  /// CDN file ID. It changes when the level file is re-uploaded, so it is used to detect updates.
  final String? fileId;
  final String? legacyDllink;
  final String? workshopLink;
  final String? videoLink;

  final double? bpm;
  final int? tilecount;
  final double? levelLengthInMs;

  final int clears;
  final int uniqueClears;
  final int likes;

  /// Download count on the website.
  final int downloadCount;
  final bool isDeleted;

  final List<LevelTag> tags;
  final List<LevelCredit> credits;

  /// Curation type ids of this level (C2, V1, ...). Icons come from the curation catalog.
  final List<int> curationTypeIds;

  /// Average rated difficulty id. Shows roughly which PGU difficulty a Q level is.
  final int? ratedDifficultyId;

  /// Other names for the song or artist (used by search).
  final List<LevelAlias> aliases;

  /// Date the level was added to TUF.
  final DateTime? createdAt;

  /// The shape differs per response:
  /// - search results: curation.typeIds
  /// - single level: curations[].types[].id
  /// - pack contents: curations[].typeIds
  static List<int> _readCurationTypeIds(Map<String, dynamic> json) {
    final ids = <int>{};

    void addTypeIds(Object? curation) {
      if (curation is! Map<String, dynamic> || curation['typeIds'] is! List) return;
      for (final id in curation['typeIds'] as List) {
        if (asIntOrNull(id) case final value?) ids.add(value);
      }
    }

    addTypeIds(json['curation']);
    addTypeIds(json['curations']);
    for (final entry in asObjectList(json['curations'])) {
      addTypeIds(entry);
      for (final type in asObjectList(entry['types'])) {
        if (asIntOrNull(type['id']) case final value?) ids.add(value);
      }
    }

    return ids.toList();
  }

  /// Fills in difficulty and tags for levels that only came with ids (like pack responses).
  Level copyWith({Difficulty? difficulty, List<LevelTag>? tags}) => Level(
    id: id,
    song: song,
    artist: artist,
    creator: creator,
    team: team,
    diffId: diffId,
    difficulty: difficulty ?? this.difficulty,
    baseScore: baseScore,
    dlLink: dlLink,
    fileId: fileId,
    legacyDllink: legacyDllink,
    workshopLink: workshopLink,
    videoLink: videoLink,
    bpm: bpm,
    tilecount: tilecount,
    levelLengthInMs: levelLengthInMs,
    clears: clears,
    uniqueClears: uniqueClears,
    likes: likes,
    downloadCount: downloadCount,
    isDeleted: isDeleted,
    tags: tags ?? this.tags,
    credits: credits,
    curationTypeIds: curationTypeIds,
    ratedDifficultyId: ratedDifficultyId,
    aliases: aliases,
    createdAt: createdAt,
  );

  /// Base score (PP) that differs from the difficulty's default, or null.
  int? get baseScoreOverride {
    final score = baseScore;
    if (score == null || score <= 0) return null;
    return score == difficulty?.baseScore ? null : score;
  }

  /// Level length, or null if unknown.
  Duration? get length {
    final ms = levelLengthInMs;
    return ms != null && ms > 0 ? Duration(milliseconds: ms.round()) : null;
  }

  /// Creator name for display, following the website's formatCreatorDisplay:
  /// team → charter/VFX credits ("A & B", "A | B", "A & 2 more | B") → the creator string from search results.
  String? get creatorDisplay {
    if (team != null) return team;

    final charters = creditedNames('charter');
    final vfxers = creditedNames('vfxer');
    final primaryCount = charters.length + vfxers.length;

    if (primaryCount >= 3) {
      return [
        if (charters.isNotEmpty) charters.length == 1 ? charters[0] : '${charters[0]} & ${charters.length - 1} more',
        if (vfxers.isNotEmpty) vfxers.length == 1 ? vfxers[0] : '${vfxers[0]} & ${vfxers.length - 1} more',
      ].join(' | ');
    }

    if (primaryCount == 2) {
      if (charters.length == 2) return '${charters[0]} & ${charters[1]}';
      if (charters.length == 1 && vfxers.length == 1) return '${charters[0]} | ${vfxers[0]}';
    }

    if (charters.isNotEmpty) return charters.first;
    if (vfxers.isNotEmpty) return vfxers.first;
    return creator;
  }

  /// Every creator without shortening, all joined with " & " ("A & B & C"), for places with room for all names
  /// like the level file. Charters come before VFX, and someone credited for both is named once.
  /// Team first, like [creatorDisplay].
  String? get creatorFull {
    if (team != null) return team;
    final names = {...creditedNames('charter'), ...creditedNames('vfxer')};
    if (names.isNotEmpty) return names.join(' & ');
    // The creator string from search results separates charter and VFX with '|'.
    return creator?.split('|').map((name) => name.trim()).where((name) => name.isNotEmpty).toSet().join(' & ');
  }

  /// Names credited with [role] ("charter", "vfxer"), in the website's order.
  List<String> creditedNames(String role) {
    final sorted = [...credits]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted.where((c) => c.role?.toLowerCase() == role).map((c) => c.creatorName).whereType<String>().toList();
  }
}

/// Another name for a song or artist, e.g. field "artist", alias "cametek".
class LevelAlias {
  const LevelAlias({required this.field, required this.alias});

  factory LevelAlias.fromJson(Map<String, dynamic> json) =>
      LevelAlias(field: asStringOrNull(json['field']) ?? '', alias: asStringOrNull(json['alias']) ?? '');

  final String field;
  final String alias;
}

class LevelTag {
  const LevelTag({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    this.description,
    this.isCommunity = false,
    this.score,
  });

  factory LevelTag.fromJson(Map<String, dynamic> json) => LevelTag(
    id: asInt(json['id']),
    name: json['name'] as String? ?? '',
    icon: asStringOrNull(json['icon']),
    color: asStringOrNull(json['color']),
    description: asStringOrNull(json['description']),
    isCommunity: json['isCommunity'] == true,
    score: asDoubleOrNull(json['score']),
  );

  final int id;
  final String name;
  final String? icon;
  final String? color;
  final String? description;

  /// Whether players voted this tag on (the website's community tags). false for tags set by staff.
  final bool isCommunity;

  /// Confidence of a community tag (0–1). The website fills that much of a green ring around the tag.
  final double? score;

  /// Replaces name and icon info but keeps the vote info.
  LevelTag withInfo({required String name, String? icon, String? color, String? description}) => LevelTag(
    id: id,
    name: name,
    icon: icon,
    color: color,
    description: description ?? this.description,
    isCommunity: isCommunity,
    score: score,
  );
}

class LevelCredit {
  const LevelCredit({this.role, this.sortOrder = 0, this.creatorId, this.creatorName, this.creatorAliases = const []});

  factory LevelCredit.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'];
    return LevelCredit(
      role: asStringOrNull(json['role']),
      sortOrder: asInt(json['sortOrder']),
      creatorId:
          asIntOrNull(json['creatorId']) ?? (creator is Map<String, dynamic> ? asIntOrNull(creator['id']) : null),
      creatorName: creator is Map<String, dynamic> ? asStringOrNull(creator['name']) : null,
      creatorAliases: creator is Map<String, dynamic>
          ? [for (final alias in asObjectList(creator['creatorAliases'])) ?asStringOrNull(alias['name'])]
          : const [],
    );
  }

  /// e.g. "charter", "vfxer"
  final String? role;
  final int sortOrder;

  /// Used to open the creator page. May be missing in search results.
  final int? creatorId;
  final String? creatorName;

  /// Other names this person uses.
  final List<String> creatorAliases;
}
