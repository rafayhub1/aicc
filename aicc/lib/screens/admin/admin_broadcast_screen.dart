import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/student.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../widgets/app_button.dart';
import 'admin_shell.dart';

class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _message = TextEditingController();
  String _type = 'other';
  String _department = '';
  int _semester = 0;
  String _section = '';
  int? _preview;
  bool _counting = false;
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  bool _matches(Student student) {
    if (_department.isNotEmpty && student.department != _department) return false;
    if (_semester != 0 && student.semester != _semester) return false;
    if (_section.isNotEmpty && student.section != _section) return false;
    return true;
  }

  Future<void> _count() async {
    setState(() => _counting = true);
    try {
      final students = await context.read<ApiService>().listStudents();
      if (!mounted) return;
      setState(() => _preview = students.where(_matches).length);
    } catch (error) {
      if (!mounted) return;
      showAdminNotice(context, describeError(error));
    } finally {
      if (mounted) setState(() => _counting = false);
    }
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty) {
      showAdminNotice(context, 'Write a message first.');
      return;
    }
    setState(() => _sending = true);
    try {
      final count = await context.read<ApiService>().broadcastNotification(
            message: text,
            type: _type,
            department: _department,
            semester: _semester == 0 ? null : _semester,
            section: _section,
          );
      if (!mounted) return;
      setState(() => _preview = count);
      _message.clear();
      showAdminNotice(context, 'Sent to $count students.');
    } catch (error) {
      if (!mounted) return;
      showAdminNotice(context, describeError(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Send a notification', style: AppTextStyles.title.copyWith(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          'It appears in each matching student\'s notification list.',
          style: TextStyle(color: context.palette.muted),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _message,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Message',
            hintText: 'Fee challans for this semester are ready.',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Type'),
          items: const [
            DropdownMenuItem(value: 'other', child: Text('Other')),
            DropdownMenuItem(value: 'fee_challan_ready', child: Text('Fee challan ready')),
            DropdownMenuItem(value: 'roll_slip_ready', child: Text('Roll slip ready')),
          ],
          onChanged: (value) => setState(() => _type = value ?? 'other'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _department,
          decoration: const InputDecoration(labelText: 'Department'),
          items: const [
            DropdownMenuItem(value: '', child: Text('All departments')),
            DropdownMenuItem(value: 'BSCS', child: Text('Computer Science')),
            DropdownMenuItem(value: 'BBA', child: Text('Business Administration')),
            DropdownMenuItem(value: 'BSPSY', child: Text('Psychology')),
          ],
          onChanged: (value) => setState(() {
            _department = value ?? '';
            _preview = null;
          }),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _semester,
                decoration: const InputDecoration(labelText: 'Semester'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('All')),
                  DropdownMenuItem(value: 1, child: Text('1')),
                  DropdownMenuItem(value: 2, child: Text('2')),
                  DropdownMenuItem(value: 3, child: Text('3')),
                  DropdownMenuItem(value: 4, child: Text('4')),
                ],
                onChanged: (value) => setState(() {
                  _semester = value ?? 0;
                  _preview = null;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _section,
                decoration: const InputDecoration(labelText: 'Section'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('All')),
                  DropdownMenuItem(value: 'A', child: Text('A')),
                  DropdownMenuItem(value: 'B', child: Text('B')),
                ],
                onChanged: (value) => setState(() {
                  _section = value ?? '';
                  _preview = null;
                }),
              ),
            ),
          ],
        ),
        if (_preview != null) ...[
          const SizedBox(height: 16),
          Text(
            '$_preview students will receive this.',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
        const SizedBox(height: 16),
        AppButton(
          label: 'Preview count',
          variant: AppButtonVariant.secondary,
          loading: _counting,
          onPressed: _counting || _sending ? null : _count,
        ),
        const SizedBox(height: 10),
        AppButton(
          label: 'Send',
          loading: _sending,
          onPressed: _counting || _sending ? null : _send,
        ),
      ],
    );
  }
}
