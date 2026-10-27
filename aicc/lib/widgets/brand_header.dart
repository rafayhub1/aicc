import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'app_logo.dart';

class AppScreenTitle extends StatelessWidget {
  const AppScreenTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogoMark(size: 28, variant: AppLogoVariant.onLight),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ),
      ],
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showLogo = true,
  });

  final String title;
  final String subtitle;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLogo) ...[
          Row(
            children: [
              AppLogoMark(
                size: 52,
                variant: AppLogoVariant.onBrand,
                showGlow: true,
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AICC',
                    style: AppTextStyles.title.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'LGU campus companion',
                    style: AppTextStyles.muted.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(title, style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTextStyles.muted.copyWith(fontSize: 15),
        ),
      ],
    );
  }
}
