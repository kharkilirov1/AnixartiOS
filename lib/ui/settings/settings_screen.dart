import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../root.dart';

/// Настройки (screenshot 09): список секций с иконками + версия.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Настройки',
      body: ListView(padding: const EdgeInsets.only(top: 4), children: [
        const Divider(color: AppColors.outline, height: 1),
        _item(context, Icons.dark_mode_outlined, 'Тёмная тема', 'Следовать настройкам системы', () {}),
        _divider(),
        _item(context, Icons.notifications_none_rounded, 'Уведомления', null, () => Navigator.pushNamed(context, Routes.notifications)),
        _item(context, Icons.play_circle_outline, 'Воспроизведение', null, () {}),
        _item(context, Icons.palette_outlined, 'Внешний вид', null, () {}),
        _item(context, Icons.cloud_upload_outlined, 'Управление данными', null, () {}),
        _item(context, Icons.more_horiz, 'Дополнительно', null, () {}),
        _divider(),
        _item(context, Icons.help_outline, 'Помощь', null, () {}),
        _item(context, Icons.verified_user_outlined, 'Правила сообщества', null, () {}),
        _item(context, Icons.error_outline, 'Проверить обновления', null, () {}),
        if (Api.I.isAuthorized)
          _item(context, Icons.logout, 'Выйти из аккаунта', null, () async {
            await Api.I.signOut();
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Вы вышли из аккаунта')));
            }
          }),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Text('Версия 1.0.0 Сборка 1',
              style: TextStyle(fontSize: 14.5, color: AppColors.textTertiary)),
        ),
      ]),
    );
  }

  Widget _divider() => const Padding(
      padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: AppColors.outline, height: 1));

  Widget _item(BuildContext context, IconData icon, String title, String? subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 24, color: AppColors.textSecondary),
          const SizedBox(width: 22),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500)),
            if (subtitle != null)
              Padding(padding: const EdgeInsets.only(top: 3),
                  child: Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.textTertiary))),
          ])),
        ]),
      ),
    );
  }
}
