import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../home/home_screen.dart';
import '../root.dart';
import '../widgets.dart';

/// Обзор (screenshot 05): banner carousel, action pills,
/// рекомендации, обсуждаемое сегодня.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  List<Map<String, dynamic>> _banners = [];

  @override
  void initState() { super.initState(); _loadBanners(); }

  Future<void> _loadBanners() async {
    try {
      final list = await Api.I.interesting();
      if (mounted) setState(() => _banners = list.cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          TopBar(searchHint: 'Поиск аниме', onSearch: () => Navigator.pushNamed(context, Routes.search)),

          // Banners (discover/interesting)
          if (_banners.isNotEmpty)
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _banners.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final b = _banners[i];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: 310,
                      child: Stack(fit: StackFit.expand, children: [
                        CachedNetworkImage(
                            imageUrl: (b['image'] as String?) ?? '', fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(color: AppColors.surface)),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.75)]),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14, right: 14, bottom: 12,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text((b['title'] as String?) ?? '',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (((b['description'] as String?) ?? '').isNotEmpty)
                              Text((b['description'] as String?)!,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                          ]),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 14),

          // Action pills grid (2 columns)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              Row(children: [
                Expanded(child: BigPillButton(icon: Icons.local_fire_department_outlined, label: 'Популярное',
                    onTap: () => Navigator.pushNamed(context, Routes.popular))),
                const SizedBox(width: 12),
                Expanded(child: BigPillButton(icon: Icons.calendar_today_outlined, label: 'Расписание',
                    onTap: () => Navigator.pushNamed(context, Routes.schedule))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: BigPillButton(icon: Icons.reorder, label: 'Коллекции',
                    onTap: () => Navigator.pushNamed(context, Routes.collections))),
                const SizedBox(width: 12),
                Expanded(child: BigPillButton(icon: Icons.tune, label: 'Фильтр',
                    onTap: () => Navigator.pushNamed(context, Routes.filter))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: BigPillButton(icon: Icons.shuffle, label: 'Рандом',
                    onTap: () async {
                      try {
                        final r = await Api.I.randomRelease();
                        if (context.mounted) {
                          Navigator.pushNamed(context, Routes.release, arguments: ReleaseArgs(release: r));
                        }
                      } catch (_) {}
                    })),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ]),
            ]),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 26, 16, 4),
            child: Text('Рекомендации', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('На основе ваших оценок',
                style: TextStyle(fontSize: 13.5, color: AppColors.textTertiary)),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
            child: const Text(
              'Продолжайте смотреть и оценивать аниме.\nЧем честнее выставлены оценки, тем точнее будут подобраны рекомендации.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 26, 16, 8),
            child: Text('Обсуждаемое сегодня', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ),
          PagedScroll<Release>(
            loader: (page) => Api.I.discussing(page),
            itemBuilder: (_, r, __) => ReleaseListItem(
              release: r,
              onTap: () => Navigator.pushNamed(context, Routes.release,
                  arguments: ReleaseArgs(release: r)),
            ),
            header: const SizedBox(height: 1),
          ),
        ],
      ),
    );
  }
}
