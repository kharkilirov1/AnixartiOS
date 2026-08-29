import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../filter/filter_screen.dart';
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
  FilterRequest? _myTabFilter;

  @override
  void initState() {
    super.initState();
    _loadMyTab();
  }

  /// «Моя вкладка» — сохранённый фильтр (как кастомная вкладка в оригинале).
  Future<void> _loadMyTab() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('my_tab_filter');
    if (raw != null && mounted) {
      setState(() {
        _myTabFilter = FilterRequest.fromJson(
            (const JsonDecoder().convert(raw)) as Map<String, dynamic>);
      });
    }
  }

  Future<void> _saveMyTab(FilterRequest f) async {
    _myTabFilter = f;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('my_tab_filter', const JsonEncoder().convert(f.toJson()));
    setState(() => _tab = 0);
  }

  FilterRequest? _filterFor(int tab) {
    if (tab == 0) {
      if (_myTabFilter == null) return null;
      final f = FilterRequest.fromJson(_myTabFilter!.toJson());
      f.sort ??= 0;
      return f;
    }
    final f = FilterRequest()..sort = 0;
    switch (tab) {
      case 2: f.statusId = 2; break;  // Онгоинги
      case 3: f.statusId = 3; break;  // Анонсы
      case 4: f.statusId = 1; break;  // Завершенные
      default: break;                 // Последнее
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
          child: _tab == 0 && _myTabFilter == null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Настройте свою вкладку через Фильтр',
                        style: TextStyle(fontSize: 14.5, color: AppColors.textTertiary)),
                    const SizedBox(height: 14),
                    LightPillButton(
                        label: 'Открыть Фильтр',
                        onTap: () async {
                          final f = await Navigator.push<FilterRequest>(
                              context, MaterialPageRoute(builder: (_) => const FilterScreen()));
                          if (f != null) await _saveMyTab(f);
                        }),
                  ]),
                )
              : PagedScroll<Release>(
                  key: ValueKey(_tab),
                  loader: (page) => Api.I.filter(page, _filterFor(_tab)!),
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
