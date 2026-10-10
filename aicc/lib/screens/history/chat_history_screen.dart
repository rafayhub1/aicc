import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/transitions.dart';
import '../../models/chat_session.dart';
import '../../services/api_exception.dart';
import '../../services/chat_repository.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/skeleton.dart';
import '../chat/chat_screen.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<ChatSession>? _sessions;
  Object? _error;
  bool _loading = true;
  final Set<String> _selected = {};

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
      final sessions = await context.read<ChatRepository>().listSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _selected.removeWhere((id) => sessions.every((session) => session.id != id));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteIds(Set<String> ids) async {
    final repo = context.read<ChatRepository>();
    try {
      await repo.deleteSessions(ids);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeError(error))),
      );
      await _load();
      return;
    }
    if (!mounted) return;
    setState(() {
      _sessions = _sessions?.where((session) => !ids.contains(session.id)).toList();
      _selected.clear();
    });
  }

  Future<void> _clearAll() async {
    final sessions = _sessions;
    if (sessions == null || sessions.isEmpty) return;
    final confirmed = await confirmAction(
      context,
      title: 'Clear all chats?',
      message: 'This removes every saved conversation from this account.',
      confirmLabel: 'Clear all',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    await _deleteIds(sessions.map((session) => session.id).toSet());
  }

  void _scheduleDelete(ChatSession session, int index) {
    final sessions = _sessions;
    if (sessions == null) return;
    final repo = context.read<ChatRepository>();
    setState(() => sessions.removeAt(index));
    var undone = false;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: const Text('Conversation deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                undone = true;
                setState(() => _sessions?.insert(index, session));
              },
            ),
          ),
        )
        .closed
        .then((_) async {
      if (undone) return;
      try {
        await repo.deleteSession(session.id);
      } catch (error) {
        if (!mounted) return;
        setState(() {
          final current = _sessions;
          if (current == null) return;
          if (current.any((item) => item.id == session.id)) return;
          final insertAt = index.clamp(0, current.length);
          current.insert(insertAt, session);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(describeError(error))),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _sessions == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SkeletonBox(height: 72),
            SizedBox(height: 12),
            SkeletonBox(height: 72),
            SizedBox(height: 12),
            SkeletonBox(height: 72),
          ],
        ),
      );
    }
    if (_error != null && _sessions == null) {
      return ErrorState(message: describeError(_error!), onRetry: _load);
    }
    final sessions = _sessions ?? const <ChatSession>[];
    if (sessions.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        title: 'No conversations yet',
        message: 'Start a new chat from the menu. Finished chats show up here.',
      );
    }

    final grouped = <String, List<ChatSession>>{};
    for (final session in sessions) {
      grouped.putIfAbsent(_bucket(session.createdAt), () => []).add(session);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(
            children: [
              if (_selected.isNotEmpty) ...[
                TextButton(
                  onPressed: () => setState(_selected.clear),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => _deleteIds(Set.of(_selected)),
                  child: Text('Delete ${_selected.length}'),
                ),
              ] else
                const Spacer(),
              if (_selected.isEmpty)
                TextButton(
                  onPressed: _clearAll,
                  child: Text('Clear all', style: AppTextStyles.label.copyWith(color: AppColors.danger)),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                for (final label in ['Today', 'Yesterday', 'Earlier'])
                  if (grouped[label]?.isNotEmpty ?? false) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(
                        label,
                        style: AppTextStyles.label.copyWith(color: context.palette.muted),
                      ),
                    ),
                    for (final session in grouped[label]!)
                      _SessionTile(
                        session: session,
                        selected: _selected.contains(session.id),
                        selecting: _selected.isNotEmpty,
                        onTap: () {
                          if (_selected.isNotEmpty) {
                            setState(() {
                              if (!_selected.add(session.id)) _selected.remove(session.id);
                            });
                            return;
                          }
                          Navigator.of(context).push(
                            fadeSlideRoute<void>(
                              ChatScreen(
                                sessionId: session.id,
                                readOnly: true,
                              ),
                            ),
                          );
                        },
                        onLongPress: () => setState(() => _selected.add(session.id)),
                        onDismissed: () {
                          final index = sessions.indexWhere((item) => item.id == session.id);
                          if (index >= 0) _scheduleDelete(session, index);
                        },
                      ),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _bucket(DateTime time) {
    final local = time.toLocal();
    final now = DateTime.now();
    final day = DateTime(local.year, local.month, local.day);
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return 'Earlier';
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.selected,
    required this.selecting,
    required this.onTap,
    required this.onLongPress,
    required this.onDismissed,
  });

  final ChatSession session;
  final bool selected;
  final bool selecting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final tile = Card(
      elevation: 0,
      color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.16) : context.palette.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: Icon(
          selected ? Icons.check_circle_rounded : Icons.chat_bubble_outline_rounded,
          color: AppColors.primary,
        ),
        title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(relativeTime(session.createdAt)),
      ),
    );
    if (selecting) return Padding(padding: const EdgeInsets.only(bottom: 8), child: tile);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(session.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        onDismissed: (_) => onDismissed(),
        child: tile,
      ),
    );
  }
}
