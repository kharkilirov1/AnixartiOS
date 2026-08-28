import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/api.dart';
import 'core/models.dart';
import 'core/theme.dart';
import 'ui/auth/auth_screen.dart';
import 'ui/collections/collections_screen.dart';
import 'ui/filter/filter_screen.dart';
import 'ui/home/home_screen.dart';
import 'ui/notifications/notifications_screen.dart';
import 'ui/popular/popular_screen.dart';
import 'ui/release/release_screen.dart';
import 'ui/release/voiceover_screen.dart';
import 'ui/root.dart';
import 'ui/schedule/schedule_screen.dart';
import 'ui/search/search_screen.dart';
import 'ui/settings/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  await Api.I.load();
  runApp(const AnixartApp());
}

class AnixartApp extends StatelessWidget {
  const AnixartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anixart',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      builder: (context, child) => DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: 'Roboto'),
        child: child ?? const SizedBox(),
      ),
      routes: {
        Routes.search: (_) => const SearchScreen(),
        Routes.settings: (_) => const SettingsScreen(),
        Routes.notifications: (_) => const NotificationsScreen(),
        Routes.auth: (_) => const AuthScreen(),
        Routes.schedule: (_) => const ScheduleScreen(),
        Routes.popular: (_) => const PopularScreen(),
        Routes.collections: (_) => const CollectionsScreen(),
        Routes.filter: (_) => const FilterScreen(),
      },
      onGenerateRoute: (settings) {
        final args = settings.arguments;
        switch (settings.name) {
          case Routes.release:
            return MaterialPageRoute(builder: (_) => ReleaseScreen(args: args as ReleaseArgs));
          case Routes.voiceover:
            return MaterialPageRoute(builder: (_) => VoiceoverScreen(release: args as Release));
          default:
            return null;
        }
      },
      home: const RootShell(),
    );
  }
}
