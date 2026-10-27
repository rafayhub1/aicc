import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/transitions.dart';
import '../../providers/session_provider.dart';
import '../../services/activity_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/inbox_service.dart';
import '../../services/push_service.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/unibot.dart';
import '../chat/chat_screen.dart';
import '../history/chat_history_screen.dart';
import '../home/home_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/appearance_screen.dart';
import '../teachers/teachers_screen.dart';

enum ShellTab { home, chat, history, notifications, teachers }

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
  bool _leaving = false;
  final List<StreamSubscription<RemoteMessage>> _pushSubscriptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _session = context.read<SessionProvider>();
      _session!.addListener(_onSession);
      _listenForPush();
      final user = context.read<AuthService>().currentUser;
      if (user != null) _session!.bind(user);
    });
  }

  @override
  void dispose() {
    _session?.removeListener(_onSession);
    for (final subscription in _pushSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  Future<void> _listenForPush() async {
    final push = context.read<PushService>();
    _pushSubscriptions
      ..add(push.foregroundMessages.listen(_onForegroundPush))
      ..add(push.openedMessages.listen((_) => _select(ShellTab.notifications)));
    final initial = await push.initialMessage();
    if (initial != null && mounted) _select(ShellTab.notifications);
  }

  void _onForegroundPush(RemoteMessage message) {
    if (!mounted) return;
    _refreshUnread();
    final notification = message.notification;
    if (notification == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notification.body ?? notification.title ?? 'New notification',
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _select(ShellTab.notifications),
        ),
      ),
    );
  }

  void _onSession() {
    if (!mounted || _leaving) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _leaving) return;
      if (_session?.isAdmin == true) {
        _leaving = true;
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.admin, (route) => false);
        return;
      }
      final student = _session?.student;
      if (student != null) {
        _refreshUnread();
        context.read<PushService>().register(student.id);
      }
    });
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
    await context.read<PushService>().unregister();
    if (!mounted) return;
    _session?.removeListener(_onSession);
    context.read<SessionProvider>().clear();
    await context.read<AuthService>().signOut();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final student = session.student;
    return Scaffold(
      appBar: AppBar(title: AppScreenTitle(_title)),
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
                    _item(ShellTab.chat, Icons.forum_rounded, 'Chat'),
                    _item(
                      ShellTab.history,
                      Icons.history_rounded,
                      'Chat History',
                    ),
                    _item(
                      ShellTab.notifications,
                      Icons.notifications_rounded,
                      'Notifications',
                      badge: _unread,
                    ),
                    _item(
                      ShellTab.teachers,
                      Icons.groups_rounded,
                      'Teacher Tracking',
                    ),
                    _navigationModeTile(),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.palette_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Appearance'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                  Navigator.of(context)
                      .push(fadeSlideRoute<void>(const AppearanceScreen()));
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.danger,
                ),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
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
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            switch (_tab) {
              ShellTab.home => HomeScreen(
                onNewChat: () => _select(ShellTab.chat),
                onTeachers: () => _select(ShellTab.teachers),
                onNotifications: () => _select(ShellTab.notifications),
              ),
              ShellTab.chat => ChatScreen(
                key: ValueKey(_chatKey),
                embedded: true,
              ),
              ShellTab.history => const ChatHistoryScreen(),
              ShellTab.notifications => NotificationsScreen(
                onChanged: _refreshUnread,
              ),
              ShellTab.teachers => const TeachersScreen(),
            },
            if (_tab != ShellTab.chat)
              UnibotShortcut(onOpen: () => _select(ShellTab.chat)),
          ],
        ),
      ),
    );
  }

  String get _title => switch (_tab) {
    ShellTab.home => 'Home',
    ShellTab.chat => 'New Chat',
    ShellTab.history => 'Chat History',
    ShellTab.notifications => 'Notifications',
    ShellTab.teachers => 'Teacher Tracking',
  };

  Widget _navigationModeTile() {
    return _drawerRouteTile(
      icon: Icons.alt_route_rounded,
      label: 'Navigation Mode',
      route: AppRoutes.navigationMode,
    );
  }

  Widget _drawerRouteTile({
    required IconData icon,
    required String label,
    required String route,
  }) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: palette.muted),
        title: Text(
          label,
          style: AppTextStyles.label.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: palette.ink,
          ),
        ),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.pop(context);
          Navigator.of(context).pushNamed(route);
        },
      ),
    );
  }

  Widget _item(
    ShellTab tab,
    IconData icon,
    String label, {
    int badge = 0,
    bool comingSoon = false,
  }) {
    final palette = context.palette;
    final selected = _tab == tab && !comingSoon;
    final color = comingSoon
        ? palette.muted
        : selected
        ? Theme.of(context).colorScheme.primary
        : palette.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: selected,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
        leading: Icon(
          icon,
          color: comingSoon
              ? palette.muted
              : (selected
                    ? Theme.of(context).colorScheme.primary
                    : palette.muted),
        ),
        title: Text(
          label,
          style: AppTextStyles.label.copyWith(
            fontSize: 16,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
        trailing: comingSoon
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.line,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Coming soon',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 12,
                    color: palette.muted,
                  ),
                ),
              )
            : badge > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  style: AppTextStyles.label.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              )
            : null,
        onTap: () {
          HapticFeedback.selectionClick();
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
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: AppTextStyles.title.copyWith(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          if (registration.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              registration,
              style: AppTextStyles.muted.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
