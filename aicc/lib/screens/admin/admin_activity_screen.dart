import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/admin_activity.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/skeleton.dart';

class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  List<AdminActivity>? _items;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await context.read<ApiService>().listActivity();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _items == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SkeletonBox(height: 72),
            SizedBox(height: 10),
            SkeletonBox(height: 72),
            SizedBox(height: 10),
            SkeletonBox(height: 72),
          ],
        ),
      );
    }
    if (_error != null && _items == null) {
      return ErrorState(message: describeError(_error!), onRetry: _load);
    }
    final items = _items ?? const <AdminActivity>[];
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.timeline_rounded,
        title: 'No activity yet',
        message: 'Sign-ins, sign-ups, and chats show up here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final who = item.registrationNumber.isEmpty ? 'Unknown account' : item.registrationNumber;
          final when = item.timestamp == null ? 'Unknown time' : relativeTime(item.timestamp!);
          return AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(_icon(item.type), color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(who, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        '${_label(item.type)} · $when',
                        style: TextStyle(color: context.palette.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

IconData _icon(String type) {
  return switch (type) {
    'signup' => Icons.person_add_alt_1_rounded,
    'login' => Icons.login_rounded,
    'logout' => Icons.logout_rounded,
    'chat_completed' => Icons.forum_rounded,
    _ => Icons.bolt_rounded,
  };
}

String _label(String type) {
  return switch (type) {
    'signup' => 'Signed up',
    'login' => 'Signed in',
    'logout' => 'Signed out',
    'chat_completed' => 'Finished a chat',
    _ => type.replaceAll('_', ' '),
  };
}
