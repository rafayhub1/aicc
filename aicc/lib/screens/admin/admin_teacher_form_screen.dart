import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/faculty.dart';
import '../../services/api_exception.dart';
import '../../services/faculty_repository.dart';
import '../../widgets/app_button.dart';
import 'admin_shell.dart';
import 'admin_teachers_screen.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class AdminTeacherFormScreen extends StatefulWidget {
  const AdminTeacherFormScreen({super.key, this.faculty});

  final Faculty? faculty;

  @override
  State<AdminTeacherFormScreen> createState() => _AdminTeacherFormScreenState();
}

class _AdminTeacherFormScreenState extends State<AdminTeacherFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _designation;
  late final TextEditingController _subject;
  late final TextEditingController _schedule;
  late final TextEditingController _consult;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _building;
  late final TextEditingController _room;
  late String _department;
  late String _status;
  late List<String> _subjects;
  late Set<String> _daysOff;
  bool _saving = false;

  bool get _editing => widget.faculty != null;

  @override
  void initState() {
    super.initState();
    final person = widget.faculty;
    _name = TextEditingController(text: person?.fullName ?? '');
    _designation = TextEditingController(text: person?.designation ?? '');
    _subject = TextEditingController();
    _schedule = TextEditingController(text: person?.classSchedule ?? '');
    _consult = TextEditingController(text: person?.consultationHours ?? '');
    _email = TextEditingController(text: person?.email ?? '');
    _phone = TextEditingController(text: person?.phone ?? '');
    _building = TextEditingController(text: person?.officeBuilding ?? '');
    _room = TextEditingController(text: person?.officeRoom ?? '');
    _department = person?.department ?? 'BSCS';
    _status = person?.currentStatus ?? 'Available';
    if (!teacherStatuses.contains(_status)) _status = 'Available';
    _subjects = [...?person?.subjects];
    _daysOff = {...?person?.daysOff};
  }

  @override
  void dispose() {
    _name.dispose();
    _designation.dispose();
    _subject.dispose();
    _schedule.dispose();
    _consult.dispose();
    _email.dispose();
    _phone.dispose();
    _building.dispose();
    _room.dispose();
    super.dispose();
  }

  void _addSubject() {
    final value = _subject.text.trim();
    if (value.isEmpty) return;
    if (_subjects.any((item) => item.toLowerCase() == value.toLowerCase())) {
      _subject.clear();
      return;
    }
    setState(() {
      _subjects = [..._subjects, value];
      _subject.clear();
    });
  }

  String _idFor(String name) {
    final existing = widget.faculty?.id;
    if (existing != null && existing.isNotEmpty) return existing;
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.isEmpty) return 'teacher-${DateTime.now().millisecondsSinceEpoch}';
    return slug;
  }

  Future<void> _save() async {
    _addSubject();
    if (!_formKey.currentState!.validate()) return;
    if (_subjects.isEmpty) {
      showAdminNotice(context, 'Add at least one subject.');
      return;
    }
    setState(() => _saving = true);
    final name = _name.text.trim();
    var email = _email.text.trim();
    if (email.isEmpty) {
      email = '${name.toLowerCase().replaceAll(RegExp(r'[^a-z\s]'), '').trim().replaceAll(RegExp(r'\s+'), '.')}@aicc.edu.pk';
    }
    final person = Faculty(
      id: _idFor(name),
      fullName: name,
      department: _department,
      designation: _designation.text.trim(),
      subjects: _subjects,
      classSchedule: _schedule.text.trim(),
      consultationHours: _consult.text.trim(),
      daysOff: _weekdays.where(_daysOff.contains).toList(),
      email: email,
      phone: _phone.text.trim(),
      officeBuilding: _building.text.trim(),
      officeRoom: _room.text.trim(),
      currentStatus: _status,
    );
    try {
      await context.read<FacultyRepository>().save(person, create: !_editing);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      showAdminNotice(context, describeError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit teacher' : 'Add teacher')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_name, 'Full name', required: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _department,
              decoration: const InputDecoration(labelText: 'Department'),
              items: const [
                DropdownMenuItem(value: 'BSCS', child: Text('Computer Science')),
                DropdownMenuItem(value: 'BBA', child: Text('Business Administration')),
                DropdownMenuItem(value: 'BSPSY', child: Text('Psychology')),
              ],
              onChanged: _saving ? null : (value) => setState(() => _department = value ?? 'BSCS'),
            ),
            const SizedBox(height: 12),
            _field(_designation, 'Designation', required: true, hint: 'Lecturer'),
            const SizedBox(height: 12),
            Text('Subjects', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final subject in _subjects)
                  InputChip(
                    label: Text(subject),
                    onDeleted: _saving
                        ? null
                        : () => setState(() => _subjects = _subjects.where((item) => item != subject).toList()),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _field(_subject, 'Add subject', hint: 'Programming Fundamentals')),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _saving ? null : _addSubject,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(_schedule, 'Class schedule', required: true, hint: 'Mon/Wed 10:00-12:00'),
            const SizedBox(height: 12),
            _field(_consult, 'Consultation hours', required: true, hint: 'Mon 12:15-13:15'),
            const SizedBox(height: 12),
            Text('Days off', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final day in _weekdays)
                  FilterChip(
                    label: Text(day.substring(0, 3)),
                    selected: _daysOff.contains(day),
                    onSelected: _saving
                        ? null
                        : (selected) {
                            setState(() {
                              if (selected) {
                                _daysOff.add(day);
                              } else {
                                _daysOff.remove(day);
                              }
                            });
                          },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _field(_email, 'Email', hint: 'name@aicc.edu.pk', keyboard: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(_phone, 'Phone', required: true, keyboard: TextInputType.phone),
            const SizedBox(height: 12),
            _field(_building, 'Office building', required: true),
            const SizedBox(height: 12),
            _field(_room, 'Office room', required: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final status in teacherStatuses)
                  DropdownMenuItem(value: status, child: Text(status)),
              ],
              onChanged: _saving ? null : (value) => setState(() => _status = value ?? 'Available'),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _editing ? 'Save teacher' : 'Create teacher',
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    String? hint,
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: (value) {
        if (required && (value ?? '').trim().isEmpty) return 'Enter $label';
        if (label == 'Email' && (value ?? '').trim().isNotEmpty && !value!.contains('@')) {
          return 'Enter a valid email';
        }
        return null;
      },
    );
  }
}
