import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../home/home_screen.dart';
import '../root.dart';
import '../widgets.dart';

/// Коллекции, содержащие релиз («Показать в коллекциях N»).
class ReleaseCollectionsScreen extends StatelessWidget {
  final Release release;
  const ReleaseCollectionsScreen({super.key, required this.release});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Коллекции',
      body: PagedScroll<Collection>(
        loader: (page) => Api.I.collectionsOfRelease(release.id, page),
        itemBuilder: (context, c, __) => CollectionCard(
          collection: c,
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CollectionDetailScreen(collection: c))),
        ),
      ),
    );
  }
}

/// Карточка коллекции: обложка, название, автор, избранное.
class CollectionDetailScreen extends StatefulWidget {
  final Collection collection;
  const CollectionDetailScreen({super.key, required this.collection});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  late Collection _collection;

  @override
  void initState() {
    super.initState();
    _collection = widget.collection;
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final c = await Api.I.collection(widget.collection.id);
      if (mounted) setState(() => _collection = c);
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    if (!Api.I.isAuthorized) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Войдите в аккаунт')));
      return;
    }
    try {
      if (_collection.isFavorite == true) {
        await Api.I.collectionFavoriteDelete(_collection.id);
        setState(() => _collection = _copy(_collection, false, _collection.favoriteCount - 1));
      } else {
        await Api.I.collectionFavoriteAdd(_collection.id);
        setState(() => _collection = _copy(_collection, true, _collection.favoriteCount + 1));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Collection _copy(Collection c, bool fav, int favCount) => Collection(
      id: c.id, title: c.title, description: c.description, image: c.image,
      creator: c.creator, isPrivate: c.isPrivate, isFavorite: fav,
      isDeleted: c.isDeleted, favoriteCount: favCount, commentCount: c.commentCount,
      creationDate: c.creationDate, lastUpdateDate: c.lastUpdateDate);

  @override
  Widget build(BuildContext context) {
    final c = _collection;
    return PageScaffold(
      title: c.title ?? 'Коллекция',
      actions: [
        IconButton(
            icon: Icon(
                c.isFavorite == true ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: c.isFavorite == true ? AppColors.statPlans : AppColors.textSecondary),
            onPressed: _toggleFavorite),
      ],
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(imageUrl: c.image ?? '', width: 92, height: 92,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(width: 92, height: 92, color: AppColors.surface)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if ((c.description ?? '').isNotEmpty)
                Text(c.description!,
                    style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
                    maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [
                Text('автор ${c.creator?.login ?? '—'}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                const SizedBox(width: 12),
                Icon(Icons.bookmark_border_rounded, size: 15, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text('${c.favoriteCount}', style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
              ]),
            ])),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: PagedScroll<Release>(
            loader: (page) => Api.I.collectionReleases(c.id, page),
            itemBuilder: (_, r, __) => ReleaseListItem(
                release: r,
                onTap: () => Navigator.pushNamed(context, Routes.release,
                    arguments: ReleaseArgs(release: r))),
          ),
        ),
      ]),
    );
  }
}
