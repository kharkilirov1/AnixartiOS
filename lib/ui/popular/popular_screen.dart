import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../home/home_screen.dart';
import '../root.dart';
import '../widgets.dart';

/// Популярное (screenshot 16): табы + нумерованный список.
class PopularScreen extends StatefulWidget {
  const PopularScreen({super.key});

  @override
  State<PopularScreen> createState() => _PopularScreenState();
}

class _PopularScreenState extends State<PopularScreen> {
  int _tab = 0;
  static const _tabs = ['Онгоинги', 'Завершенные', 'Фильмы', 'OVA'];

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Популярное',
      body: Column(children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 24),
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
          child: PagedScroll<Release>(
            key: ValueKey(_tab),
            loader: (page) {
              final f = FilterRequest()..sort = 3; // SORT_POPULAR
              switch (_tab) {
                case 0: f.statusId = 2; break;
                case 1: f.statusId = 1; break;
                case 2: f.categoryId = 2; break;
                case 3: f.categoryId = 3; break;
              }
              return Api.I.filter(page, f);
            },
            itemBuilder: (context, r, index) {
              return ReleaseListItem(release: r, rank: index + 1,
                  onTap: () => Navigator.pushNamed(context, Routes.release,
                      arguments: ReleaseArgs(release: r)));
            },
          ),
        ),
      ]),
    );
  }
}
