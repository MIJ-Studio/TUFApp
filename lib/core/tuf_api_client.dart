import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'frame_log.dart';
import 'json.dart';
import 'l10n.dart';
import 'models/browse.dart';
import 'models/difficulty.dart';
import 'models/facet.dart';
import 'models/level.dart';
import 'models/pack.dart';
import 'models/pass.dart';
import 'models/profile.dart';
import 'models/search_models.dart';

class TufApiException implements Exception {
  const TufApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Client for the TUF API (https://api.tuforums.com).
class TufApiClient {
  TufApiClient({http.Client? client}) : _client = client ?? http.Client();

  static final Uri baseUri = Uri.parse('https://api.tuforums.com/');
  static const _headers = {'User-Agent': 'TUFApp/0.2'};

  /// Requests fail after this long without a response, so a stalled connection never leaves a page waiting forever.
  static const requestTimeout = Duration(seconds: 20);

  /// Responses at least this big are decoded on a background isolate. On the UI thread a 1 MB pack takes
  /// about 40 ms, long enough to drop frames while scrolling.
  static const _backgroundDecodeBytes = 64 * 1024;

  final http.Client _client;

  Future<PagedResult<Level>> searchLevels(LevelSearchQuery query) async {
    final json = await _getJson('v2/database/levels', query.toQueryParameters());
    if (json is! Map<String, dynamic>) throw TufApiException(l10n.unexpectedSearchResponse);
    return PagedResult.fromJson(json, Level.fromJson);
  }

  Future<Level> getLevel(int id) async {
    final json = await _getJson('v2/database/levels/$id');
    final level = json is Map<String, dynamic> ? json['level'] : null;
    if (level is! Map<String, dynamic>) {
      throw TufApiException(l10n.noLevelField(id));
    }
    return Level.fromJson(level);
  }

  Future<List<Difficulty>> getDifficulties() async {
    final json = await _getJson('v2/database/difficulties');
    if (json is! List) throw TufApiException(l10n.unexpectedDifficultyListResponse);
    return json.whereType<Map<String, dynamic>>().map(Difficulty.fromJson).toList();
  }

  /// Level tags, with their groups.
  Future<List<FacetItem>> getTags() => _getFacetItems('v2/database/difficulties/tags', l10n.listTag);

  /// Curation types (C3, V2, Epic, ...).
  Future<List<FacetItem>> getCurationTypes() => _getFacetItems('v2/admin/curations/types', l10n.listCurationType);

  Future<List<FacetItem>> _getFacetItems(String path, String label) async {
    final json = await _getJson(path);
    if (json is! List) throw TufApiException(l10n.unexpectedListResponse(label));
    return json.whereType<Map<String, dynamic>>().map(FacetItem.fromJson).toList();
  }

  /// All passes of a level (its leaderboard).
  Future<List<LevelPass>> getLevelPasses(int levelId) async {
    final json = await _getJson('v2/database/passes/level/$levelId');
    if (json is! List) {
      throw TufApiException(l10n.unexpectedPassResponseFor(levelId));
    }
    return json.whereType<Map<String, dynamic>>().map(LevelPass.fromJson).toList();
  }

  /// Details of one pass, including its ranked score contribution and rank.
  Future<PassDetail> getPass(int id) async {
    final json = await _getJson('v2/database/passes/$id');
    if (json is! Map<String, dynamic>) {
      throw TufApiException(l10n.unexpectedResponseForPass(id));
    }
    return PassDetail.fromJson(json);
  }

  /// The player behind a pass (scores, rank, ...).
  Future<PlayerProfile> getPlayer(int id) async {
    final json = await _getJson('v2/database/players/$id');
    if (json is! Map<String, dynamic>) {
      throw TufApiException(l10n.unexpectedResponseForPlayer(id));
    }
    return PlayerProfile.fromJson(json);
  }

  /// Searches all passes (the website's pass list).
  Future<({List<PlayerPassEntry> passes, int total, int? seed})> searchPasses(ClearSearchQuery query) async {
    final json = await _getJson('v2/database/passes', query.toQueryParameters());
    if (json is! Map<String, dynamic>) {
      throw TufApiException(l10n.unexpectedPassListResponse);
    }
    return (
      passes: asObjectList(json['results']).map(PlayerPassEntry.fromJson).toList(),
      total: asInt(json['count']),
      seed: asIntOrNull(json['seed']),
    );
  }

  /// Levels by id, in the given order (missing ones are left out). Same request as the website's featured blocks.
  Future<List<Level>> getLevelsByIds(List<int> ids) async {
    final json = await _getJson('v2/database/levels', _idQuery(ids));
    if (json is! Map<String, dynamic>) throw TufApiException(l10n.unexpectedSearchResponse);
    return _inOrder(asObjectList(json['results']).map(Level.fromJson), ids, (level) => level.id);
  }

  /// Passes by id, in the given order (missing ones are left out).
  Future<List<PlayerPassEntry>> getPassesByIds(List<int> ids) async {
    final json = await _getJson('v2/database/passes', _idQuery(ids));
    if (json is! Map<String, dynamic>) {
      throw TufApiException(l10n.unexpectedPassListResponse);
    }
    return _inOrder(asObjectList(json['results']).map(PlayerPassEntry.fromJson), ids, (entry) => entry.pass.id);
  }

  /// The search language joins alternatives with '|'.
  static Map<String, Object> _idQuery(List<int> ids) => {
    'query': ids.map((id) => 'id:$id').join(' | '),
    'limit': '${ids.length}',
    'offset': '0',
    'deletedFilter': 'hide',
  };

  static List<T> _inOrder<T>(Iterable<T> rows, List<int> ids, int Function(T row) idOf) {
    final byId = {for (final row in rows) idOf(row): row};
    return [for (final id in ids) ?byId[id]];
  }

  /// Finds a pass by number ("#id" in the search box). Empty if not found.
  Future<List<PlayerPassEntry>> findPassesById(int id) async {
    final json = await _getJson('v2/database/passes/byId/$id');
    if (json is! Map<String, dynamic>) return const [];
    return asObjectList(json['results']).map(PlayerPassEntry.fromJson).toList();
  }

  /// Player leaderboard. Banned players are excluded, like on the website.
  Future<({List<LeaderboardPlayer> players, int total})> getLeaderboard({
    String query = '',
    LeaderboardSort sort = LeaderboardSort.rankedScore,
    bool descending = true,
    int offset = 0,
    int limit = 30,
  }) async {
    final json = await _getJson('v3/players/leaderboard', {
      'query': query.trim(),
      'sortBy': sort.name,
      'order': descending ? 'desc' : 'asc',
      'offset': '$offset',
      'limit': '$limit',
      'flagField': 'isBanned',
      'flagMode': 'hide',
    });
    if (json is! Map<String, dynamic>) {
      throw TufApiException(l10n.unexpectedLeaderboardResponse);
    }
    return (
      players: asObjectList(json['results']).map(LeaderboardPlayer.fromJson).toList(),
      total: asInt(json['count']),
    );
  }

  /// Creator list (the website's creators page). [facetQuery] filters by curation type ([buildFacetQuery]).
  Future<({List<CreatorListEntry> creators, int total})> getCreators({
    String query = '',
    CreatorSort sort = CreatorSort.chartsTotal,
    bool descending = true,
    CreatorVerification? verification,
    String? facetQuery,
    int offset = 0,
    int limit = 30,
  }) async {
    final json = await _getJson('v3/creators/leaderboard', {
      'query': query.trim(),
      'sortBy': sort.name,
      'order': descending ? 'desc' : 'asc',
      'offset': '$offset',
      'limit': '$limit',
      if (verification != null) 'filters': jsonEncode({'verificationStatus': verification.name}),
      'facetQuery': ?facetQuery,
    });
    if (json is! Map<String, dynamic>) {
      throw TufApiException(l10n.unexpectedCreatorListResponse);
    }
    return (
      creators: asObjectList(json['results']).map(CreatorListEntry.fromJson).toList(),
      total: asInt(json['count']),
    );
  }

  /// Player page (scores, stats, tournament placements, module layout).
  Future<PlayerProfileDetail> getPlayerProfile(int id) async {
    final json = await _getJson('v3/players/$id/profile');
    if (json is! Map<String, dynamic> || json['id'] == null) {
      throw TufApiException(l10n.playerNotFound(id), 404);
    }
    return PlayerProfileDetail.fromJson(json);
  }

  /// A player's passes. Sorting and search happen on the server.
  Future<({List<PlayerPassEntry> passes, int total})> getPlayerPasses(
    int id, {
    int offset = 0,
    int limit = 50,
    PlayerPassSort sort = PlayerPassSort.score,
    bool descending = true,
    String query = '',
    bool bestPerLevel = false,
  }) async {
    final json = await _getJson('v3/players/$id/passes', {
      'limit': '$limit',
      'offset': '$offset',
      'sortBy': sort.name,
      'order': descending ? 'DESC' : 'ASC',
      if (query.trim().isNotEmpty) 'query': query.trim(),
      if (bestPerLevel) 'bestPerLevel': 'true',
    });
    if (json is! Map<String, dynamic>) {
      throw TufApiException(l10n.unexpectedPassResponseForPlayer(id));
    }
    return (passes: asObjectList(json['passes']).map(PlayerPassEntry.fromJson).toList(), total: asInt(json['total']));
  }

  /// Rank history. Without [from]/[to], the whole period.
  Future<List<RankHistoryPoint>> getRankHistory(int id, {DateTime? from, DateTime? to}) async {
    String day(DateTime date) => date.toUtc().toIso8601String().substring(0, 10);
    final json = await _getJson('v3/players/$id/rank-history', {
      if (from != null) 'from': day(from),
      if (to != null) 'to': day(to),
    });
    if (json is! Map<String, dynamic>) {
      throw TufApiException(l10n.unexpectedRankHistoryResponse(id));
    }
    return asObjectList(json['series']).map(RankHistoryPoint.fromJson).toList();
  }

  Future<CreatorProfileDetail> getCreatorProfile(int id) async {
    final json = await _getJson('v3/creators/$id/profile');
    if (json is! Map<String, dynamic>) {
      throw TufApiException(l10n.creatorNotFound(id), 404);
    }
    return CreatorProfileDetail.fromJson(json);
  }

  /// Public level packs; the same request as the website's packs page.
  Future<({List<LevelPack> packs, int total})> searchPacks({
    String query = '',
    PackSort sort = PackSort.recent,
    bool descending = true,
    int offset = 0,
    int limit = 30,
  }) async {
    final json = await _getJson('v2/database/levels/packs', {
      'offset': '$offset',
      'limit': '$limit',
      'sort': sort.apiValue,
      'order': descending ? 'DESC' : 'ASC',
      if (query.trim().isNotEmpty) 'query': query.trim(),
    });
    if (json is! Map<String, dynamic>) {
      throw TufApiException(l10n.unexpectedPackListResponse);
    }
    return (packs: asObjectList(json['packs']).map(LevelPack.fromJson).toList(), total: asInt(json['total']));
  }

  /// A single pack with its folder structure.
  Future<LevelPackDetail> getPack(String id, {Level Function(Level level)? resolveLevel}) async {
    // Big packs have hundreds of levels, so they are parsed along with the decoding, off the UI thread.
    final detail = await _get('v2/database/levels/packs/${Uri.encodeComponent(id)}', {'tree': 'true'}, _parsePack);
    if (detail == null) throw TufApiException(l10n.unexpectedResponseForPack(id));
    return resolveLevel == null ? detail : detail.mapLevels(resolveLevel);
  }

  static LevelPackDetail? _parsePack(Object? json) =>
      json is Map<String, dynamic> ? LevelPackDetail.fromJson(json) : null;

  /// Contents of a level's zip, or null if the level isn't on the CDN.
  Future<CdnLevelMetadata?> getLevelCdnMetadata(int id) async {
    final json = await _getJson('v2/database/levels/$id/cdnData');
    final metadata = json is Map<String, dynamic> ? json['metadata'] : null;
    return metadata is Map<String, dynamic> ? CdnLevelMetadata.fromJson(metadata) : null;
  }

  /// Thumbnail URL of a video link (YouTube, Bilibili, ...). Cached by the
  /// server; Bilibili comes back as a TUF image proxy URL.
  Future<String?> getVideoThumbnailUrl(String videoLink) async {
    final json = await _getJson('v2/media/video-details/${Uri.encodeComponent(videoLink)}');
    return json is Map<String, dynamic> ? asStringOrNull(json['image']) : null;
  }

  /// A response with headers only; the caller streams the body.
  Future<http.StreamedResponse> openDownload(String url) async {
    final request = http.Request('GET', Uri.parse(url))..headers.addAll(_headers);

    final http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(requestTimeout);
    } on TimeoutException {
      throw TufApiException(l10n.serverNotResponding(url));
    } on http.ClientException catch (e) {
      throw TufApiException(l10n.downloadRequestFailed(url, e.message));
    } on IOException catch (e) {
      throw TufApiException(l10n.downloadRequestFailed(url, e));
    }

    if (response.statusCode >= 400) {
      await response.stream.drain<void>();
      throw TufApiException('${response.statusCode} ${response.reasonPhrase ?? ''}: $url', response.statusCode);
    }
    return response;
  }

  /// [query] values are strings, or lists of strings sent as repeated keys.
  Future<Object?> _getJson(String path, [Map<String, Object>? query]) => _get(path, query, _identity);

  static Object? _identity(Object? json) => json;

  /// Fetches JSON and turns it into a result with [parse], off the UI thread for big responses.
  /// [parse] runs on another isolate then, so it must be a static or top-level function that doesn't
  /// depend on the UI language.
  Future<T> _get<T>(String path, Map<String, Object>? query, T Function(Object? json) parse) async {
    var uri = baseUri.resolve(path);
    if (query != null) uri = uri.replace(queryParameters: query);

    final http.Response response;
    try {
      response = await _client.get(uri, headers: _headers).timeout(requestTimeout);
    } on TimeoutException {
      throw TufApiException(l10n.serverNotResponding(path));
    } on http.ClientException catch (e) {
      throw TufApiException(l10n.requestFailed(path, e.message));
    } on IOException catch (e) {
      throw TufApiException(l10n.requestFailed(path, e));
    }

    if (response.statusCode >= 400) {
      throw TufApiException('${response.statusCode}: $path ${response.body}'.trim(), response.statusCode);
    }

    final bytes = response.bodyBytes;
    try {
      final watch = Stopwatch()..start();
      final background = bytes.length >= _backgroundDecodeBytes;
      final result = background ? await _decodeInBackground(bytes, parse) : _decode(bytes, parse);
      FrameLog.note(
        background ? 'decode (background)' : 'decode',
        watch.elapsed,
        detail: '$path, ${bytes.length ~/ 1024} KB',
      );
      return result;
    } on FormatException {
      throw TufApiException(l10n.couldNotReadTheResponse(path));
    }
  }

  static T _decode<T>(Uint8List bytes, T Function(Object? json) parse) => parse(jsonDecode(utf8.decode(bytes)));

  // Static, so the closure sent to the isolate can't capture this client.
  static Future<T> _decodeInBackground<T>(Uint8List bytes, T Function(Object? json) parse) =>
      Isolate.run(() => _decode(bytes, parse));

  void close() => _client.close();
}
