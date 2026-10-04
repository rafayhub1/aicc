import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';

class WakingBanner extends StatefulWidget {
  const WakingBanner({super.key, required this.active});

  final bool active;

  @override
  State<WakingBanner> createState() => _WakingBannerState();
}

class _WakingBannerState extends State<WakingBanner> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant WakingBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _sync();
  }

  void _sync() {
    _timer?.cancel();
    if (!widget.active) {
      if (_visible) setState(() => _visible = false);
      return;
    }
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted && widget.active) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _visible
          ? Container(
              key: const ValueKey('waking'),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: const Text(
                'Waking up the university server. The first request after a pause can take about a minute.',
                style: TextStyle(color: AppColors.primary, height: 1.35),
              ),
            )
          : const SizedBox(key: ValueKey('idle'), width: 0, height: 0),
    );
  }
}
