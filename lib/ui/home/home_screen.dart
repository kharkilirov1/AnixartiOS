import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../root.dart';
import '../widgets.dart';

/// Главная (screenshot 01): search bar, tabs
/// Моя вкладка / Последнее / Онгоинги / Анонсы / Завершенные, release list.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 1; // "Последнее" active by default, like the app

  FilterRequest _filterFor(int tab) {
    final f = FilterRequest()..sort = 0;
    switch (tab) {
      case 2: f.statusId = 2; break;  // Онгоинги
      case 3: f.statusId = 3; break;  // Анонсы
      case 4: f.statusId = 1; break;  // Завершенные
      default: break;                 // Последнее / Моя вкладка
    }
    return f;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(children: [
        TopBar(
          searchHint: 'Поиск аниме',
          onSearch: () => Navigator.pushNamed(context, Routes.search),
        ),
        UnderlineTabs(
          tabs: const ['Моя вкладка', 'Последнее', 'Онгоинги', 'Анонсы', 'Завершенные'],
          selected: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        Expanded(
          child: PagedScroll<Release>(
            key: ValueKey(_tab),
            loader: (page) => Api.I.filter(page, _filterFor(_tab)),
            itemBuilder: (_, r, __) => ReleaseListItem(
              release: r,
              onTap: () => Navigator.pushNamed(context, Routes.release,
                  arguments: ReleaseArgs(release: r)),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Arguments passed to the release screen.
class ReleaseArgs {
  final Release? release;
  final int? releaseId;
  ReleaseArgs({this.release, this.releaseId});
}
