import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/routes.dart';
import 'core/theme.dart';
import 'core/transitions.dart';
import 'providers/session_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/firebase_setup_screen.dart';
import 'screens/shell/main_shell.dart';
import 'screens/splash_screen.dart';
import 'services/activity_service.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/chat_repository.dart';
import 'services/faculty_repository.dart';

class AiccApp extends StatelessWidget {
  const AiccApp({
    super.key,
    required this.firebaseReady,
    required this.preferences,
  });

  final bool firebaseReady;
  final SharedPreferences preferences;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: preferences),
        Provider(create: (_) => AuthService()),
        Provider(
          create: (context) => ApiService(
            context.read<SharedPreferences>(),
            tokenProvider: () async {
              return context.read<AuthService>().currentUser?.getIdToken();
            },
          ),
        ),
        Provider(create: (_) => ActivityService()),
        Provider(create: (_) => ChatRepository()),
        Provider(create: (_) => FacultyRepository()),
        ChangeNotifierProvider(
          create: (context) => SessionProvider(api: context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(context.read<SharedPreferences>()),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'AICC',
            debugShowCheckedModeBanner: false,
            navigatorKey: appNavigatorKey,
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: theme.mode,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: _onGenerateRoute,
          );
        },
      ),
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      AppRoutes.setup => const FirebaseSetupScreen(),
      AppRoutes.login => LoginScreen(
          onSignupTap: () => appNavigatorKey.currentState?.pushNamed(AppRoutes.signup),
        ),
      AppRoutes.signup => SignupScreen(onLoginTap: _openLogin),
      AppRoutes.home => const MainShell(),
      AppRoutes.admin => const AdminShell(),
      _ => SplashScreen(firebaseReady: firebaseReady),
    };
    return fadeSlideRoute(page, settings: settings);
  }

  void _openLogin() {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(AppRoutes.login);
    }
  }
}
