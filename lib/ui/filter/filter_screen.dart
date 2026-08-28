import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../widgets.dart';

/// Фильтр (screenshot 15): outlined dropdowns в две колонки для Года/Сезона,
/// Сбросить + Применить.
class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  String? _country, _category, _status, _sort;
  final Set<String> _genres = {};
  int? _yearFrom;

  static const _countries = ['Япония', 'Китай', 'Корея', 'США'];
  static const _categories = ['Сериал', 'Фильм', 'OVA', 'Спешл'];
  static const _statuses = ['Вышел', 'Выходит', 'Анонс'];
  static const _sorts = ['По дате обновления', 'По оценке', 'По году', 'По популярности'];

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Фильтр',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _dropdown('Страна', _country, _countries, (v) => setState(() => _country = v)),
        _dropdown('Категория', _category, _categories, (v) => setState(() => _category = v)),
        _dropdown('Жанры', _genres.isEmpty ? null : _genres.join(', '), GenresList.all,
            (_) => _pickGenres()),
        _dropdown('Статус', _status, _statuses, (v) => setState(() => _status = v)),
        _dropdown('Сортировка', _sort, _sorts, (v) => setState(() => _sort = v)),
        _dropdown('Года', _yearFrom == null ? null : 'от $_yearFrom',
            [for (var y = 2026; y >= 1960; y--) '$y'], (v) => setState(() => _yearFrom = v == null ? null : int.parse(v))),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() {
                _country = _category = _status = _sort = null; _genres.clear(); _yearFrom = null;
              }),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.outline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  padding: const EdgeInsets.symmetric(vertical: 13)),
              child: const Text('Сбросить', style: TextStyle(fontSize: 15.5)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: LightPillButton(label: 'Применить', onTap: _apply),
          ),
        ]),
      ]),
    );
  }

  Widget _dropdown(String label, String? value, List<String> items, ValueChanged<String?> onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => SafeArea(
            child: ListView(shrinkWrap: true, children: [
              for (final item in items)
                ListTile(
                  title: Text(item),
                  onTap: () { Navigator.pop(context); onTap(item); },
                ),
              ListTile(title: const Text('Неважно'), onTap: () { Navigator.pop(context); onTap(null); }),
            ]),
          ),
        ),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
            filled: true,
            fillColor: AppColors.bg,
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.outline)),
            suffixIcon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textTertiary),
          ),
          child: Text(value ?? 'Неважно', style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  void _pickGenres() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (context, setSheet) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(children: [
            Padding(padding: const EdgeInsets.all(14),
                child: Text('Жанры (${_genres.length})',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
            Expanded(
              child: ListView(
                children: [for (final g in GenresList.all)
                  CheckboxListTile(
                    value: _genres.contains(g),
                    activeColor: AppColors.accent,
                    title: Text(g),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (on) => setSheet(() {
                      on == true ? _genres.add(g) : _genres.remove(g);
                    }),
                  )],
              ),
            ),
            Padding(padding: const EdgeInsets.all(14),
                child: LightPillButton(label: 'Готово', onTap: () {
                  setState(() {});
                  Navigator.pop(context);
                })),
          ]),
        );
      }),
    );
  }

  void _apply() {
    final f = FilterRequest()..sort = 0;
    if (_category != null) f.categoryId = _categories.indexOf(_category!) + 1;
    if (_status != null) f.statusId = _statuses.indexOf(_status!) + 1;
    if (_yearFrom != null) f.startYear = _yearFrom;
    if (_genres.isNotEmpty) {
      f.genres = _genres.map((g) => g.toLowerCase()).toList();
      f.isGenresExcludeModeEnabled = false;
    }
    Navigator.pop(context, f);
  }
}

/// Genre list from the APK resources.
class GenresList {
  static const List<String> all = [
    'авангард', 'гурман', 'драма', 'комедия', 'повседневность', 'приключения', 'романтика',
    'сверхъестественное', 'спорт', 'тайна', 'триллер', 'ужасы', 'фантастика', 'фэнтези',
    'экшен', 'эротика', 'этти', 'детское', 'дзёсей', 'сэйнэн', 'сёдзё', 'сёдзё-ай', 'сёнен',
    'сёнен-ай', 'CGDCT', 'антропоморфизм', 'боевые искусства', 'вампиры', 'взрослые персонажи',
    'видеоигры', 'военное', 'выживание', 'гарем', 'гонки', 'городское фэнтези', 'гэг-юмор',
    'детектив', 'жестокость', 'забота о детях', 'злодейка', 'игра с высокими ставками',
    'идолы (жен.)', 'идолы (муж.)', 'изобразительное искусство', 'исполнительское искусство',
    'исторический', 'исэкай', 'иясикэй', 'командный спорт', 'космос', 'кроссдрессинг',
    'культура отаку', 'любовный многоугольник', 'магическая смена пола', 'махо-сёдзё',
    'медицина', 'меха', 'мифология', 'музыка', 'образовательное', 'организованная преступность',
    'пародия', 'питомцы', 'психологическое', 'путешествие во времени', 'работа',
    'реверс-гарем', 'реинкарнация', 'романтический подтекст', 'самураи',
    'спортивные единоборства', 'стратегические игры', 'супер сила', 'удостоено наград',
    'хулиганы', 'школа', 'шоу-бизнес',
  ];
}
