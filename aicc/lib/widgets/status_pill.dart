import 'package:flutter/material.dart';

import '../core/theme.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? colorForStatus(label);
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(color: tone, fontSize: 12),
        ),
      ),
    );
  }
}

Color colorForStatus(String label) {
  switch (label.toLowerCase()) {
    case 'in office':
    case 'available':
    case 'ready':
      return AppColors.accent;
    case 'in class':
      return AppColors.primaryLight;
    case 'pending':
    case 'on leave':
      return AppColors.warning;
    case 'unavailable':
    case 'left university':
      return AppColors.danger;
    default:
      return AppColors.muted;
  }
}
