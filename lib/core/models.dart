/// Data models decoded from the Anixart API wire format (mixed snake/camel).

class Pageable<T> {
  final int? code;
  final List<T> content;
  final int? currentPage;
  final int? totalPageCount;
  Pageable({required this.code, required this.content, this.currentPage, this.totalPageCount});
}

class RefEntity {
  final int id;
  final String? name;
  RefEntity({required this.id, this.name});

  factory RefEntity.fromJson(Map<String, dynamic> j) =>
      RefEntity(id: (j['id'] as num?)?.toInt() ?? 0, name: j['name'] as String?);
}

/// Баннер видео-раздела релиза (трейлеры / опенинги).
class VideoBanner {
  final String? name, image, value;
  final int? actionId;
  final bool? isNew;
  VideoBanner({this.name, this.image, this.value, this.actionId, this.isNew});

  factory VideoBanner.fromJson(Map<String, dynamic> j) => VideoBanner(
      name: j['name'] as String?,
      image: j['image'] as String?,
      value: j['value'] as String?,
      actionId: (j['action_id'] as num?)?.toInt(),
      isNew: j['is_new'] == true,
  );
}

class Release {
  final int id;
  final String? titleRu, titleOriginal, description, poster, image;
  final List<String> screenshots;
  final String? year;
  final int? season, statusId, ageRating, broadcast, duration;
  final RefEntity? category, status;
  final String? genres, country, studio, director, author, translators, source, note;
  final int? episodesTotal, episodesReleased;
  final double? grade;
  final int? rating, voteCount, yourVote;
  final int vote1Count, vote2Count, vote3Count, vote4Count, vote5Count;
  final List<VideoBanner> videoBanners;
  final int favoriteCount, watchingCount, completedCount, droppedCount, holdOnCount, planCount, collectionCount, commentCount, commentPerDayCount;
  final int? relatedCount;
  final List<Release> relatedReleases, recommendedReleases;
  final bool isFavorite, isViewed, isAdult, isDeleted, isViewBlocked, isPlayDisabled, canTorlookSearch, canVideoAppeal;
  final int? profileListStatus;
  final Episode? lastViewEpisode;
  final int? lastViewTimestamp;
  final Map<String, dynamic>? episodeLastUpdate;
  final String? releaseDate;
  final int? lastUpdateDate, airedOnDate;

  Release({
    required this.id,
    this.titleRu, this.titleOriginal, this.description, this.poster, this.image,
    this.screenshots = const [],
    this.year, this.season, this.statusId, this.ageRating, this.broadcast, this.duration,
    this.category, this.status,
    this.genres, this.country, this.studio, this.director, this.author, this.translators, this.source, this.note,
    this.episodesTotal, this.episodesReleased,
    this.grade, this.rating, this.voteCount, this.yourVote,
    this.vote1Count = 0, this.vote2Count = 0, this.vote3Count = 0, this.vote4Count = 0, this.vote5Count = 0,
    this.videoBanners = const [],
    this.favoriteCount = 0, this.watchingCount = 0, this.completedCount = 0,
    this.droppedCount = 0, this.holdOnCount = 0, this.planCount = 0,
    this.collectionCount = 0, this.commentCount = 0, this.commentPerDayCount = 0,
    this.relatedCount, this.relatedReleases = const [], this.recommendedReleases = const [],
    this.isFavorite = false, this.isViewed = false, this.isAdult = false,
    this.isDeleted = false, this.isViewBlocked = false, this.isPlayDisabled = false,
    this.canTorlookSearch = false, this.canVideoAppeal = false,
    this.profileListStatus, this.lastViewEpisode, this.lastViewTimestamp,
    this.episodeLastUpdate, this.releaseDate, this.lastUpdateDate, this.airedOnDate,
  });

