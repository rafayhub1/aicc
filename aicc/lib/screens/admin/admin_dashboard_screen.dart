import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/campus_stats.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../services/faculty_repository.dart';
import '../../widgets/app_card.dart';
import '../../widgets/error_state.dart';
import '../../widgets/skeleton.dart';
import 'admin_shell.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, required this.onOpen});

  final ValueChanged<AdminTab> onOpen;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  CampusStats? _stats;
  int? _teachers;
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
      final api = context.read<ApiService>();
      final faculty = context.read<FacultyRepository>();
      final results = await Future.wait([
        api.getStats(),
        faculty.fetchAll(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as CampusStats;
        _teachers = (results[1] as List).length;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _stats == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SkeletonBox(height: 96),
            SizedBox(height: 12),
            SkeletonBox(height: 96),
            SizedBox(height: 12),
            SkeletonBox(height: 140),
          ],
        ),
      );
    }
    if (_error != null && _stats == null) {
      return ErrorState(message: describeError(_error!), onRetry: _load);
    }
    final stats = _stats!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Campus overview', style: AppTextStyles.title.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            'Students, documents, and teachers in one place.',
            style: TextStyle(color: context.palette.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _StatTile(label: 'Students', value: '${stats.totalStudents}')),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(label: 'Teachers', value: '${_teachers ?? 0}')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Pending documents',
                  value: '${stats.pendingDocuments}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Average CGPA',
                  value: stats.averageCgpa == null ? '—' : stats.averageCgpa!.toStringAsFixed(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('By department', style: AppTextStyles.title.copyWith(fontSize: 18)),
          const SizedBox(height: AppSpacing.sm),
          for (final department in stats.byDepartment) ...[
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(department.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Text(
                    '${department.count}',
                    style: AppTextStyles.title.copyWith(fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text('Quick actions', style: AppTextStyles.title.copyWith(fontSize: 18)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Action(icon: Icons.school_rounded, label: 'Students', onTap: () => widget.onOpen(AdminTab.students)),
              _Action(icon: Icons.groups_rounded, label: 'Teachers', onTap: () => widget.onOpen(AdminTab.teachers)),
              _Action(icon: Icons.campaign_rounded, label: 'Broadcast', onTap: () => widget.onOpen(AdminTab.broadcast)),
              _Action(icon: Icons.timeline_rounded, label: 'Activity', onTap: () => widget.onOpen(AdminTab.activity)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.title.copyWith(fontSize: 26)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: context.palette.muted)),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.card,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          width: 150,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
