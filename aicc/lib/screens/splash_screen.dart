import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/brand_loading.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  String _status = 'Starting up…';

  @override
  void initState() {
    super.initState();
    _openNext();
  }

  Future<void> _openNext() async {
    final auth = context.read<AuthService>();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _status = 'Connecting to campus services…');
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _status = 'Checking your session…');
    final restored = await auth.authState().first.timeout(
      const Duration(seconds: 4),
      onTimeout: () => auth.currentUser,
    );
    if (!mounted) return;
    var destination = AppRoutes.login;
    if (!widget.firebaseReady) {
      destination = AppRoutes.setup;
    } else if (restored != null) {
      final admin = await auth.isAdmin(restored);
      if (!mounted) return;
      destination = admin ? AppRoutes.admin : AppRoutes.home;
    }
    final next = destination;
    Navigator.of(context).pushReplacementNamed(next);
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _intro, curve: Curves.easeOutBack);
    final fade = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    final glow = Tween<double>(begin: 0.92, end: 1.06).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    return Scaffold(
      body: SplashBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: fade,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.88, end: 1).animate(scale),
                    child: AnimatedBuilder(
                      animation: glow,
                      builder: (context, child) {
                        return Transform.scale(scale: glow.value, child: child);
                      },
                      child: const AppLogoHero(logoSize: 112),
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: fade,
                  child: Column(
                    children: [
                      const BrandLoadingIndicator(size: 48, light: true),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _status,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.muted.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