  factory Release.fromJson(Map<String, dynamic> j) {
    List<T> listOf<T>(String k, T Function(Map<String, dynamic>) f) =>
        ((j[k] as List?) ?? []).whereType<Map<String, dynamic>>().map(f).toList();
    int? asInt(String k) => (j[k] as num?)?.toInt();
    String? asStr(String k) => j[k] is String ? j[k] as String : null;

    return Release(
      id: asInt('id') ?? 0,
      titleRu: asStr('title_ru'),
      titleOriginal: asStr('title_original'),
      description: asStr('description'),
      poster: asStr('poster'),
      image: asStr('image'),
      screenshots: ((j['screenshots'] as List?) ?? []).whereType<String>().toList(),
      year: asStr('year'),
      season: asInt('season'),
      statusId: asInt('status_id'),
      ageRating: asInt('age_rating'),
      broadcast: asInt('broadcast'),
      duration: asInt('duration'),
      category: j['category'] is Map ? RefEntity.fromJson(j['category']) : null,
      status: j['status'] is Map ? RefEntity.fromJson(j['status']) : null,
      genres: asStr('genres'),
      country: asStr('country'),
      studio: asStr('studio'),
      director: asStr('director'),
      author: asStr('author'),
      translators: asStr('translators'),
      source: asStr('source'),
      note: asStr('note'),
      episodesTotal: asInt('episodes_total'),
      episodesReleased: asInt('episodes_released'),
      grade: (j['grade'] as num?)?.toDouble(),
      rating: asInt('rating'),
      voteCount: asInt('vote_count'),
      yourVote: asInt('your_vote'),
      vote1Count: asInt('vote_1_count') ?? 0,
      vote2Count: asInt('vote_2_count') ?? 0,
      vote3Count: asInt('vote_3_count') ?? 0,
      vote4Count: asInt('vote_4_count') ?? 0,
      vote5Count: asInt('vote_5_count') ?? 0,
      videoBanners: ((j['video_banners'] as List?) ?? [])
          .whereType<Map<String, dynamic>>().map(VideoBanner.fromJson).toList(),
      favoriteCount: asInt('favorites_count') ?? 0,
      watchingCount: asInt('watching_count') ?? 0,
      completedCount: asInt('completed_count') ?? 0,
      droppedCount: asInt('dropped_count') ?? 0,
      holdOnCount: asInt('hold_on_count') ?? 0,
      planCount: asInt('plan_count') ?? 0,
      collectionCount: asInt('collection_count') ?? 0,
      commentCount: asInt('comment_count') ?? 0,
      commentPerDayCount: asInt('comment_per_day_count') ?? 0,
      relatedCount: asInt('related_count'),
      relatedReleases: listOf('related_releases', Release.fromJson),
      recommendedReleases: listOf('recommended_releases', Release.fromJson),
      isFavorite: j['is_favorite'] == true,
      isViewed: j['is_viewed'] == true,
      isAdult: j['is_adult'] == true,
      isDeleted: j['is_deleted'] == true,
      isViewBlocked: j['is_view_blocked'] == true,
      isPlayDisabled: j['is_play_disabled'] == true,
      canTorlookSearch: j['can_torlook_search'] == true,
      canVideoAppeal: j['can_video_appeal'] == true,
      profileListStatus: asInt('profile_list_status'),
      lastViewEpisode: j['last_view_episode'] is Map ? Episode.fromJson(j['last_view_episode']) : null,
      lastViewTimestamp: asInt('last_view_timestamp'),
      episodeLastUpdate: j['episode_last_update'] as Map<String, dynamic>?,
      releaseDate: asStr('release_date'),
      lastUpdateDate: asInt('last_update_date'),
      airedOnDate: asInt('aired_on_date'),
    );
  }

  List<String> get genreList =>
      (genres ?? '').split(',').map((g) => g.trim()).where((g) => g.isNotEmpty).toList();

  String get statusLabel {
    switch (statusId) {
      case 1: return 'вышел';
      case 2: return 'выходит';
      case 3: return 'анонс';
      default: return status?.name ?? '';
    }
  }

