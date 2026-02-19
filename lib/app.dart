import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/mode_selection/mode_selection_screen.dart';
import 'features/about/about_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/terms/terms_screen.dart';
import 'features/privacy/privacy_screen.dart';
import 'features/balance/balance_screen.dart';
import 'features/subscription/subscription_screen.dart';
import 'shared/navigation/dc_page_route.dart';

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
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    Widget page;
    
    switch (settings.name) {
      case Routes.splash:
        page = const SplashScreen();
        break;
      case Routes.modeSelection:
        page = const ModeSelectionScreen();
        break;
      case Routes.about:
        page = const AboutScreen();
        break;
      case Routes.profile:
        page = const ProfileScreen();
        break;
      case Routes.terms:
        page = const TermsScreen();
        break;
      case Routes.privacy:
        page = const PrivacyScreen();
        break;
      case Routes.balance:
        page = const BalanceScreen();
        break;
      case Routes.subscription:
        page = const SubscriptionScreen();
        break;
      default:
        page = const SplashScreen();
    }

    return DCPageRoute(page: page);
  }
}

/// Названия маршрутов
abstract class Routes {
  static const String splash = '/';
  static const String modeSelection = '/mode-selection';
  static const String about = '/about';
  static const String profile = '/profile';
  static const String terms = '/terms';
  static const String privacy = '/privacy';
  static const String balance = '/balance';
  static const String subscription = '/subscription';
  static const String openChat = '/chat/open';
  static const String practice = '/chat/practice';
  static const String understanding = '/chat/understanding';
  static const String reflection = '/chat/reflection';
}
