import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';

enum UnibotMood { idle, wink, thumbsUp }

/// Animated Unibot mascot. It bobs, winks, and can give a thumbs up.
class UnibotAvatar extends StatefulWidget {
  const UnibotAvatar({
    super.key,
    required this.size,
    this.interactive = false,
    this.showName = false,
    this.mood,
  });

  final double size;
  final bool interactive;
  final bool showName;
  final UnibotMood? mood;

  @override
  State<UnibotAvatar> createState() => _UnibotAvatarState();
}

class _UnibotAvatarState extends State<UnibotAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _bob;
  Timer? _actTimer;
  UnibotMood _mood = UnibotMood.idle;
  int _beat = 0;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    if (widget.mood == null) _scheduleAct();
  }

  @override
  void didUpdateWidget(UnibotAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mood != null) {
      _actTimer?.cancel();
      _mood = widget.mood!;
    } else if (oldWidget.mood != null) {
      _mood = UnibotMood.idle;
      _scheduleAct();
    }
  }

  void _scheduleAct() {
    _actTimer?.cancel();
    _actTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted || widget.mood != null) return;
      setState(() {
        _beat += 1;
        _mood = _beat.isEven ? UnibotMood.wink : UnibotMood.thumbsUp;
      });
      _actTimer = Timer(const Duration(milliseconds: 900), () {
        if (!mounted || widget.mood != null) return;
        setState(() => _mood = UnibotMood.idle);
        _scheduleAct();
      });
    });
  }

  void _play() {
    HapticFeedback.lightImpact();
    _actTimer?.cancel();
    setState(() {
      _mood = _mood == UnibotMood.thumbsUp ? UnibotMood.wink : UnibotMood.thumbsUp;
    });
    _actTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _mood = UnibotMood.idle);
      _scheduleAct();
    });
  }

  @override
  void dispose() {
    _actTimer?.cancel();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = widget.mood ?? _mood;
    final size = widget.size;
    final face = SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _bob,
        builder: (context, child) {
          final t = _bob.value;
          return Transform.translate(
            offset: Offset(math.sin(t * math.pi) * size * 0.03, (t - 0.5) * size * 0.06),
            child: Transform.rotate(
              angle: (t - 0.5) * 0.08,
              child: child,
            ),
          );
        },
        child: _Face(size: size, mood: mood),
      ),
    );

    final bot = widget.interactive
        ? GestureDetector(
            onTap: _play,
            child: face,
          )
        : face;

    if (!widget.showName) return bot;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        bot,
        const SizedBox(height: 8),
        Text(
          'Unibot AI',
          style: AppTextStyles.title.copyWith(
            fontSize: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          'Tap me',
          style: AppTextStyles.muted.copyWith(fontSize: 12, color: context.palette.muted),
        ),
      ],
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.size, required this.mood});

  final double size;
  final UnibotMood mood;

  @override
  Widget build(BuildContext context) {
    final head = size * 0.72;
    final eye = size * 0.09;
    final winking = mood == UnibotMood.wink;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: size * 0.08,
          child: Transform.rotate(
            angle: -0.12,
            child: Container(
              width: head * 0.72,
              height: size * 0.12,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        Container(
          width: head,
          height: head,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryLight,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: head * 0.78,
              height: head * 0.78,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF7FBFF),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Eye(size: eye, closed: false),
                      SizedBox(width: eye * 0.9),
                      _Eye(size: eye, closed: winking),
                    ],
                  ),
                  SizedBox(height: size * 0.04),
                  Container(
                    width: head * 0.22,
                    height: head * 0.1,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(head)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (mood == UnibotMood.thumbsUp)
          Positioned(
            right: size * 0.02,
            bottom: size * 0.12,
            child: Container(
              padding: EdgeInsets.all(size * 0.04),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.thumb_up_rounded, color: Colors.white, size: size * 0.22),
            ),
          ),
      ],
    );
  }
}

class _Eye extends StatelessWidget {
  const _Eye({required this.size, required this.closed});

  final double size;
  final bool closed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: size,
      height: closed ? 3 : size,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}

/// Small Unibot that can be dragged around. A tap opens chat.
class UnibotShortcut extends StatefulWidget {
  const UnibotShortcut({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  State<UnibotShortcut> createState() => _UnibotShortcutState();
}

class _UnibotShortcutState extends State<UnibotShortcut> {
  static const _size = 72.0;
  Offset? _pos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pos = _pos ?? Offset(constraints.maxWidth - _size - 12, constraints.maxHeight - _size - 16);
        return Stack(
          children: [
            Positioned(
              left: pos.dx,
              top: pos.dy,
              child: GestureDetector(
                onTap: widget.onOpen,
                onPanUpdate: (details) {
                  final next = pos + details.delta;
                  setState(() {
                    _pos = Offset(
                      next.dx.clamp(0, math.max(0, constraints.maxWidth - _size)),
                      next.dy.clamp(0, math.max(0, constraints.maxHeight - _size)),
                    );
                  });
                },
                child: const SizedBox(
                  width: _size,
                  height: _size,
                  child: UnibotAvatar(size: _size),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
