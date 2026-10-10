import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/transitions.dart';
import '../../models/faculty.dart';
import '../../services/api_exception.dart';
import '../../services/faculty_repository.dart';
import '../../services/faculty_search.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/status_pill.dart';
import 'teacher_detail_screen.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final _search = TextEditingController();
  List<Faculty>? _faculty;
  Object? _error;
  bool _loading = true;
  String _department = '';
  bool _seeding = false;

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _seed() async {
    setState(() => _seeding = true);
    try {
      await context.read<FacultyRepository>().seedSampleFaculty();
      if (!mounted) return;
      await _load();
    } catch (error) {
      if (!mounted) return;
      final denied = '$error'.toLowerCase().contains('permission');
      setState(() => _error = denied ? 'rules' : error);
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
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
      final rules = _error == 'rules';
      return ErrorState(
        message: rules
            ? 'Publish the latest aicc/firestore.rules in the aicc-mobile project, then try again.'
            : describeError(_error!),
        onRetry: rules ? _seed : _load,
      );
    }
    final people = filterFaculty(
      _faculty ?? const [],
      query: _search.text,
      department: _department,
    );
    return Column(
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
              _deptChip('All', ''),
              _deptChip('Computer Science', 'BSCS'),
              _deptChip('Business', 'BBA'),
              _deptChip('Psychology', 'BSPSY'),
            ],
          ),
        ),
        Expanded(
          child: people.isEmpty
              ? EmptyState(
                  icon: Icons.person_search_rounded,
                  title: (_faculty ?? const []).isEmpty ? 'No teachers yet' : 'No teachers found',
                  message: _error == 'rules'
                      ? 'Publish the latest aicc/firestore.rules in the aicc-mobile project, then try again.'
                      : (_faculty ?? const []).isEmpty
                          ? 'Load 36 sample teachers. Some teach English, maths, or statistics in more than one department.'
                          : 'Try another name, subject, or department.',
                  actionLabel: (_faculty ?? const []).isEmpty
                      ? (_seeding ? 'Loading…' : 'Load sample teachers')
                      : null,
                  onAction: (_faculty ?? const []).isEmpty && !_seeding ? _seed : null,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: people.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final person = people[index];
                    return Material(
                      color: context.palette.card,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        onTap: () {
                          Navigator.of(context).push(
                            fadeSlideRoute<void>(TeacherDetailScreen(faculty: person)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
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
                                  ],
                                ),
                              ),
                              StatusPill(label: person.currentStatus),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _deptChip(String label, String code) {
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
