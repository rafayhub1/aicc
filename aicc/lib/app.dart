import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'providers/session_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/backend_check_screen.dart';
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
        Provider(create: (context) => ApiService(context.read<SharedPreferences>())),
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => ActivityService()),
        Provider(create: (_) => ChatRepository()),
        Provider(create: (_) => FacultyRepository()),
        ChangeNotifierProvider(
          create: (context) => SessionProvider(api: context.read<ApiService>()),
        ),
      ],
      child: MaterialApp(
        title: 'AICC',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: AppEntry(firebaseReady: firebaseReady),
      ),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _showSplash = true;
  bool _backendChecked = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return const SplashScreen();
    if (!widget.firebaseReady) return const FirebaseSetupScreen();
    if (!_backendChecked) {
      return BackendCheckScreen(
        onContinue: () => setState(() => _backendChecked = true),
      );
    }
    return const AuthGate();
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: context.read<AuthService>().authState(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) return const AuthFlow();
        return const MainShell();
      },
    );
  }
}

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  bool _signup = false;

  @override
  Widget build(BuildContext context) {
    if (_signup) {
      return SignupScreen(onLoginTap: () => setState(() => _signup = false));
    }
    return LoginScreen(onSignupTap: () => setState(() => _signup = true));
  }
}
