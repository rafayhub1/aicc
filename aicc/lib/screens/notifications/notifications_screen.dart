import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/inbox_item.dart';
import '../../providers/session_provider.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../services/inbox_service.dart';
import '../../widgets/document_webview.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/waking_banner.dart';

enum _Filter { all, unread, documents }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<InboxItem>? _items;
  Object? _error;
  bool _loading = true;
  _Filter _filter = _Filter.all;
  String? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final student = context.read<SessionProvider>().student;
    if (student != null && _loadedFor != student.id) {
      _loadedFor = student.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  InboxService get _inbox => InboxService(
        api: context.read<ApiService>(),
        activity: context.read<ActivityService>(),
      );

  Future<void> _load() async {
    final student = context.read<SessionProvider>().student;
    if (student == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _inbox.load(studentId: student.id);
      if (!mounted) return;
      setState(() => _items = items);
      widget.onChanged();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(InboxItem item) async {
    final student = context.read<SessionProvider>().student;
    if (student == null) return;
    if (!item.read) {
      try {
        await _inbox.markRead(item, student.id);
        if (!mounted) return;
        setState(() {
          _items = [
            for (final current in _items ?? const <InboxItem>[])
              if (current.id == item.id && current.source == item.source)
                current.copyWith(read: true)
              else
                current,
          ];
        });
        widget.onChanged();
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(describeError(error))),
        );
      }
    }
    if (!mounted || item.documentUrl == null) return;
    openDocument(
      context,
      title: item.documentTitle ?? item.title,
      url: item.documentUrl!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    if (session.error != null && session.student == null) {
      return ErrorState(message: describeError(session.error!), onRetry: () async {
        final user = context.read<AuthService>().currentUser;
        if (user != null) await session.bind(user, force: true);
      });
    }
    final items = _visible;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              _chip('All', _Filter.all),
              const SizedBox(width: 8),
              _chip('Unread', _Filter.unread),
              const SizedBox(width: 8),
              _chip('Documents', _Filter.documents),
            ],
          ),
        ),
        WakingBanner(active: _loading),
        Expanded(child: _body(items)),
      ],
    );
  }

  List<InboxItem> get _visible {
    final items = _items ?? const <InboxItem>[];
    return switch (_filter) {
      _Filter.all => items,
      _Filter.unread => items.where((item) => !item.read).toList(),
      _Filter.documents => items.where((item) => item.isDocument || _isDocType(item.type)).toList(),
    };
  }

  bool _isDocType(String type) {
    return type == 'fee_challan_ready' || type == 'roll_slip_ready';
  }

  Widget _body(List<InboxItem> items) {
    if (_loading && _items == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SkeletonBox(height: 78),
            SizedBox(height: 10),
            SkeletonBox(height: 78),
          ],
        ),
      );
    }
    if (_error != null && _items == null) {
      return ErrorState(message: describeError(_error!), onRetry: _load);
    }
    if (items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 420,
              child: EmptyState(
                icon: Icons.notifications_none_rounded,
                title: _filter == _Filter.unread ? 'All caught up' : 'No notifications yet',
                message: _filter == _Filter.all
                    ? 'Fee challans, roll slips, and sign-in activity will show up here.'
                    : 'Nothing matches this filter.',
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return Material(
            color: context.palette.card,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: () => _open(item),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_iconFor(item.type), color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: AppTextStyles.label.copyWith(
                                    fontSize: 16,
                                    color: context.palette.ink,
                                  ),
                                ),
                              ),
                              if (!item.read)
                                Semantics(
                                  label: 'Unread',
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.body,
                            style: AppTextStyles.body.copyWith(fontSize: 15, color: context.palette.ink),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            relativeTime(item.time),
                            style: AppTextStyles.muted.copyWith(fontSize: 12, color: context.palette.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String label, _Filter filter) {
    final selected = _filter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = filter),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : context.palette.ink,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'fee_challan_ready' => Icons.receipt_long_rounded,
      'roll_slip_ready' => Icons.badge_rounded,
      'signup' => Icons.person_add_alt_1_rounded,
      'login' => Icons.login_rounded,
      'logout' => Icons.logout_rounded,
      'chat_completed' => Icons.forum_rounded,
      _ => Icons.notifications_rounded,
    };
  }
}
