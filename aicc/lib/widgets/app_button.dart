import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';

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
    final enabled = onPressed != null && !loading;
    final background = switch (variant) {
      AppButtonVariant.primary => AppColors.primary,
      AppButtonVariant.secondary => Colors.white,
      AppButtonVariant.danger => AppColors.danger,
    };
    final foreground = switch (variant) {
      AppButtonVariant.secondary => AppColors.primary,
      _ => Colors.white,
    };
    final border = variant == AppButtonVariant.secondary
        ? BorderSide(color: AppColors.primary.withValues(alpha: 0.35))
        : BorderSide.none;

    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: foreground,
              ),
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
