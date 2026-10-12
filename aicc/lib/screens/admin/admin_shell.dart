import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/transitions.dart';
import '../../providers/session_provider.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/confirm_dialog.dart';
import '../settings/appearance_screen.dart';
import 'admin_activity_screen.dart';
import 'admin_broadcast_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_students_screen.dart';
import 'admin_teachers_screen.dart';

enum AdminTab { dashboard, students, teachers, broadcast, activity }

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AdminTab _tab = AdminTab.dashboard;
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
    if (_session?.role == SessionRole.student && _session?.student != null && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    }
  }

  void _select(AdminTab tab) => setState(() => _tab = tab);

  Future<void> _logout() async {
    final confirmed = await confirmAction(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again.',
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
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthService>().currentUser?.email ?? '';
    final name = _displayName(email);
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              _Header(name: name),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _item(AdminTab.dashboard, Icons.dashboard_rounded, 'Dashboard'),
                    _item(AdminTab.students, Icons.school_rounded, 'Students'),
                    _item(AdminTab.teachers, Icons.groups_rounded, 'Teachers'),
                    _item(AdminTab.broadcast, Icons.campaign_rounded, 'Broadcast'),
                    _item(AdminTab.activity, Icons.timeline_rounded, 'Activity Log'),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.palette_outlined, color: Theme.of(context).colorScheme.primary),
                title: const Text('Appearance'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                  Navigator.of(context).push(fadeSlideRoute<void>(const AppearanceScreen()));
                },
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
      body: SafeArea(
        top: false,
        child: switch (_tab) {
          AdminTab.dashboard => AdminDashboardScreen(onOpen: _select),
          AdminTab.students => const AdminStudentsScreen(),
          AdminTab.teachers => const AdminTeachersScreen(),
          AdminTab.broadcast => const AdminBroadcastScreen(),
          AdminTab.activity => const AdminActivityScreen(),
        },
      ),
    );
  }

  String get _title => switch (_tab) {
        AdminTab.dashboard => 'Dashboard',
        AdminTab.students => 'Students',
        AdminTab.teachers => 'Teachers',
        AdminTab.broadcast => 'Broadcast',
        AdminTab.activity => 'Activity Log',
      };

  Widget _item(AdminTab tab, IconData icon, String label) {
    final palette = context.palette;
    final selected = _tab == tab;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: selected,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
        leading: Icon(icon, color: selected ? Theme.of(context).colorScheme.primary : palette.muted),
        title: Text(
          label,
          style: AppTextStyles.label.copyWith(
            fontSize: 16,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Theme.of(context).colorScheme.primary : palette.ink,
          ),
        ),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.pop(context);
          _select(tab);
        },
      ),
    );
  }
}

String _displayName(String email) {
  final local = email.split('@').first.trim();
  if (local.isEmpty) return 'Administrator';
  return local[0].toUpperCase() + local.substring(1);
}

class _Header extends StatelessWidget {
  const _Header({required this.name});

  final String name;

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
            child: Text(initials(name), style: AppTextStyles.title.copyWith(fontSize: 18)),
          ),
          const SizedBox(height: 14),
          Text(name, style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            'Administrator',
            style: AppTextStyles.muted.copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}

void showAdminNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
