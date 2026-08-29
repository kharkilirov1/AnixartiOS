import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../home/home_screen.dart';
import '../collections/collection_detail_screen.dart';
import '../root.dart';
import '../widgets.dart';

/// Закладки (screenshot 06): contextual tabs + «N ВСЕГО» + sort pill + list.
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  int _tab = 2; // Избранное active, like the app

  static const _tabs = ['Коллекции', 'История', 'Избранное', 'Смотрю', 'В планах', 'Просмотрено', 'Отложено', 'Брошено'];

  Pageable<T> _empty<T>() => Pageable<T>(code: 0, content: []);

  @override
  Widget build(BuildContext context) {
    final hint = _tabs[_tab];
    return SafeArea(
      bottom: false,
      child: Column(children: [
        TopBar(searchHint: 'Поиск в «$hint»', onSearch: () => Navigator.pushNamed(context, Routes.search)),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 22),
            itemBuilder: (context, i) {
              final active = i == _tab;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _tab = i),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_tabs[i], style: TextStyle(
                      fontSize: 15,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? AppColors.textPrimary : AppColors.textTertiary)),
                  const SizedBox(height: 6),
                  Container(height: 2.5, width: _tabs[i].length * 9.0,
                      decoration: BoxDecoration(
                          color: active ? AppColors.textPrimary : Colors.transparent,
                          borderRadius: BorderRadius.circular(2))),
                ]),
              );
            },
          ),
        ),
        Expanded(
          child: Column(children: [
            _bookmarksHeader(),
            Expanded(child: _body()),
          ]),
        ),
      ]),
    );
  }

  /// Хедер «ВСЕГО · По добавл. ▼ · Шаффл» (эталон: скриншот 06).
  Widget _bookmarksHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      child: Row(children: [
        const Text('ВСЕГО', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700,
            color: AppColors.textTertiary, letterSpacing: 0.5)),
        const SizedBox(width: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.reorder, size: 15, color: AppColors.textSecondary),
            SizedBox(width: 8),
            Text('По добавл.', style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 17, color: AppColors.textSecondary),
          ]),
        ),
        const Spacer(),
        IconButton(icon: const Icon(Icons.shuffle, size: 20, color: AppColors.textSecondary),
            onPressed: () {}),
      ]),
    );
  }

  Widget _body() {
    if (!Api.I.isAuthorized) {
      return const Center(
          child: Text('Войдите в аккаунт, чтобы видеть закладки',
              style: TextStyle(color: AppColors.textTertiary)));
    }
    switch (_tab) {
      case 0:
        return PagedScroll<Collection>(
          loader: (page) => Api.I.collections(page),
          itemBuilder: (_, c, __) => CollectionCard(collection: c, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CollectionDetailScreen(collection: c)))),
        );
      case 1:
        return PagedScroll<Release>(
          loader: (page) => Api.I.history(page),
          itemBuilder: (_, r, __) => ReleaseListItem(release: r,
              onTap: () => Navigator.pushNamed(context, Routes.release,
                  arguments: ReleaseArgs(release: r))),
        );
      case 2:
        return PagedScroll<Release>(
          loader: (page) => Api.I.favorites(page),
          itemBuilder: (_, r, __) => ReleaseListItem(release: r,
              onTap: () => Navigator.pushNamed(context, Routes.release,
                  arguments: ReleaseArgs(release: r))),
        );
      default:
        final status = ProfileListStatus.values[_tab - 3];
        return PagedScroll<Release>(
          loader: (page) => Api.I.profileList(status, page),
          itemBuilder: (_, r, __) => ReleaseListItem(release: r,
              onTap: () => Navigator.pushNamed(context, Routes.release,
                  arguments: ReleaseArgs(release: r))),
        );
    }
  }
}

/// Large banner-style collection card (screenshot 17).
class CollectionCard extends StatelessWidget {
  final Collection collection;
  final VoidCallback? onTap;
  const CollectionCard({super.key, required this.collection, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        height: 190,
        child: Stack(fit: StackFit.expand, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(collection.image ?? '', fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppColors.surface)),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)]),
              ),
            ),
          ),
          Positioned(
            top: 10, right: 10,
            child: Row(children: [
              _CounterPill(icon: Icons.chat_bubble_outline, value: '${collection.commentCount}'),
              const SizedBox(width: 8),
              _CounterPill(icon: Icons.bookmark_border_rounded, value: '${collection.favoriteCount}'),
            ]),
          ),
          Positioned(
            left: 14, right: 14, bottom: 12,
            child: Text(collection.title ?? '',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }
}

class _CounterPill extends StatelessWidget {
  final IconData icon;
  final String value;
  const _CounterPill({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Icon(icon, size: 15, color: Colors.white),
      ]),
    );
  }
}
