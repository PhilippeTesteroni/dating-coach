import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/mode_selection/mode_selection_screen.dart';

/// Главный виджет приложения Dating Coach
class DatingCoachApp extends StatelessWidget {
  const DatingCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dating Coach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: Routes.splash,
      routes: {
        Routes.splash: (context) => const SplashScreen(),
        Routes.modeSelection: (context) => const ModeSelectionScreen(),
      },
    );
  }
}

/// Названия маршрутов
abstract class Routes {
  static const String splash = '/';
  static const String modeSelection = '/mode-selection';
  static const String openChat = '/chat/open';
  static const String practice = '/chat/practice';
  static const String understanding = '/chat/understanding';
  static const String reflection = '/chat/reflection';
}
