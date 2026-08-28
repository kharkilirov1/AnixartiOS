import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../home/home_screen.dart';
import '../root.dart';
import '../widgets.dart';

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
          : Stack(children: [
              // Blurred poster backdrop
              Positioned.fill(
                child: Opacity(
                  opacity: 0.22,
                  child: CachedNetworkImage(imageUrl: r.image ?? '', fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox()),
                ),
              ),
              SafeArea(
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
                            onPressed: () {},
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
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.outline),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                padding: const EdgeInsets.symmetric(vertical: 11)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text('${r.favoriteCount}', style: const TextStyle(fontSize: 14.5)),
                              const SizedBox(width: 8),
                              const Icon(Icons.bookmark_border_rounded, size: 17),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            onPressed: () {},
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
                            onPressed: () {}),
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
                        child: Text(r.note!,
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
                        child: Text(r.description!,
                            style: const TextStyle(fontSize: 14.5, height: 1.5,
                                color: AppColors.textSecondary)),
                      ),
                  ],
                ),
              ),
            ]),
    );
  }

  String _listTitle(int? status) {
    final s = ProfileListStatus.values.where((e) => e.value == status).firstOrNull;
    return s?.title ?? 'Не смотрю';
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
