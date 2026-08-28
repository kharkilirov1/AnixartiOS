import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../root.dart';
import '../widgets.dart';

/// Профиль (screenshot 07): avatar, login+level, counters row,
/// Редактировать, статистика donut, оценки релизов.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? _me;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!Api.I.isAuthorized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('my_profile_id') ?? 0;
      if (id <= 0) {
        if (mounted) setState(() => _error = 'Не удалось определить профиль');
        return;
      }
      final p = await Api.I.profile(id);
      if (mounted) setState(() => _me = p);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(children: [
        const TopBar(searchHint: 'Поиск пользователей'),
        const SizedBox(height: 8),
        if (!Api.I.isAuthorized)
          _notAuthorized()
        else if (_me != null)
          _content(_me!)
        else if (_error != null)
          ErrorCentered(message: _error!, onRetry: _load)
        else
          const Center(child: CircularProgressIndicator(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _notAuthorized() {
    return Center(
      child: Column(children: [
        const SizedBox(height: 40),
        const Text('Вы не авторизованы',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: LightPillButton(label: 'Войти', onTap: () => Navigator.pushNamed(context, Routes.auth)),
        ),
      ]),
    );
  }

  Widget _content(Profile me) {
    final stats = [
      (AppColors.statWatching, 'Смотрю', me.watchingCount ?? 0),
      (AppColors.statPlans, 'В планах', me.planCount ?? 0),
      (AppColors.statCompleted, 'Просмотрено', me.completedCount ?? 0),
      (AppColors.statHoldOn, 'Отложено', me.holdOnCount ?? 0),
      (AppColors.statDropped, 'Брошено', me.droppedCount ?? 0),
    ];
    return Column(children: [
      const SizedBox(height: 16),
      Container(
        width: 110, height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          image: (me.avatar ?? '').isNotEmpty
              ? DecorationImage(image: NetworkImage(me.avatar!), fit: BoxFit.cover)
              : null,
        ),
      ),
      const SizedBox(height: 16),
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(me.login ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.statWatching, width: 1.5),
              borderRadius: BorderRadius.circular(8)),
          child: Text('${me.privilegeLevel ?? 1}',
              style: const TextStyle(fontSize: 13, color: AppColors.statWatching)),
        ),
      ]),
      Text(me.status?.isNotEmpty == true ? me.status! : 'Статус не установлен',
          style: const TextStyle(fontSize: 14.5, color: AppColors.textSecondary)),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _counter(me.commentCount ?? 0, 'коммент.'),
        _counter(me.videoCount ?? 0, 'видео'),
        _counter(me.collectionCount ?? 0, 'коллекций'),
        _counter(me.friendCount ?? 0, 'друзей'),
      ]),
      const SizedBox(height: 22),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.outline),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                padding: const EdgeInsets.symmetric(vertical: 13)),
            child: const Text('Редактировать',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
      const SizedBox(height: 26),
      const Divider(color: AppColors.outline, height: 1),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: Row(children: [
          const Text('Статистика', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Icon(Icons.info_outline, size: 18, color: AppColors.textTertiary),
          const Spacer(),
          const Text('Показать все', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ]),
      ),
      SizedBox(
        height: 190,
        child: Row(children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final s in stats)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    child: Row(children: [
                      Container(width: 14, height: 14, color: s.$1),
                      const SizedBox(width: 10),
                      Text(s.$2, style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 8),
                      Text('${s.$3}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 170,
            child: PieChart(PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 42,
              sections: [
                for (final s in stats)
                  if (s.$3 > 0)
                    PieChartSectionData(
                        value: s.$3.toDouble(), color: s.$1, radius: 34, showTitle: false),
              ],
            )),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Просмотрено серий:  ${me.watchedEpisodeCount ?? 0}',
              style: const TextStyle(fontSize: 14.5, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('Время просмотра:  ~ ${((me.watchedTime ?? 0) / 60 / 24).toStringAsFixed(0)} дн.',
              style: const TextStyle(fontSize: 14.5, color: AppColors.textSecondary)),
        ]),
      ),
      const SizedBox(height: 18),
      const Divider(color: AppColors.outline, height: 1),
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: Row(children: [
          Text('Оценки релизов', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          Spacer(),
          Text('Показать все', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ]),
      ),
    ]);
  }

  Widget _counter(int value, String label) {
    return Column(children: [
      Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
    ]);
  }
}
