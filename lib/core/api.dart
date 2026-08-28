import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'police_sign.dart';

class ApiException implements Exception {
  final int code;
  final String message;
  ApiException(this.code, this.message);
  @override
  String toString() => message;
}

class Api {
  Api._();
  static final Api I = Api._();

  static const String primaryBase = 'https://api-s.anixsekai.com/';
  static const String altBase = 'https://api-s2.anixart.tv/';

  static const String _baseKey = 'api_base';
  static const String _tokenKey = 'api_token';

  String _base = primaryBase;
  String? _token;

  String get base => _base;
  String? get token => _token;
  bool get isAuthorized => (_token ?? '').isNotEmpty;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _base = p.getString(_baseKey) ?? primaryBase;
    _token = p.getString(_tokenKey);
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final p = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await p.remove(_tokenKey);
    } else {
      await p.setString(_tokenKey, token);
    }
  }

  Future<void> _switchBase(String url) async {
    _base = url;
    final p = await SharedPreferences.getInstance();
    await p.setString(_baseKey, url);
  }

  Uri _uri(String path, Map<String, String> query) {
    final q = <String, String>{...query};
    if (isAuthorized) {
      q['token'] = _token!;
    } else if (path != 'config/toggles' && !path.startsWith('auth/')) {
      q['token'] = '';
    }
    return Uri.parse(_base + path).replace(queryParameters: q);
  }

  Future<dynamic> _call(String method, String path,
      {Map<String, String> query = const {}, Map<String, String>? form, Object? body}) async {
    Future<http.Response> send(String base) async {
      final old = _base;
      _base = base;
      try {
        final uri = _uri(path, query);
        final headers = {
          'User-Agent': PoliceSign.userAgent(),
          'Sign': PoliceSign.make(),
        };
        if (form != null) {
          headers['Content-Type'] = 'application/x-www-form-urlencoded';
          return await http.post(uri, headers: headers,
              body: Uri(queryParameters: form).query);
        }
        if (body != null) {
          headers['Content-Type'] = 'application/json';
          return await http.post(uri, headers: headers, body: jsonEncode(body));
        }
        if (method == 'POST') {
          headers['Content-Type'] = 'application/json';
          return await http.post(uri, headers: headers, body: '{}');
        }
        return await http.get(uri, headers: headers);
      } finally {
        _base = old;
      }
    }

    http.Response resp;
    try {
      resp = await send(_base);
    } catch (e) {
      // Automatic failover to the other API host (mirrors the Android app).
      final fallback = _base == primaryBase ? altBase : primaryBase;
      resp = await send(fallback);
      await _switchBase(fallback);
    }

    final text = utf8.decode(resp.bodyBytes, allowMalformed: true);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(resp.statusCode, 'HTTP ${resp.statusCode}');
    }
    dynamic json;
    try {
      json = jsonDecode(text);
    } catch (_) {
      throw ApiException(-1, 'Некорректный ответ сервера');
    }
    return json;
  }

  Pageable<T> _page<T>(dynamic json, T Function(dynamic) parse) {
    return Pageable<T>(
      code: (json['code'] as num?)?.toInt(),
      content: ((json['content'] as List?) ?? []).map(parse).toList(),
      currentPage: (json['current_page'] as num?)?.toInt(),
      totalPageCount: (json['total_page_count'] as num?)?.toInt(),
    );
  }

  // ---- Auth ----

  Future<Profile?> signIn(String login, String password) async {
    final j = await _call('POST', 'auth/signIn', form: {'login': login, 'password': password});
    final code = (j['code'] as num?)?.toInt() ?? -1;
    if (code == 0) {
      final tokenObj = ProfileToken.fromJson(j['profileToken']);
      final profile = j['profile'] == null ? null : Profile.fromJson(j['profile']);
      await setToken(tokenObj.token);
      return profile;
    }
    throw ApiException(code, code == 2 ? 'Неверный логин' : code == 3 ? 'Неверный пароль' : 'Ошибка входа (код $code)');
  }

  Future<void> signOut() => setToken(null);

  Future<String?> signUp(String login, String email, String password) async {
    final j = await _call('POST', 'auth/signUp',
        form: {'login': login, 'email': email, 'password': password});
    final code = (j['code'] as num?)?.toInt() ?? -1;
    if (code == 0) return j['hash'] as String?;
    const messages = {5: 'Логин уже занят', 6: 'Email уже занят', 3: 'Некорректный email', 2: 'Некорректный логин'};
    throw ApiException(code, messages[code] ?? 'Ошибка регистрации (код $code)');
  }

  Future<Profile?> verify(String login, String email, String password, String hash, String code) async {
    final j = await _call('POST', 'auth/verify', form: {
      'login': login, 'email': email, 'password': password, 'hash': hash, 'code': code});
    if ((j['code'] as num?)?.toInt() == 0) {
      final tokenObj = ProfileToken.fromJson(j['profileToken']);
      await setToken(tokenObj.token);
      return j['profile'] == null ? null : Profile.fromJson(j['profile']);
    }
    throw ApiException(1, 'Неверный код подтверждения');
  }

  // ---- Catalog ----

  Future<Pageable<Release>> filter(int page, FilterRequest f) async {
    final j = await _call('POST', 'filter/$page?extended_mode=true',
        body: f.toJson());
    return _page(j, Release.fromJson);
  }

  Future<Release> release(int id) async {
    final j = await _call('GET', 'release/$id?extended_mode=true');
    if (j['release'] == null) throw ApiException((j['code'] as num?)?.toInt() ?? 1, 'Релиз недоступен');
    return Release.fromJson(j['release']);
  }

  Future<Release> randomRelease() async {
    final j = await _call('GET', 'release/random?extended_mode=true');
    if (j['release'] == null) throw ApiException(1, 'Сервер не вернул релиз');
    return Release.fromJson(j['release']);
  }

  Future<ScheduleData> schedule() async =>
      ScheduleData.fromJson(await _call('GET', 'schedule'));

  Future<Pageable<Release>> related(int releaseId, int page) async {
    final j = await _call('GET', 'related/$releaseId/$page');
    return _page(j, Release.fromJson);
  }

  // ---- Discover ----

  Future<List<dynamic>> interesting() async {
    final j = await _call('POST', 'discover/interesting');
    return (j['content'] as List?) ?? [];
  }

  Future<Pageable<Release>> recommendations(int page) async {
    final j = await _call('POST', 'discover/recommendations/$page?previous_page=${page > 0 ? page - 1 : 0}');
    return _page(j, Release.fromJson);
  }

  Future<Pageable<Release>> discussing(int page) async {
    final j = await _call('POST', 'discover/discussing');
    return _page(j, Release.fromJson);
  }

  // ---- Search ----

  Future<Pageable<Release>> searchReleases(String query, int page) async {
    final j = await _call('POST', 'search/releases/$page',
        body: {'query': query, 'searchBy': 0});
    return _page(j, Release.fromJson);
  }

  Future<Pageable<Collection>> searchCollections(String query, int page) async {
    final j = await _call('POST', 'search/collections/$page',
        body: {'query': query, 'searchBy': 0});
    return _page(j, Collection.fromJson);
  }

  Future<Pageable<Profile>> searchProfiles(String query, int page) async {
    final j = await _call('POST', 'search/profiles/$page',
        body: {'query': query, 'searchBy': 0});
    return _page(j, Profile.fromJson);
  }

  // ---- Episodes ----

  Future<List<EpisodeType>> episodeTypes(int releaseId) async {
    final j = await _call('GET', 'episode/$releaseId');
    return ((j['types'] as List?) ?? [])
        .whereType<Map<String, dynamic>>().map(EpisodeType.fromJson).toList();
  }

  Future<List<EpisodeSource>> episodeSources(int releaseId, int typeId) async {
    final j = await _call('GET', 'episode/$releaseId/$typeId');
    return ((j['sources'] as List?) ?? [])
        .whereType<Map<String, dynamic>>().map(EpisodeSource.fromJson).toList();
  }

  Future<List<Episode>> episodes(int releaseId, int typeId, int sourceId) async {
    final j = await _call('GET', 'episode/$releaseId/$typeId/$sourceId');
    return ((j['episodes'] as List?) ?? [])
        .whereType<Map<String, dynamic>>().map(Episode.fromJson).toList();
  }

  Future<void> markWatched(int releaseId, int sourceId, int position, {bool watched = true}) async {
    await _call('POST', 'episode/${watched ? 'watch' : 'unwatch'}/$releaseId/$sourceId/$position');
  }

  Future<DirectLinks?> parseVideo(String url) async {
    final j = await _call('POST', 'video/parse', body: {'url': url});
    return j['default'] == null ? null : DirectLinks.fromJson(j['default']);
  }

  // ---- History ----

  Future<Pageable<Release>> history(int page) async {
    final j = await _call('GET', 'history/$page');
    return _page(j, Release.fromJson);
  }

  Future<void> saveHistory(int releaseId, int sourceId, int position) async {
    try { await _call('GET', 'history/add/$releaseId/$sourceId/$position'); } catch (_) {}
  }

  // ---- Favorites / lists ----

  Future<void> favoriteAdd(int releaseId) async => _call('GET', 'favorite/add/$releaseId');
  Future<void> favoriteDelete(int releaseId) async => _call('GET', 'favorite/delete/$releaseId');
  Future<Pageable<Release>> favorites(int page) async {
    final j = await _call('GET', 'favorite/all/$page');
    return _page(j, Release.fromJson);
  }

  Future<void> listAdd(ProfileListStatus s, int releaseId) async =>
      _call('GET', 'profile/list/add/${s.value}/$releaseId');
  Future<void> listDelete(ProfileListStatus s, int releaseId) async =>
      _call('GET', 'profile/list/delete/${s.value}/$releaseId');
  Future<Pageable<Release>> profileList(ProfileListStatus s, int page) async {
    final j = await _call('GET', 'profile/list/all/${s.value}/$page');
    return _page(j, Release.fromJson);
  }

  // ---- Votes ----

  Future<void> vote(int releaseId, int vote) async => _call('GET', 'release/vote/add/$releaseId/$vote');
  Future<void> voteDelete(int releaseId) async => _call('GET', 'release/vote/delete/$releaseId');

  // ---- Collections ----

  Future<Pageable<Collection>> collections(int page) async {
    final j = await _call('GET', 'collection/all/$page');
    return _page(j, Collection.fromJson);
  }

  Future<Collection> collection(int id) async {
    final j = await _call('GET', 'collection/$id');
    if (j['collection'] == null) throw ApiException((j['code'] as num?)?.toInt() ?? 1, 'Коллекция недоступна');
    return Collection.fromJson(j['collection']);
  }

  Future<Pageable<Release>> collectionReleases(int id, int page) async {
    final j = await _call('GET', 'collection/$id/releases/$page');
    return _page(j, Release.fromJson);
  }

  Future<void> collectionFavoriteAdd(int id) async => _call('GET', 'collectionFavorite/add/$id');
  Future<void> collectionFavoriteDelete(int id) async => _call('GET', 'collectionFavorite/delete/$id');

  // ---- Comments ----

  Future<Pageable<ReleaseComment>> comments(int releaseId, int page) async {
    final j = await _call('GET', 'release/comment/all/$releaseId/$page');
    return _page(j, ReleaseComment.fromJson);
  }

  Future<void> addComment(int releaseId, String message,
      {int? parentCommentId, bool isSpoiler = false}) async {
    final j = await _call('POST', 'release/comment/add/$releaseId', body: {
      'message': message,
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
      'isSpoiler': isSpoiler,
    });
    final code = (j['code'] as num?)?.toInt() ?? -1;
    if (code != 0) throw ApiException(code, 'Не удалось отправить (код $code)');
  }

  Future<void> voteComment(int commentId, int vote) async =>
      _call('GET', 'release/comment/vote/$commentId/$vote');

  // ---- Profile ----

  Future<Profile> profile(int id) async {
    final j = await _call('GET', 'profile/$id');
    if (j['profile'] == null) {
      final code = (j['code'] as num?)?.toInt() ?? 1;
      throw ApiException(code, code == 2 ? 'Профиль не найден' : 'Профиль недоступен');
    }
    return Profile.fromJson(j['profile']);
  }

  Future<Pageable<Profile>> friends(int profileId, int page) async {
    final j = await _call('GET', 'profile/friend/all/$profileId/$page');
    return _page(j, Profile.fromJson);
  }

  // ---- Notifications ----

  Future<int> notificationCount() async {
    final j = await _call('GET', 'notification/count');
    return (j['count'] as num?)?.toInt() ?? 0;
  }

  Future<Pageable<Release>> notificationEpisodes(int page) async {
    // The episodes feed carries nested episode+release wrappers; reuse Release parse
    // on the notification items that embed release data.
    final j = await _call('GET', 'notification/episodes/$page');
    return _page(j, Release.fromJson);
  }

  Future<Pageable<ReleaseComment>> notificationComments(int page) async {
    final j = await _call('GET', 'notification/releaseComments/$page');
    return _page(j, ReleaseComment.fromJson);
  }

  Future<void> notificationsRead() async => _call('GET', 'notification/read');
}
