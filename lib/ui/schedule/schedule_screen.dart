import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../home/home_screen.dart';
import '../root.dart';
import '../widgets.dart';

/// Расписание (screenshot 14): подсказка + секции дней с горизонтальными рядами.
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Расписание',
      body: FutureBuilder<ScheduleData>(
        future: Api.I.schedule(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.textSecondary));
          }
          if (snap.hasError) return ErrorCentered(message: '${snap.error}');
          final data = snap.data!;
          return ListView(padding: const EdgeInsets.only(top: 6, bottom: 16), children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.outline),
                  borderRadius: BorderRadius.circular(14)),
              child: Text(
                'В расписании указаны дни недели, в которые выходят новые серии в Японии и Китае. Уже переведенные серии в озвучке и субтитрах появляются позже.',
                style: TextStyle(fontSize: 13.5, color: AppColors.textTertiary.withOpacity(0.9), height: 1.45)),
            ),
            for (final day in [1,2,3,4,5,6,7]) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 4),
                child: Text(_dayName(day), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              SizedBox(
                height: 218,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: (data.byDay[day] ?? []).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final r = data.byDay[day]![i];
                    return SizedBox(
                      width: 112,
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, Routes.release,
                            arguments: ReleaseArgs(release: r)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Poster(url: r.image, width: 112, height: 160),
                          const SizedBox(height: 8),
                          Text(r.titleRu ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13.5, height: 1.25)),
                          const SizedBox(height: 3),
                          Text(r.episodesLabel,
                              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ]);
        },
      ),
    );
  }

  String _dayName(int d) => const ['Понедельник','Вторник','Среда','Четверг','Пятница','Суббота','Воскресенье'][d-1];
}
