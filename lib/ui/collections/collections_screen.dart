import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../widgets.dart';

/// Коллекции (screenshot 17): Создать коллекцию / Мои коллекции / сортировка.
class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Коллекции',
      actions: [IconButton(icon: const Icon(Icons.search, color: AppColors.textSecondary), onPressed: () {})],
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: SizedBox(width: double.infinity,
              child: LightPillButton(icon: Icons.add_circle_outline, label: 'Создать коллекцию')),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {},
                child: Container(height: 48, alignment: Alignment.center,
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.reorder, size: 20, color: AppColors.textPrimary),
                      SizedBox(width: 10),
                      Text('Мои коллекции', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500)),
                    ])),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
            Text('Популярные за сезон', style: TextStyle(fontSize: 14.5, color: AppColors.textSecondary)),
            SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down, size: 19, color: AppColors.textSecondary),
          ]),
        ),
        Expanded(
          child: PagedScroll<Collection>(
            loader: (page) => Api.I.collections(page),
            itemBuilder: (_, c, __) => CollectionCard(collection: c),
          ),
        ),
      ]),
    );
  }
}
