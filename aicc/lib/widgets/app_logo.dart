import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Vector AICC mark: campus pin + navigation arc on brand gradient.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({
    super.key,
    required this.size,
    this.showGlow = false,
    this.variant = AppLogoVariant.onBrand,
  });

  final double size;
  final bool showGlow;
  final AppLogoVariant variant;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AppLogoMarkPainter(variant: variant, showGlow: showGlow),
      ),
    );
  }
}

enum AppLogoVariant { onBrand, onLight, onDark }

class _AppLogoMarkPainter extends CustomPainter {
  _AppLogoMarkPainter({required this.variant, required this.showGlow});

  final AppLogoVariant variant;
  final bool showGlow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final radius = w * 0.24;

    if (showGlow) {
      final glow = Paint()
        ..color = AppColors.accent.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(w * 0.06), Radius.circular(radius * 1.1)),
        glow,
      );
    }

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: switch (variant) {
          AppLogoVariant.onLight => [Colors.white, const Color(0xFFF4F8FC)],
          _ => [AppColors.primary, AppColors.primaryLight],
        },
      ).createShader(rect);

    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), bgPaint);

    if (variant == AppLogoVariant.onLight) {
      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.025
        ..color = AppColors.primary.withValues(alpha: 0.12);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), border);
    }

    final ink = switch (variant) {
      AppLogoVariant.onLight => AppColors.primary,
      _ => Colors.white,
    };

    final cx = w * 0.5;
    final top = h * 0.22;
    final bottom = h * 0.78;
    final spread = w * 0.22;

    final aPath = Path()
      ..moveTo(cx, top)
      ..lineTo(cx - spread, bottom)
      ..lineTo(cx - spread * 0.55, bottom)
      ..lineTo(cx - spread * 0.18, h * 0.52)
      ..lineTo(cx + spread * 0.18, h * 0.52)
      ..lineTo(cx + spread * 0.55, bottom)
      ..lineTo(cx + spread, bottom)
      ..close();

    canvas.drawPath(
      aPath,
      Paint()
        ..color = ink
        ..style = PaintingStyle.fill,
    );

    final arcRect = Rect.fromCenter(
      center: Offset(cx, h * 0.54),
      width: spread * 1.05,
      height: spread * 0.55,
    );
    canvas.drawArc(
      arcRect,
      math.pi * 0.08,
      math.pi * 0.84,
      false,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.065
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      Offset(cx, top + h * 0.02),
      w * 0.045,
      Paint()..color = AppColors.accent,
    );

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..color = ink.withValues(alpha: 0.22);
    canvas.drawCircle(Offset(cx, h * 0.52), spread * 0.72, ring);
  }

  @override
  bool shouldRepaint(covariant _AppLogoMarkPainter oldDelegate) {
    return oldDelegate.variant != variant || oldDelegate.showGlow != showGlow;
  }
}

/// Splash / hero lockup with optional tagline.
class AppLogoHero extends StatelessWidget {
  const AppLogoHero({
    super.key,
    this.logoSize = 104,
    this.showTagline = true,
    this.lightText = true,
    this.compact = false,
  });

  final double logoSize;
  final bool showTagline;
  final bool lightText;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleColor = lightText ? Colors.white : AppColors.ink;
    final subtitleColor = lightText ? Colors.white.withValues(alpha: 0.82) : AppColors.muted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogoMark(size: logoSize, showGlow: lightText, variant: AppLogoVariant.onBrand),
        SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
        Text(
          'AICC',
          style: AppTextStyles.display.copyWith(
            color: titleColor,
            fontSize: compact ? 24 : 30,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your campus companion',
            textAlign: TextAlign.center,
            style: AppTextStyles.muted.copyWith(
              color: subtitleColor,
              fontSize: compact ? 14 : 15,
            ),
          ),
        ],
      ],
    );
  }
}
