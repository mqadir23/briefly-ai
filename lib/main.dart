// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'services/api_service.dart';

// ── Screens  (uncomment one at a time as you build them) ────────────────────
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar, light icons
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:            Colors.transparent,
    statusBarIconBrightness:   Brightness.light,
    statusBarBrightness:       Brightness.dark,
  ));

  runApp(const BrieflyApp());
  // TEMP TEST — remove after checking
  final reachable = await ApiService.instance.isBackendReachable();
  debugPrint('Backend reachable: $reachable');
}

class BrieflyApp extends StatelessWidget {
  const BrieflyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                    AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme:                    AppTheme.darkTheme,
      initialRoute:             '/splash',

      // ── Add each route as you build the screen ──────────
      routes: {
        '/splash':     (_) => const SplashScreen(),

        // Uncomment as you go:
       '/onboarding': (_) => const OnboardingScreen(),
        '/home':       (_) => const HomeScreen(),
        '/chat':       (_) => const ChatScreen(),
        '/analytics':  (_) => const AnalyticsScreen(),
        '/history':    (_) => const HistoryScreen(),
        '/settings':   (_) => const SettingsScreen(),
      },
    );
  }
}