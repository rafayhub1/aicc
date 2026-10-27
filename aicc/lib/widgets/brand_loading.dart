import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'app_logo.dart';

/// Branded loading indicator for splash, buttons, and full-screen waits.
class BrandLoadingIndicator extends StatefulWidget {
  const BrandLoadingIndicator({
    super.key,
    this.size = 36,
    this.light = false,
    this.showOrbit = true,
  });

  final double size;
  final bool light;
  final bool showOrbit;

  @override
  State<BrandLoadingIndicator> createState() => _BrandLoadingIndicatorState();
}

class _BrandLoadingIndicatorState extends State<BrandLoadingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logo = widget.size * 0.62;
    final ringColor = widget.light ? Colors.white.withValues(alpha: 0.55) : AppColors.primary.withValues(alpha: 0.35);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.showOrbit)
            AnimatedBuilder(
              animation: _spin,
              builder: (context, child) {
                return Transform.rotate(angle: _spin.value * 6.28318, child: child);
              },
              child: CustomPaint(
                size: Size.square(widget.size),
                painter: _OrbitRingPainter(color: ringColor, accent: AppColors.accent),
              ),
            ),
          AppLogoMark(size: logo, variant: AppLogoVariant.onBrand),
        ],
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  _OrbitRingPainter({required this.color, required this.accent});

  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect.deflate(size.width * 0.08), 0.2, 4.6, false, paint);

    final dot = Paint()..color = accent;
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.5), size.width * 0.06, dot);
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) => false;
}

/// Full-screen branded loading used while session or bootstrap finishes.
class BrandLoadingScreen extends StatelessWidget {
  const BrandLoadingScreen({
    super.key,
    this.message = 'Getting things ready…',
    this.subtitle,
  });

  final String message;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFF0E4A7A), AppColors.primaryLight],
          ),
        ),
        child: Stack(
          children: [
            const _SplashOrbs(),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogoHero(logoSize: 96, compact: true),
                    const SizedBox(height: AppSpacing.xl),
                    const BrandLoadingIndicator(size: 52, light: true),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      message,
                      style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 17),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.muted.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft background orbs for splash / loading screens.
class SplashBackdrop extends StatelessWidget {
  const SplashBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, Color(0xFF0E4A7A), AppColors.primaryLight],
            ),
          ),
        ),
        const _SplashOrbs(),
        child,
      ],
    );
  }
}

class _SplashOrbs extends StatelessWidget {
  const _SplashOrbs();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _Orb(diameter: 220, color: AppColors.accent.withValues(alpha: 0.18)),
          ),
          Positioned(
            bottom: -60,
            left: -50,
            child: _Orb(diameter: 260, color: Colors.white.withValues(alpha: 0.08)),
          ),
          Positioned(
            top: 280,
            left: -70,
            child: _Orb(diameter: 160, color: AppColors.primaryLight.withValues(alpha: 0.35)),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
