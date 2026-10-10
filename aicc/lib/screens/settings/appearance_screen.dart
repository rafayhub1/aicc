import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_card.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<ThemeProvider>().mode;
    final palette = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Choose how AICC looks on this phone.',
            style: AppTextStyles.body.copyWith(color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ModeCard(
            mode: ThemeMode.system,
            selected: selected,
            title: 'System default',
            subtitle: 'Match the light or dark setting on your phone.',
            icon: Icons.phone_android_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ModeCard(
            mode: ThemeMode.light,
            selected: selected,
            title: 'Light',
            subtitle: 'Bright surfaces and navy headings.',
            icon: Icons.light_mode_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ModeCard(
            mode: ThemeMode.dark,
            selected: selected,
            title: 'Dark',
            subtitle: 'Dim surfaces for late study sessions.',
            icon: Icons.dark_mode_rounded,
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final ThemeMode mode;
  final ThemeMode selected;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final active = mode == selected;
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      color: active ? scheme.primary.withValues(alpha: 0.12) : palette.card,
      onTap: () => context.read<ThemeProvider>().setMode(mode),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label.copyWith(fontSize: 16, color: palette.ink)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.muted.copyWith(color: palette.muted)),
              ],
            ),
          ),
          if (active) Icon(Icons.check_circle_rounded, color: scheme.primary),
        ],
      ),
    );
  }
}
