import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'app_button.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, color: AppColors.danger, size: 32),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Something needs attention',
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.muted.copyWith(fontSize: 15, color: context.palette.muted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              AppButton(label: 'Try again', icon: Icons.refresh_rounded, onPressed: onRetry, expand: false),
            ],
          ],
        ),
      ),
    );
  }
}
