import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../collections/collection_detail_screen.dart';
import '../home/home_screen.dart';
import '../root.dart';
import '../widgets.dart';
import 'comments_screen.dart';

/// Страница релиза (screenshots 11/12): blurred backdrop, centered poster,
/// title + original + age, pills row, play button, info rows, genres, description.
class ReleaseScreen extends StatefulWidget {
  final ReleaseArgs args;
  const ReleaseScreen({super.key, required this.args});

  @override
  State<ReleaseScreen> createState() => _ReleaseScreenState();
}

class _ReleaseScreenState extends State<ReleaseScreen> {
  Release? _release;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final id = widget.args.release?.id ?? widget.args.releaseId ?? 0;
      final r = await Api.I.release(id);
      if (mounted) setState(() => _release = r);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _release = widget.args.release; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _release;
    final isAnons = r?.statusId == 3;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: r == null
          ? (_error != null
              ? SafeArea(child: ErrorCentered(message: _error!, onRetry: _load))
              : const Center(child: CircularProgressIndicator(color: AppColors.textSecondary)))
          // Фон через DecorationImage — не участвует в hit-test, скролл живой.
          : Container(
              decoration: BoxDecoration(
                image: (r.image ?? '').isEmpty ? null : DecorationImage(
                    image: CachedNetworkImageProvider(r.image!),
                    fit: BoxFit.cover,
                    opacity: 0.18),
              ),
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    // Top buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        _roundIcon(Icons.arrow_back, () => Navigator.maybePop(context)),
                        _roundIcon(Icons.add_to_photos_outlined, () {}),
                      ]),
                    ),
                    // Centered poster
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 30)]),
                        child: Poster(url: r.image, width: 220, height: 324, radius: 18),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Title block
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.info_outline, size: 18, color: AppColors.textTertiary),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r.titleRu ?? '', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Row(children: [
                            Flexible(child: Text(r.titleOriginal ?? '',
                                style: const TextStyle(fontSize: 13.5, color: AppColors.textTertiary),
                                overflow: TextOverflow.ellipsis)),
                            if (r.ageRating != null && r.ageRating! > 0) ...[
                              const SizedBox(width: 8),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(7)),
                                  child: Text('${r.ageRating!}+',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary))),
                            ],
                          ]),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    // Pills row: status dropdown, favorites count, comments
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        Expanded(
                          flex: 3,
                          child: OutlinedButton(
                            onPressed: () => _showStatusMenu(r),
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.outline),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                padding: const EdgeInsets.symmetric(vertical: 11)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(_listTitle(r.profileListStatus),
                                  style: const TextStyle(fontSize: 14.5)),
                              const SizedBox(width: 6),
                              const Icon(Icons.keyboard_arrow_down, size: 18),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: OutlinedButton(
                            onPressed: () => _toggleFavorite(r),
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.outline),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                padding: const EdgeInsets.symmetric(vertical: 11)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text('${r.favoriteCount + (r.isFavorite ? 0 : 0)}',
                                  style: const TextStyle(fontSize: 14.5)),
                              const SizedBox(width: 8),
                              Icon(
                                r.isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                size: 17,
                                color: r.isFavorite ? AppColors.statPlans : null,
                              ),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => CommentsScreen(releaseId: r.id))),
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.outline),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                padding: const EdgeInsets.symmetric(vertical: 11)),
                            child: const Icon(Icons.chat_bubble_outline, size: 18),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    // Play button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        Expanded(
                          child: isAnons
                              ? Container(
                                  height: 52,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(28)),
                                  child: const Text('СКОРО',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary)))
                              : LightPillButton(icon: Icons.play_arrow_rounded, label: 'Воспроизвести',
                                  onTap: () => Navigator.pushNamed(context, Routes.voiceover,
                                      arguments: r)),
                        ),
                        IconButton(
                            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                            onPressed: () => _showMoreMenu(r)),
                      ]),
                    ),
                    // Note banner
                    if ((r.note ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14)),
                        child: Text(stripHtml(r.note!),
                            style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4)),
                      ),
                    ],
                    const SizedBox(height: 14),
                    // Info rows
                    _infoRow(Icons.flag_outlined, _countryLine(r)),
                    _infoRow(Icons.play_circle_outline, '${r.episodesLabel} по ~${r.duration ?? 24} мин.'),
                    _infoRow(Icons.calendar_today_outlined, '${r.typeLabel}, ${r.statusLabel}'),
                    if ((r.source ?? '').isNotEmpty)
                      _infoRow(Icons.adjust, 'Первоисточник ${r.source}'),
                    if ((r.studio ?? '').isNotEmpty || (r.author ?? '').isNotEmpty)
                      _infoRow(Icons.groups_outlined, _peopleLine(r)),
                    // Genres
                    if (r.genreList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Wrap(
                          spacing: 12, runSpacing: 6,
                          children: [for (final g in r.genreList)
                            Text(g, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary,
                                decoration: TextDecoration.underline))],
                        ),
                      ),
                    // Description
                    if ((r.description ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Text(stripHtml(r.description!),
                            style: const TextStyle(fontSize: 14.5, height: 1.5,
                                color: AppColors.textSecondary)),
                      ),

                    // Трейлеры / Опенинги (video_banners)
                    if ((r.videoBanners ?? []).isNotEmpty) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 130,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: r.videoBanners!.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final b = r.videoBanners![i];
                            return GestureDetector(
                              onTap: () => _snack('Раздел видео: ${b.name ?? ''}'),
                              child: Stack(children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: CachedNetworkImage(
                                      imageUrl: b.image ?? '', width: 200, height: 130,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                          width: 200, height: 130, color: AppColors.surface)),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: Colors.black26),
                                    alignment: Alignment.center,
                                    child: Text(b.name ?? '',
                                        style: const TextStyle(fontSize: 17,
                                            fontWeight: FontWeight.w700, color: Colors.white)),
                                  ),
                                ),
                              ]),
                            );
                          },
                        ),
                      ),
                    ],

                    // Рейтинг: средняя оценка + гистограмма + звёзды
                    if ((r.voteCount ?? 0) > 0) ...[
                      const SizedBox(height: 22),
                      const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: Text('Рейтинг', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                          SizedBox(width: 92, child: Column(children: [
                            Text((r.grade ?? 0).toStringAsFixed(1),
                                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('${r.voteCount} голосов',
                                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                                textAlign: TextAlign.center),
                          ])),
                          Expanded(child: Column(children: [
                            for (final star in [5, 4, 3, 2, 1])
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(children: [
                                  SizedBox(width: 14, child: Text('$star',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary))),
                                  const SizedBox(width: 8),
                                  Expanded(child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                          value: _voteFraction(r, star),
                                          minHeight: 8,
                                          backgroundColor: AppColors.surface,
                                          valueColor: const AlwaysStoppedAnimation(AppColors.textSecondary)))),
                                ]),
                              ),
                          ])),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          for (var star = 1; star <= 5; star++)
                            IconButton(
                              iconSize: 34,
                              icon: Icon(
                                  (r.yourVote ?? 0) >= star ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: AppColors.statHoldOn),
                              onPressed: () async {
                                try {
                                  await Api.I.vote(r.id, star);
                                  _snack('Оценка $star сохранена');
                                  _load();
                                } catch (e) { _snack('$e'); }
                              },
                            ),
                        ]),
                      ),
                    ],

                    // В списках у людей
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.outline, height: 1),
                    const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Text('В списках у людей', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700))),
                    _peopleInLists(r),

                    // Кадры
                    if ((r.screenshots ?? []).isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: Text('Кадры', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700))),
                      SizedBox(
                        height: 96,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: r.screenshots!.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, i) => ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                  imageUrl: r.screenshots![i], width: 168, height: 96,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                      width: 168, height: 96, color: AppColors.surface))),
                        ),
                      ),
                    ],

                    // Показать в коллекциях
                    if ((r.collectionCount ?? 0) > 0)
                      Padding(padding: const EdgeInsets.only(top: 18), child: InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ReleaseCollectionsScreen(release: r))),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(children: [
                            Text('Показать в коллекциях',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 10),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text('${r.collectionCount}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                            const Spacer(),
                            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                          ]),
                        ),
                      )),

                    // Комментарии (популярные и актуальные) — прямо на странице
                    const SizedBox(height: 16),
                    CommentsPreview(releaseId: r.id, commentCount: r.commentCount),
                  ],
                ),
              ),
            ),
    );
  }

  double _voteFraction(Release r, int star) {
    final total = (r.voteCount ?? 0).toDouble();
    if (total <= 0) return 0;
    final v = switch (star) {
      1 => r.vote1Count ?? 0,
      2 => r.vote2Count ?? 0,
      3 => r.vote3Count ?? 0,
      4 => r.vote4Count ?? 0,
      _ => r.vote5Count ?? 0,
    };
    return v / total;
  }

  /// Полоса-стек и легенда «В списках у людей» (эталон rel_mid).
  Widget _peopleInLists(Release r) {
    final entries = <(Color, String, int)>[
      (AppColors.statWatching, 'Смотрю', r.watchingCount),
      (AppColors.statPlans, 'В планах', r.planCount),
      (AppColors.statCompleted, 'Просмотрено', r.completedCount),
      (AppColors.statHoldOn, 'Отложено', r.holdOnCount),
      (AppColors.statDropped, 'Брошено', r.droppedCount),
    ].where((e) => e.$3 > 0).toList();
    final total = entries.fold<int>(0, (s, e) => s + e.$3);
    if (total == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(height: 26,
              child: Row(children: [
                for (final e in entries)
                  Expanded(flex: e.$3, child: Container(color: e.$1)),
              ])),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < entries.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              for (final e in entries.skip(i).take(2))
                Expanded(child: Row(children: [
                  Container(width: 14, height: 14, color: e.$1),
                  const SizedBox(width: 8),
                  Text(e.$2, style: const TextStyle(fontSize: 14.5)),
                  const SizedBox(width: 6),
                  Text('${e.$3}', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                ])),
              if (entries.length - i == 1) const Expanded(child: SizedBox()),
            ]),
          ),
      ]),
    );
  }

  String _listTitle(int? status) {
    final s = ProfileListStatus.values.where((e) => e.value == status).firstOrNull;
    return s?.title ?? 'Не смотрю';
  }

  // MARK: Actions (status / favorite / vote)

  Future<void> _showStatusMenu(Release r) async {
    if (!Api.I.isAuthorized) {
      _snack('Войдите в аккаунт, чтобы добавлять в списки');
      return;
    }
    final selected = await showModalBottomSheet<ProfileListStatus>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(14),
              child: Text('Список просмотра', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
          for (final s in ProfileListStatus.values)
            ListTile(
              title: Text(s.title),
              trailing: r.profileListStatus == s.value
                  ? const Icon(Icons.check_rounded, color: AppColors.statWatching)
                  : null,
              onTap: () => Navigator.pop(context, s),
            ),
          const Divider(color: AppColors.outline, height: 1),
          ListTile(
            title: const Text('Убрать из списка'),
            textColor: AppColors.badgeNew,
            onTap: () => Navigator.pop(context, null),
          ),
        ]),
      ),
    );
    if (selected == null && r.profileListStatus == null) return;
    try {
      if (selected == null) {
        await Api.I.listDelete(ProfileListStatus.values.firstWhere((e) => e.value == r.profileListStatus), r.id);
        if (mounted) setState(() => _release = _withStatus(r, null));
      } else {
        await Api.I.listAdd(selected, r.id);
        if (mounted) setState(() => _release = _withStatus(r, selected.value));
      }
    } catch (e) {
      _snack('$e');
    }
  }

  Release _withStatus(Release r, int? status) => Release(
    id: r.id, titleRu: r.titleRu, titleOriginal: r.titleOriginal, description: r.description,
    poster: r.poster, image: r.image, screenshots: r.screenshots, year: r.year,
    season: r.season, statusId: r.statusId, ageRating: r.ageRating, broadcast: r.broadcast,
    duration: r.duration, category: r.category, status: r.status, genres: r.genres,
    country: r.country, studio: r.studio, director: r.director, author: r.author,
    translators: r.translators, source: r.source, note: r.note,
    episodesTotal: r.episodesTotal, episodesReleased: r.episodesReleased,
    grade: r.grade, rating: r.rating, voteCount: r.voteCount, yourVote: r.yourVote,
    favoriteCount: r.favoriteCount, watchingCount: r.watchingCount, completedCount: r.completedCount,
    droppedCount: r.droppedCount, holdOnCount: r.holdOnCount, planCount: r.planCount,
    collectionCount: r.collectionCount, commentCount: r.commentCount,
    commentPerDayCount: r.commentPerDayCount, relatedCount: r.relatedCount,
    relatedReleases: r.relatedReleases, recommendedReleases: r.recommendedReleases,
    isFavorite: r.isFavorite, isViewed: r.isViewed, isAdult: r.isAdult, isDeleted: r.isDeleted,
    isViewBlocked: r.isViewBlocked, isPlayDisabled: r.isPlayDisabled,
    canTorlookSearch: r.canTorlookSearch, canVideoAppeal: r.canVideoAppeal,
    profileListStatus: status, lastViewEpisode: r.lastViewEpisode,
    lastViewTimestamp: r.lastViewTimestamp, episodeLastUpdate: r.episodeLastUpdate,
    releaseDate: r.releaseDate, lastUpdateDate: r.lastUpdateDate, airedOnDate: r.airedOnDate,
  );

  Future<void> _toggleFavorite(Release r) async {
    if (!Api.I.isAuthorized) {
      _snack('Войдите в аккаунт, чтобы добавлять в избранное');
      return;
    }
    try {
      if (r.isFavorite) {
        await Api.I.favoriteDelete(r.id);
        if (mounted) {
          setState(() {
            _release = Release(
              id: r.id, titleRu: r.titleRu, titleOriginal: r.titleOriginal,
              description: r.description, poster: r.poster, image: r.image,
              screenshots: r.screenshots, year: r.year, season: r.season,
              statusId: r.statusId, ageRating: r.ageRating, broadcast: r.broadcast,
              duration: r.duration, category: r.category, status: r.status,
              genres: r.genres, country: r.country, studio: r.studio, director: r.director,
              author: r.author, translators: r.translators, source: r.source, note: r.note,
              episodesTotal: r.episodesTotal, episodesReleased: r.episodesReleased,
              grade: r.grade, rating: r.rating, voteCount: r.voteCount, yourVote: r.yourVote,
              favoriteCount: r.favoriteCount - 1, watchingCount: r.watchingCount,
              completedCount: r.completedCount, droppedCount: r.droppedCount,
              holdOnCount: r.holdOnCount, planCount: r.planCount,
              collectionCount: r.collectionCount, commentCount: r.commentCount,
              commentPerDayCount: r.commentPerDayCount, relatedCount: r.relatedCount,
              relatedReleases: r.relatedReleases, recommendedReleases: r.recommendedReleases,
              isFavorite: false, isViewed: r.isViewed, isAdult: r.isAdult, isDeleted: r.isDeleted,
              isViewBlocked: r.isViewBlocked, isPlayDisabled: r.isPlayDisabled,
              canTorlookSearch: r.canTorlookSearch, canVideoAppeal: r.canVideoAppeal,
              profileListStatus: r.profileListStatus, lastViewEpisode: r.lastViewEpisode,
              lastViewTimestamp: r.lastViewTimestamp, episodeLastUpdate: r.episodeLastUpdate,
              releaseDate: r.releaseDate, lastUpdateDate: r.lastUpdateDate, airedOnDate: r.airedOnDate,
            );
          });
        }
      } else {
        await Api.I.favoriteAdd(r.id);
        if (mounted) {
          setState(() {
            _release = Release(
              id: r.id, titleRu: r.titleRu, titleOriginal: r.titleOriginal,
              description: r.description, poster: r.poster, image: r.image,
              screenshots: r.screenshots, year: r.year, season: r.season,
              statusId: r.statusId, ageRating: r.ageRating, broadcast: r.broadcast,
              duration: r.duration, category: r.category, status: r.status,
              genres: r.genres, country: r.country, studio: r.studio, director: r.director,
              author: r.author, translators: r.translators, source: r.source, note: r.note,
              episodesTotal: r.episodesTotal, episodesReleased: r.episodesReleased,
              grade: r.grade, rating: r.rating, voteCount: r.voteCount, yourVote: r.yourVote,
              favoriteCount: r.favoriteCount + 1, watchingCount: r.watchingCount,
              completedCount: r.completedCount, droppedCount: r.droppedCount,
              holdOnCount: r.holdOnCount, planCount: r.planCount,
              collectionCount: r.collectionCount, commentCount: r.commentCount,
              commentPerDayCount: r.commentPerDayCount, relatedCount: r.relatedCount,
              relatedReleases: r.relatedReleases, recommendedReleases: r.recommendedReleases,
              isFavorite: true, isViewed: r.isViewed, isAdult: r.isAdult, isDeleted: r.isDeleted,
              isViewBlocked: r.isViewBlocked, isPlayDisabled: r.isPlayDisabled,
              canTorlookSearch: r.canTorlookSearch, canVideoAppeal: r.canVideoAppeal,
              profileListStatus: r.profileListStatus, lastViewEpisode: r.lastViewEpisode,
              lastViewTimestamp: r.lastViewTimestamp, episodeLastUpdate: r.episodeLastUpdate,
              releaseDate: r.releaseDate, lastUpdateDate: r.lastUpdateDate, airedOnDate: r.airedOnDate,
            );
          });
        }
      }
    } catch (e) {
      _snack('$e');
    }
  }

  Future<void> _showMoreMenu(Release r) async {
    final vote = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(14),
              child: Text('Оценить релиз', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: StatefulBuilder(builder: (context, setSheet) {
              var hovered = r.yourVote ?? 0;
              return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    iconSize: 36,
                    icon: Icon(star <= hovered ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: AppColors.statHoldOn),
                    onPressed: () => Navigator.pop(context, star),
                  ),
              ]);
            }),
          ),
        ]),
      ),
    );
    if (vote == null) return;
    try {
      await Api.I.vote(r.id, vote);
      _snack('Оценка $vote сохранена');
      _load();
    } catch (e) {
      _snack('$e');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _countryLine(Release r) {
    final season = switch (r.season) { 1 => 'зима', 2 => 'весна', 3 => 'лето', 4 => 'осень', _ => '' };
    final year = r.year ?? '';
    return [r.country ?? '', if (season.isNotEmpty) '$season ${year} г.'.trim() else year]
        .where((s) => s.isNotEmpty).join(', ');
  }

  String _peopleLine(Release r) {
    final parts = <String>[];
    if ((r.studio ?? '').isNotEmpty) parts.add('Студия ${r.studio}');
    if ((r.author ?? '').isNotEmpty) parts.add('автор ${r.author}');
    if ((r.director ?? '').isNotEmpty) parts.add('режиссёр ${r.director}');
    return parts.join(', ');
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 19, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(child: Text(text,
            style: const TextStyle(fontSize: 14.5, color: AppColors.textSecondary, height: 1.35))),
      ]),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.surface.withOpacity(0.9),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(width: 44, height: 44,
            child: Icon(icon, color: AppColors.textPrimary, size: 22)),
      ),
    );
  }
}
