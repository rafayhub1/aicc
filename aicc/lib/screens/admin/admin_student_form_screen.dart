import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/student.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'admin_shell.dart';

class AdminStudentFormScreen extends StatefulWidget {
  const AdminStudentFormScreen({super.key, this.student});

  final Student? student;

  @override
  State<AdminStudentFormScreen> createState() => _AdminStudentFormScreenState();
}

class _AdminStudentFormScreenState extends State<AdminStudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _registration;
  late final TextEditingController _cgpa;
  late String _department;
  late int _semester;
  late String _section;
  bool _saving = false;

  bool get _editing => widget.student != null;

  @override
  void initState() {
    super.initState();
    final student = widget.student;
    _name = TextEditingController(text: student?.name ?? '');
    _registration = TextEditingController(text: student?.registrationNumber ?? '');
    _cgpa = TextEditingController(
      text: student == null ? '' : student.cgpaOverall.toStringAsFixed(2),
    );
    _department = student?.department ?? 'BSCS';
    _semester = student?.semester == 0 ? 1 : (student?.semester ?? 1);
    _section = student?.section == 'B' ? 'B' : 'A';
  }

  @override
  void dispose() {
    _name.dispose();
    _registration.dispose();
    _cgpa.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final registration = _registration.text.trim().toUpperCase();
    final student = Student(
      id: widget.student?.id ?? registration,
      name: _name.text.trim(),
      registrationNumber: registration,
      department: _department,
      semester: _semester,
      section: _section,
      cgpaOverall: double.parse(_cgpa.text.trim()),
    );
    final api = context.read<ApiService>();
    try {
      final saved = _editing
          ? await api.updateStudent(widget.student!.id, student.toJson())
          : await api.createStudent(student.toJson());
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.pop(context, saved);
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
      appBar: AppBar(title: Text(_editing ? 'Edit student' : 'Add student')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              controller: _name,
              label: 'Full name',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter the student name' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _registration,
              label: 'Registration number',
              hint: 'FA26-BSCS-001',
              prefixIcon: Icons.badge_outlined,
              textInputAction: TextInputAction.next,
              validator: (value) => validateStudentRegistration(value ?? '', _department),
            ),
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
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _semester,
                    decoration: const InputDecoration(labelText: 'Semester'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1')),
                      DropdownMenuItem(value: 2, child: Text('2')),
                      DropdownMenuItem(value: 3, child: Text('3')),
                      DropdownMenuItem(value: 4, child: Text('4')),
                    ],
                    onChanged: _saving ? null : (value) => setState(() => _semester = value ?? 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _section,
                    decoration: const InputDecoration(labelText: 'Section'),
                    items: const [
                      DropdownMenuItem(value: 'A', child: Text('A')),
                      DropdownMenuItem(value: 'B', child: Text('B')),
                    ],
                    onChanged: _saving ? null : (value) => setState(() => _section = value ?? 'A'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _cgpa,
              label: 'CGPA',
              hint: '3.40',
              prefixIcon: Icons.grade_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                final parsed = double.tryParse((value ?? '').trim());
                if (parsed == null) return 'Enter a CGPA';
                if (parsed < 0 || parsed > 4) return 'CGPA must be between 0 and 4';
                return null;
              },
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _editing ? 'Save changes' : 'Create student',
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
