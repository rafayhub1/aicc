import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import 'brand_loading.dart';

enum AppButtonVariant { primary, secondary, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    final enabled = onPressed != null && !loading;
    final background = switch (variant) {
      AppButtonVariant.primary => scheme.primary,
      AppButtonVariant.secondary => palette.card,
      AppButtonVariant.danger => AppColors.danger,
    };
    final foreground = switch (variant) {
      AppButtonVariant.secondary => scheme.primary,
      _ => Colors.white,
    };
    final border = variant == AppButtonVariant.secondary
        ? BorderSide(color: scheme.primary.withValues(alpha: 0.35))
        : BorderSide.none;

    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: loading
          ? BrandLoadingIndicator(
              key: const ValueKey('loading'),
              size: 26,
              light: variant != AppButtonVariant.secondary,
              showOrbit: false,
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    );

    final button = ElevatedButton(
      onPressed: enabled
          ? () {
              HapticFeedback.lightImpact();
              onPressed!();
            }
          : null,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: 0.45),
        disabledForegroundColor: foreground.withValues(alpha: 0.8),
        minimumSize: Size(expand ? double.infinity : 48, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          side: border,
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      child: child,
    );

    return Semantics(button: true, label: label, child: button);
  }
}
