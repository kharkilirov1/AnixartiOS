import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../widgets.dart';

/// Уведомления (screenshot 10): «Все уведомления ▼» + карточки-подсказки + лента.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Уведомления',
      actions: [
        IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary), onPressed: () {}),
        IconButton(icon: const Icon(Icons.tune, color: AppColors.textSecondary), onPressed: () {}),
      ],
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.reorder, size: 18, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text('Все уведомления', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down, size: 19, color: AppColors.textSecondary),
              ]),
            ),
          ),
        ),
        Expanded(
          child: !Api.I.isAuthorized
              ? const Center(child: Text('Войдите в аккаунт, чтобы видеть уведомления',
                  style: TextStyle(color: AppColors.textTertiary)))
              : PagedScroll<Release>(
                  loader: (page) => Api.I.notificationEpisodes(page),
                  itemBuilder: (_, r, __) => ReleaseListItem(release: r),
                ),
        ),
      ]),
    );
  }
}
