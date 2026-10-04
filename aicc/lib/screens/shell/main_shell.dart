import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../providers/session_provider.dart';
import '../../services/activity_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/inbox_service.dart';
import '../../widgets/confirm_dialog.dart';
import '../chat/chat_screen.dart';
import '../history/chat_history_screen.dart';
import '../home/home_screen.dart';
import '../navigation/indoor_navigation_screen.dart';
import '../notifications/notifications_screen.dart';
import '../teachers/teachers_screen.dart';

enum ShellTab { home, chat, history, notifications, teachers, map }

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  ShellTab _tab = ShellTab.home;
  int _chatKey = 0;
  int _unread = 0;
  SessionProvider? _session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _session = context.read<SessionProvider>();
      _session!.addListener(_onSession);
      final user = context.read<AuthService>().currentUser;
      if (user != null) _session!.bind(user);
    });
  }

  @override
  void dispose() {
    _session?.removeListener(_onSession);
    super.dispose();
  }

  void _onSession() {
    if (_session?.student != null) _refreshUnread();
  }

  Future<void> _refreshUnread() async {
    final student = _session?.student;
    if (student == null || !mounted) return;
    try {
      final items = await InboxService(
        api: context.read<ApiService>(),
        activity: context.read<ActivityService>(),
      ).load(studentId: student.id);
      if (!mounted) return;
      setState(() => _unread = items.where((item) => !item.read).length);
    } catch (_) {}
  }

  void _select(ShellTab tab) {
    setState(() {
      if (tab == ShellTab.chat) _chatKey += 1;
      _tab = tab;
    });
    if (tab == ShellTab.notifications) {
      Future<void>.delayed(const Duration(milliseconds: 400), _refreshUnread);
    }
  }

  Future<void> _logout() async {
    final confirmed = await confirmAction(
      context,
      title: 'Log out?',
      message: 'You will need your registration number and password to sign in again.',
      confirmLabel: 'Log out',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await context.read<ActivityService>().log('logout');
    } catch (_) {}
    if (!mounted) return;
    context.read<SessionProvider>().clear();
    await context.read<AuthService>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final student = session.student;
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              _DrawerHeader(
                name: student?.name ?? 'Student',
                registration: student?.registrationNumber ?? '',
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _item(ShellTab.home, Icons.home_rounded, 'Home'),
                    _item(ShellTab.chat, Icons.forum_rounded, 'New Chat'),
                    _item(ShellTab.history, Icons.history_rounded, 'Chat History'),
                    _item(
                      ShellTab.notifications,
                      Icons.notifications_rounded,
                      'Notifications',
                      badge: _unread,
                    ),
                    _item(ShellTab.teachers, Icons.groups_rounded, 'Teacher Tracking'),
                    _item(ShellTab.map, Icons.map_rounded, 'Indoor Navigation'),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                title: const Text(
                  'Log Out',
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: switch (_tab) {
        ShellTab.home => HomeScreen(
            onNewChat: () => _select(ShellTab.chat),
            onTeachers: () => _select(ShellTab.teachers),
            onNotifications: () => _select(ShellTab.notifications),
          ),
        ShellTab.chat => ChatScreen(key: ValueKey(_chatKey), embedded: true),
        ShellTab.history => const ChatHistoryScreen(),
        ShellTab.notifications => NotificationsScreen(onChanged: _refreshUnread),
        ShellTab.teachers => const TeachersScreen(),
        ShellTab.map => const IndoorNavigationScreen(),
      },
    );
  }

  String get _title => switch (_tab) {
        ShellTab.home => 'Home',
        ShellTab.chat => 'New Chat',
        ShellTab.history => 'Chat History',
        ShellTab.notifications => 'Notifications',
        ShellTab.teachers => 'Teacher Tracking',
        ShellTab.map => 'Indoor Navigation',
      };

  Widget _item(ShellTab tab, IconData icon, String label, {int badge = 0}) {
    final selected = _tab == tab;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: selected,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
        leading: Icon(icon, color: selected ? AppColors.primary : AppColors.muted),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.ink,
          ),
        ),
        trailing: badge > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              )
            : null,
        onTap: () {
          Navigator.pop(context);
          _select(tab);
        },
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.name, required this.registration});

  final String name;
  final String registration;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Text(
              initials(name),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (registration.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              registration,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
            ),
          ],
        ],
      ),
    );
  }
}
