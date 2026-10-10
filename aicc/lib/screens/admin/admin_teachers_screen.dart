import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/transitions.dart';
import '../../models/faculty.dart';
import '../../services/api_exception.dart';
import '../../services/faculty_repository.dart';
import '../../services/faculty_search.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/status_pill.dart';
import 'admin_shell.dart';
import 'admin_teacher_form_screen.dart';

const teacherStatuses = [
  'Available',
  'In Class',
  'On Leave',
  'Left University',
  'Unavailable',
];

class AdminTeachersScreen extends StatefulWidget {
  const AdminTeachersScreen({super.key});

  @override
  State<AdminTeachersScreen> createState() => _AdminTeachersScreenState();
}

class _AdminTeachersScreenState extends State<AdminTeachersScreen> {
  final _search = TextEditingController();
  List<Faculty>? _faculty;
  Object? _error;
  bool _loading = true;
  String _department = '';
  bool _seeding = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final people = await context.read<FacultyRepository>().fetchAll();
      if (!mounted) return;
      setState(() => _faculty = people);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _seed() async {
    setState(() => _seeding = true);
    try {
      await context.read<FacultyRepository>().seedSampleFaculty();
      await _load();
    } catch (error) {
      if (!mounted) return;
      showAdminNotice(context, describeError(error));
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _openForm(Faculty? person) async {
    final saved = await Navigator.of(context).push<bool>(
      fadeSlideRoute(AdminTeacherFormScreen(faculty: person)),
    );
    if (saved == true) _load();
  }

  Future<void> _status(Faculty person) async {
    final next = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text('Working status', style: AppTextStyles.title.copyWith(fontSize: 18)),
              for (final status in teacherStatuses)
                ListTile(
                  title: Text(status),
                  trailing: person.currentStatus == status
                      ? const Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context, status),
                ),
            ],
          ),
        );
      },
    );
    if (next == null || next == person.currentStatus || !mounted) return;
    try {
      await context.read<FacultyRepository>().setStatus(person.id, next);
      await _load();
    } catch (error) {
      if (!mounted) return;
      showAdminNotice(context, describeError(error));
    }
  }

  Future<void> _delete(Faculty person) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete teacher?',
      message: '${person.fullName} will disappear from teacher tracking.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await context.read<FacultyRepository>().delete(person.id);
      HapticFeedback.mediumImpact();
      await _load();
    } catch (error) {
      if (!mounted) return;
      showAdminNotice(context, describeError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _faculty == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SkeletonBox(height: 48, radius: 24),
            SizedBox(height: 12),
            SkeletonBox(height: 88),
            SizedBox(height: 10),
            SkeletonBox(height: 88),
          ],
        ),
      );
    }
    if (_error != null && _faculty == null) {
      return ErrorState(message: describeError(_error!), onRetry: _load);
    }
    final people = filterFaculty(
      _faculty ?? const [],
      query: _search.text,
      department: _department,
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.selectionClick();
          _openForm(null);
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add teacher'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search by name or subject',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip('All', ''),
                _chip('Computer Science', 'BSCS'),
                _chip('Business', 'BBA'),
                _chip('Psychology', 'BSPSY'),
              ],
            ),
          ),
          Expanded(
            child: people.isEmpty
                ? EmptyState(
                    icon: Icons.groups_outlined,
                    title: (_faculty ?? const []).isEmpty ? 'No teachers yet' : 'No teachers found',
                    message: (_faculty ?? const []).isEmpty
                        ? 'Add a teacher, or load the sample faculty list.'
                        : 'Try another name, subject, or department.',
                    actionLabel: (_faculty ?? const []).isEmpty
                        ? (_seeding ? 'Loading…' : 'Load sample teachers')
                        : null,
                    onAction: (_faculty ?? const []).isEmpty && !_seeding ? _seed : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: people.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final person = people[index];
                      return Material(
                        color: context.palette.card,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          onTap: () => _openForm(person),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    initials(person.fullName),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        person.fullName,
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${person.designation} · ${departmentLabel(person.department)}',
                                        style: TextStyle(color: context.palette.muted, fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: StatusPill(label: person.currentStatus),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _openForm(person);
                                      case 'status':
                                        _status(person);
                                      case 'delete':
                                        _delete(person);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(value: 'status', child: Text('Change status')),
                                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String code) {
    final selected = _department == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _department = code),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : context.palette.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