  String get episodesLabel {
    final r = episodesReleased ?? 0;
    final t = episodesTotal;
    if (t != null && t > 0) return '$r из $t эп.';
    return '$r эп.';
  }

  String get typeLabel {
    switch (category?.id) {
      case 2: return 'Фильм';
      case 3: return 'OVA';
      case 6: return 'Спешл';
      default: return 'Сериал';
    }
  }
}

class Episode {
  final int? releaseId, sourceId, position;
  final String? name, url;
  final bool? iframe, isFiller, isWatched;
  final int? playbackPosition, quality;

  Episode({this.releaseId, this.sourceId, this.position, this.name, this.url,
      this.iframe, this.isFiller, this.isWatched, this.playbackPosition, this.quality});

  factory Episode.fromJson(Map<String, dynamic> j) => Episode(
      releaseId: (j['releaseId'] as num?)?.toInt(),
      sourceId: (j['sourceId'] as num?)?.toInt(),
      position: (j['position'] as num?)?.toInt(),
      name: j['name'] as String?,
      url: j['url'] as String?,
      iframe: j['iframe'] == true,
      isFiller: j['is_filler'] == true,
      isWatched: j['is_watched'] == true,
      playbackPosition: (j['playback_position'] as num?)?.toInt(),
      quality: (j['quality'] as num?)?.toInt(),
  );
}

class EpisodeType {
  final int id;
  final String? name, icon, workers;
  final bool? isSub, pinned;
  final int? episodesCount, viewCount, quality;
  EpisodeType({required this.id, this.name, this.icon, this.workers, this.isSub, this.pinned, this.episodesCount, this.viewCount, this.quality});

  factory EpisodeType.fromJson(Map<String, dynamic> j) => EpisodeType(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: j['name'] as String?,
      icon: j['icon'] as String?,
      workers: j['workers'] as String?,
      isSub: j['is_sub'] == true,
      pinned: j['pinned'] == true,
      episodesCount: (j['episodes_count'] as num?)?.toInt(),
      viewCount: (j['view_count'] as num?)?.toInt(),
      quality: (j['quality'] as num?)?.toInt(),
  );
}

class EpisodeSource {
  final int id;
  final String? name;
  final int? episodesCount, quality;
  EpisodeSource({required this.id, this.name, this.episodesCount, this.quality});

  factory EpisodeSource.fromJson(Map<String, dynamic> j) => EpisodeSource(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: j['name'] as String?,
      episodesCount: (j['episodes_count'] as num?)?.toInt(),
      quality: (j['quality'] as num?)?.toInt(),
  );
}

class DirectLinks {
  final String? d, q360p, q480p, q720p, q1080p;
  DirectLinks({this.d, this.q360p, this.q480p, this.q720p, this.q1080p});

  factory DirectLinks.fromJson(Map<String, dynamic> j) => DirectLinks(
      d: j['default'] as String?,
      q360p: j['q360p'] as String?,
      q480p: j['q480p'] as String?,
      q720p: j['q720p'] as String?,
      q1080p: j['q1080p'] as String?,
  );

  String? get best => q1080p ?? q720p ?? q480p ?? q360p ?? d;
}

class Role {
  final int? id;
  final String? name, color;
  Role({this.id, this.name, this.color});
  factory Role.fromJson(Map<String, dynamic> j) =>
      Role(id: (j['id'] as num?)?.toInt(), name: j['name'] as String?, color: j['color'] as String?);
}

class Profile {
  final int id;
  final String? login, avatar, status, badge;
  final List<Role> roles;
  final int? friendStatus, privilegeLevel;
  final bool? isOnline, isVerified, isSponsor, isBanned, isBlocked;
  final int? collectionCount, commentCount, completedCount, droppedCount, favoriteCount,
      friendCount, holdOnCount, planCount, watchingCount, videoCount,
      watchedEpisodeCount, watchedTime, ratingScore;
  final String? vkPage, tgPage, instPage, ttPage, discordPage;

