import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/transitions.dart';
import '../../models/student.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/skeleton.dart';
import 'admin_student_detail_screen.dart';
import 'admin_student_form_screen.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final _search = TextEditingController();
  List<Student>? _students;
  Object? _error;
  bool _loading = true;
  String _department = '';
  int? _semester;
  String _section = '';

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
      final students = await context.read<ApiService>().listStudents();
      students.sort((a, b) => a.registrationNumber.compareTo(b.registrationNumber));
      if (!mounted) return;
      setState(() => _students = students);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final created = await Navigator.of(context).push<Student>(
      fadeSlideRoute(const AdminStudentFormScreen()),
    );
    if (created != null) _load();
  }

  List<Student> get _visible {
    final query = _search.text.trim().toLowerCase();
    return (_students ?? const <Student>[]).where((student) {
      if (_department.isNotEmpty && student.department != _department) return false;
      if (_semester != null && student.semester != _semester) return false;
      if (_section.isNotEmpty && student.section != _section) return false;
      if (query.isEmpty) return true;
      return student.name.toLowerCase().contains(query) ||
          student.registrationNumber.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _students == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SkeletonBox(height: 48, radius: 24),
            SizedBox(height: 12),
            SkeletonBox(height: 84),
            SizedBox(height: 10),
            SkeletonBox(height: 84),
          ],
        ),
      );
    }
    if (_error != null && _students == null) {
      return ErrorState(message: describeError(_error!), onRetry: _load);
    }
    final students = _visible;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.selectionClick();
          _add();
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add student'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search name or registration number',
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
                _chip('All', _department.isEmpty, () => setState(() => _department = '')),
                _chip('CS', _department == 'BSCS', () => setState(() => _department = 'BSCS')),
                _chip('BBA', _department == 'BBA', () => setState(() => _department = 'BBA')),
                _chip('Psychology', _department == 'BSPSY', () => setState(() => _department = 'BSPSY')),
                _chip('Sem all', _semester == null, () => setState(() => _semester = null)),
                for (final semester in [1, 2, 3, 4])
                  _chip(
                    'Sem $semester',
                    _semester == semester,
                    () => setState(() => _semester = semester),
                  ),
                _chip('Sec all', _section.isEmpty, () => setState(() => _section = '')),
                _chip('A', _section == 'A', () => setState(() => _section = 'A')),
                _chip('B', _section == 'B', () => setState(() => _section = 'B')),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: students.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: 360,
                          child: EmptyState(
                            icon: Icons.school_outlined,
                            title: (_students ?? const []).isEmpty
                                ? 'No students yet'
                                : 'No students match',
                            message: (_students ?? const []).isEmpty
                                ? 'Add a student record to get started.'
                                : 'Try another name, registration number, or filter.',
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: students.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return Material(
                          color: context.palette.card,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            onTap: () async {
                              final changed = await Navigator.of(context).push<bool>(
                                fadeSlideRoute(AdminStudentDetailScreen(student: student)),
                              );
                              if (changed == true) _load();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    child: Text(
                                      initials(student.name),
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
                                          student.name,
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${student.registrationNumber} · ${departmentLabel(student.department)} · Sem ${student.semester}${student.section}',
                                          style: TextStyle(color: context.palette.muted, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    student.cgpaOverall.toStringAsFixed(2),
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : context.palette.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