  Profile({required this.id, this.login, this.avatar, this.status, this.badge,
      this.roles = const [], this.friendStatus, this.privilegeLevel,
      this.isOnline, this.isVerified, this.isSponsor, this.isBanned, this.isBlocked,
      this.collectionCount, this.commentCount, this.completedCount, this.droppedCount,
      this.favoriteCount, this.friendCount, this.holdOnCount, this.planCount,
      this.watchingCount, this.videoCount, this.watchedEpisodeCount, this.watchedTime,
      this.ratingScore, this.vkPage, this.tgPage, this.instPage, this.ttPage, this.discordPage});

  factory Profile.fromJson(Map<String, dynamic> j) {
    int? asInt(String k) => (j[k] as num?)?.toInt();
    String? asStr(String k) => j[k] is String ? j[k] as String : null;
    return Profile(
      id: asInt('id') ?? 0,
      login: asStr('login'),
      avatar: asStr('avatar'),
      status: asStr('status'),
      badge: asStr('badge'),
      roles: ((j['roles'] as List?) ?? []).whereType<Map<String, dynamic>>().map(Role.fromJson).toList(),
      friendStatus: asInt('friend_status'),
      privilegeLevel: asInt('privilege_level'),
      isOnline: j['is_online'] == true,
      isVerified: j['is_verified'] == true,
      isSponsor: j['is_sponsor'] == true,
      isBanned: j['is_banned'] == true,
      isBlocked: j['is_blocked'] == true,
      collectionCount: asInt('collection_count'),
      commentCount: asInt('comment_count'),
      completedCount: asInt('completed_count'),
      droppedCount: asInt('dropped_count'),
      favoriteCount: asInt('favorite_count'),
      friendCount: asInt('friend_count'),
      holdOnCount: asInt('hold_on_count'),
      planCount: asInt('plan_count'),
      watchingCount: asInt('watching_count'),
      videoCount: asInt('video_count'),
      watchedEpisodeCount: asInt('watched_episode_count'),
      watchedTime: asInt('watched_time'),
      ratingScore: asInt('rating_score'),
      vkPage: asStr('vk_page'), tgPage: asStr('tg_page'),
      instPage: asStr('inst_page'), ttPage: asStr('tt_page'), discordPage: asStr('discord_page'),
    );
  }
}

class ProfileToken {
  final int? id;
  final String? token;
  ProfileToken({this.id, this.token});
  factory ProfileToken.fromJson(Map<String, dynamic> j) =>
      ProfileToken(id: (j['id'] as num?)?.toInt(), token: j['token'] as String?);
}

class Collection {
  final int id;
  final String? title, description, image;
  final Profile? creator;
  final bool? isPrivate, isFavorite, isDeleted;
  final int favoriteCount, commentCount;
  final int? creationDate, lastUpdateDate;
  Collection({required this.id, this.title, this.description, this.image, this.creator,
      this.isPrivate, this.isFavorite, this.isDeleted, this.favoriteCount = 0,
      this.commentCount = 0, this.creationDate, this.lastUpdateDate});

  factory Collection.fromJson(Map<String, dynamic> j) => Collection(
      id: (j['id'] as num?)?.toInt() ?? 0,
      title: j['title'] as String?,
      description: j['description'] as String?,
      image: j['image'] as String?,
      creator: j['creator'] is Map ? Profile.fromJson(j['creator']) : null,
      isPrivate: j['is_private'] == true,
      isFavorite: j['is_favorite'] == true,
      isDeleted: j['is_deleted'] == true,
      favoriteCount: (j['favorites_count'] as num?)?.toInt() ?? 0,
      commentCount: (j['comment_count'] as num?)?.toInt() ?? 0,
      creationDate: (j['creation_date'] as num?)?.toInt(),
      lastUpdateDate: (j['last_update_date'] as num?)?.toInt(),
  );
}

class ReleaseComment {
  final int id;
  final String? message;
  final Profile? profile;
  final int? parentCommentId, replyCount, timestamp, vote, voteCount;
  final bool? isEdited, isDeleted, isSpoiler;

  ReleaseComment({required this.id, this.message, this.profile, this.parentCommentId,
      this.replyCount, this.timestamp, this.vote, this.voteCount,
      this.isEdited, this.isDeleted, this.isSpoiler});

  factory ReleaseComment.fromJson(Map<String, dynamic> j) => ReleaseComment(
      id: (j['id'] as num?)?.toInt() ?? 0,
      message: j['message'] as String?,
      profile: j['profile'] is Map ? Profile.fromJson(j['profile']) : null,
      parentCommentId: (j['parentCommentId'] as num?)?.toInt(),
      replyCount: (j['replyCount'] as num?)?.toInt(),
      timestamp: (j['timestamp'] as num?)?.toInt(),
      vote: (j['vote'] as num?)?.toInt(),
      voteCount: (j['voteCount'] as num?)?.toInt(),
      isEdited: j['isEdited'] == true,
      isDeleted: j['isDeleted'] == true,
      isSpoiler: j['isSpoiler'] == true,
  );
}

class ScheduleData {
  final Map<int, List<Release>> byDay; // 1=Mon..7=Sun
  ScheduleData({required this.byDay});

  factory ScheduleData.fromJson(Map<String, dynamic> j) {
    List<Release> day(String k) =>
        ((j[k] as List?) ?? []).whereType<Map<String, dynamic>>().map(Release.fromJson).toList();
    return ScheduleData(byDay: {
      1: day('monday'), 2: day('tuesday'), 3: day('wednesday'),
      4: day('thursday'), 5: day('friday'), 6: day('saturday'), 7: day('sunday'),
    });
  }
}

class Toggles {
  final String? baseUrl, apiUrl, apiAltUrl, kodikVideoLinksUrl, torlookUrl, iframeEmbedUrl;
  final bool? apiAltAvailable, kodikIframeAd, sibnetRandUserAgent;
  Toggles({this.baseUrl, this.apiUrl, this.apiAltUrl, this.apiAltAvailable,
      this.kodikVideoLinksUrl, this.torlookUrl, this.iframeEmbedUrl,
      this.kodikIframeAd, this.sibnetRandUserAgent});

  factory Toggles.fromJson(Map<String, dynamic> j) => Toggles(
      baseUrl: j['baseUrl'] as String?,
      apiUrl: j['apiUrl'] as String?,
      apiAltUrl: j['apiAltUrl'] as String?,
      apiAltAvailable: j['apiAltAvailable'] == true,
      kodikVideoLinksUrl: j['kodikVideoLinksUrl'] as String?,
      torlookUrl: j['torlookUrl'] as String?,
      iframeEmbedUrl: j['iframeEmbedUrl'] as String?,
      kodikIframeAd: j['kodikIframeAd'] == true,
      sibnetRandUserAgent: j['sibnetRandUserAgent'] == true,
  );
}

enum ProfileListStatus {
  watching(1, 'Смотрю'),
  plans(2, 'В планах'),
  completed(3, 'Просмотрено'),
  holdOn(4, 'Отложено'),
  dropped(5, 'Брошено');

  final int value;
  final String title;
  const ProfileListStatus(this.value, this.title);
}

class FilterRequest {
  int? categoryId, statusId, sort, startYear, endYear;
  List<String>? genres;
  bool? isGenresExcludeModeEnabled;
  Map<String, dynamic> toJson() => {
    if (categoryId != null) 'category_id': categoryId,
    if (statusId != null) 'status_id': statusId,
    if (sort != null) 'sort': sort,
    if (startYear != null) 'start_year': startYear,
    if (endYear != null) 'end_year': endYear,
    if (genres != null && genres!.isNotEmpty) 'genres': genres,
    if (isGenresExcludeModeEnabled != null) 'is_genres_exclude_mode_enabled': isGenresExcludeModeEnabled,
  };
}
