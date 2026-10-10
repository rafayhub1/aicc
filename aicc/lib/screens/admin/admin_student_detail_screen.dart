import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/transitions.dart';
import '../../models/app_notification.dart';
import '../../models/course.dart';
import '../../models/student.dart';
import '../../models/student_document.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/document_webview.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/status_pill.dart';
import 'admin_shell.dart';
import 'admin_student_form_screen.dart';

class AdminStudentDetailScreen extends StatefulWidget {
  const AdminStudentDetailScreen({super.key, required this.student});

  final Student student;

  @override
  State<AdminStudentDetailScreen> createState() => _AdminStudentDetailScreenState();
}

class _AdminStudentDetailScreenState extends State<AdminStudentDetailScreen> {
  late Student _student = widget.student;
  bool _changed = false;

  void _replace(Student student) {
    setState(() {
      _student = student;
      _changed = true;
    });
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<Student>(
      fadeSlideRoute(AdminStudentFormScreen(student: _student)),
    );
    if (saved != null) _replace(saved);
  }

  Future<void> _deleteStudent() async {
    final confirmed = await _confirmTyped(
      context,
      title: 'Delete student?',
      message:
          'This removes the university record, courses, documents, notifications, and the app account. Type ${_student.registrationNumber} to confirm.',
      expected: _student.registrationNumber,
    );
    if (!confirmed || !mounted) return;
    try {
      await context.read<ApiService>().deleteStudentFully(_student.id);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      showAdminNotice(context, describeError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.pop(context, _changed);
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(_student.name),
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Profile'),
                Tab(text: 'Courses'),
                Tab(text: 'Documents'),
                Tab(text: 'Notifications'),
                Tab(text: 'Account'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _ProfileTab(student: _student, onEdit: _edit, onDelete: _deleteStudent),
              _CoursesTab(studentId: _student.id, maxSemester: _student.semester),
              _DocumentsTab(studentId: _student.id),
              _NotificationsTab(studentId: _student.id),
              _AccountTab(registration: _student.registrationNumber),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.student,
    required this.onEdit,
    required this.onDelete,
  });

  final Student student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            children: [
              _row(context, 'Name', student.name),
              _row(context, 'Registration', student.registrationNumber),
              _row(context, 'Department', departmentLabel(student.department)),
              _row(context, 'Semester', '${student.semester}'),
              _row(context, 'Section', student.section),
              _row(context, 'CGPA', student.cgpaOverall.toStringAsFixed(2)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppButton(label: 'Edit profile', icon: Icons.edit_outlined, onPressed: onEdit),
        const SizedBox(height: 28),
        Text('Danger zone', style: AppTextStyles.title.copyWith(fontSize: 16, color: AppColors.danger)),
        const SizedBox(height: 8),
        Text(
          'Deleting a student cannot be undone.',
          style: TextStyle(color: context.palette.muted),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Delete student',
          variant: AppButtonVariant.danger,
          icon: Icons.delete_outline_rounded,
          onPressed: onDelete,
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: context.palette.muted)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _CoursesTab extends StatefulWidget {
  const _CoursesTab({required this.studentId, required this.maxSemester});

  final String studentId;
  final int maxSemester;

  @override
  State<_CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends State<_CoursesTab> {
  List<Course>? _courses;
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
      final courses = await context.read<ApiService>().getCourses(widget.studentId);
      courses.sort((a, b) => a.courseCode.compareTo(b.courseCode));
      if (!mounted) return;
      setState(() => _courses = courses);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(Course? course) async {
    final saved = await showModalBottomSheet<Course>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CourseSheet(
        course: course,
        maxSemester: widget.maxSemester,
      ),
    );
    if (saved == null || !mounted) return;
    final api = context.read<ApiService>();
    try {
      if (course == null) {
        await api.createCourse(widget.studentId, saved.toJson());
      } else {
        await api.updateCourse(widget.studentId, course.id, saved.toJson());
      }
      await _load();
    } catch (error) {
      if (!mounted) return;
      showAdminNotice(context, describeError(error));
    }
  }

  Future<void> _delete(Course course) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete course?',
      message: '${course.courseName} will be removed from this student.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await context.read<ApiService>().deleteCourse(widget.studentId, course.id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      showAdminNotice(context, describeError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _courses == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _courses == null) {
      return ErrorState(message: describeError(_error!), onRetry: _load);
    }
    final courses = _courses ?? const <Course>[];
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextButton.icon(
              onPressed: () => _edit(null),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add course'),
            ),
          ),
        ),
        Expanded(
          child: courses.isEmpty
              ? const EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'No courses',
                  message: 'Add a course and its attendance.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: courses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return Dismissible(
                      key: ValueKey(course.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        await _delete(course);
                        return false;
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                      ),
                      child: AppCard(
                        onTap: () => _edit(course),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(course.courseName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${course.courseCode} · Semester ${course.semester}',
                                    style: TextStyle(color: context.palette.muted, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${course.attendancePercent.toStringAsFixed(0)}%',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CourseSheet extends StatefulWidget {
  const _CourseSheet({required this.course, required this.maxSemester});

  final Course? course;
  final int maxSemester;

  @override
  State<_CourseSheet> createState() => _CourseSheetState();
}

class _CourseSheetState extends State<_CourseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _attendance;
  late int _semester;

  @override
  void initState() {
    super.initState();
    final course = widget.course;
    _name = TextEditingController(text: course?.courseName ?? '');
    _code = TextEditingController(text: course?.courseCode ?? '');
    _attendance = TextEditingController(
      text: course == null ? '' : course.attendancePercent.toStringAsFixed(0),
    );
    final cap = widget.maxSemester.clamp(1, 4).toInt();
    final current = course?.semester ?? cap;
    _semester = current.clamp(1, cap).toInt();
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _attendance.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final draft = Course(
      id: widget.course?.id ?? '',
      courseName: _name.text.trim(),
      courseCode: _code.text.trim().toUpperCase(),
      attendancePercent: double.parse(_attendance.text.trim()),
      semester: _semester,
    );
    Navigator.pop(context, draft);
  }

  @override
  Widget build(BuildContext context) {
    final cap = widget.maxSemester.clamp(1, 4).toInt();
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.course == null ? 'Add course' : 'Edit course',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Course name'),
              validator: (value) => (value ?? '').trim().isEmpty ? 'Enter a course name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _code,
              decoration: const InputDecoration(labelText: 'Course code'),
              validator: (value) => (value ?? '').trim().isEmpty ? 'Enter a course code' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _semester,
              decoration: const InputDecoration(labelText: 'Semester'),
              items: [
                for (var semester = 1; semester <= cap; semester++)
                  DropdownMenuItem(value: semester, child: Text('$semester')),
              ],
              onChanged: (value) => setState(() => _semester = value ?? 1),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _attendance,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Attendance %'),
              validator: (value) {
                final parsed = double.tryParse((value ?? '').trim());
                if (parsed == null) return 'Enter attendance';
                if (parsed < 0 || parsed > 100) return 'Use 0 to 100';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Save course',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentsTab extends StatefulWidget {
  const _DocumentsTab({required this.studentId});

  final String studentId;

  @override
  State<_DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<_DocumentsTab> {
  static const _types = [
    ('fee_challan', 'Fee challan'),
    ('roll_number_slip', 'Roll number slip'),
  ];

  List<StudentDocument>? _documents;
  Object? _error;
  bool _loading = true;
  String? _busyId;

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
      final documents = await context.read<ApiService>().getDocuments(widget.studentId);
      if (!mounted) return;
      setState(() => _documents = documents);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  StudentDocument? _for(String type) {
    for (final document in _documents ?? const <StudentDocument>[]) {
      if (document.docType == type) return document;
    }
    return null;
  }

  Future<void> _create(String type) async {
    setState(() => _busyId = type);
    try {
      await context.read<ApiService>().createDocument(widget.studentId, {
        'docType': type,
        'status': 'pending',
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      showAdminNotice(context, describeError(error));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _setStatus(StudentDocument document, bool ready) async {
    setState(() => _busyId = document.id);
    try {
      await context.read<ApiService>().updateDocument(
        widget.studentId,
        document.id,
        {'status': ready ? 'ready' : 'pending'},
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      showAdminNotice(context, describeError(error));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _delete(StudentDocument document) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete document?',
      message: 'The student will no longer see this document.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await context.read<ApiService>().deleteDocument(widget.studentId, document.id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      showAdminNotice(context, describeError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _documents == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _documents == null) {
      return ErrorState(message: describeError(_error!), onRetry: _load);
    }
    final base = context.read<ApiService>().baseUrl;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in _types) ...[
          _documentCard(context, entry.$1, entry.$2, _for(entry.$1), base),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _documentCard(
    BuildContext context,
    String type,
    String title,
    StudentDocument? document,
    String base,
  ) {
    final busy = _busyId == type || _busyId == document?.id;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
              if (document != null) StatusPill(label: document.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            document == null
                ? 'Not created yet.'
                : document.isReady
                    ? 'Visible to the student.'
                    : 'Marked pending.',
            style: TextStyle(color: context.palette.muted),
          ),
          const SizedBox(height: 12),
          if (document == null)
            AppButton(
              label: 'Create',
              loading: busy,
              onPressed: busy ? null : () => _create(type),
            )
          else ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ready'),
              value: document.isReady,
              onChanged: busy ? null : (value) => _setStatus(document, value),
            ),
            AppButton(
              label: 'Preview',
              variant: AppButtonVariant.secondary,
              icon: Icons.visibility_outlined,
              onPressed: () => openDocument(
                context,
                title: title,
                url: document.resolvedUrl(base, widget.studentId),
              ),
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Delete',
              variant: AppButtonVariant.danger,
              onPressed: busy ? null : () => _delete(document),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationsTab extends StatefulWidget {
  const _NotificationsTab({required this.studentId});

  final String studentId;

  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  final _message = TextEditingController();
  String _type = 'other';
  List<AppNotification>? _items;
  Object? _error;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await context.read<ApiService>().getNotifications(widget.studentId);
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (!mounted) return;
      setState(() => _items = items);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
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
      await context.read<ApiService>().createNotification(widget.studentId, {
        'type': _type,
        'message': text,
        'read': false,
      });
      _message.clear();
      await _load();
      if (!mounted) return;
      showAdminNotice(context, 'Notification sent.');
    } catch (error) {
      if (!mounted) return;
      showAdminNotice(context, describeError(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(AppNotification item) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete notification?',
      message: item.message,
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await context.read<ApiService>().deleteNotification(widget.studentId, item.id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      showAdminNotice(context, describeError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _message,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Message',
            hintText: 'Your fee challan is ready.',
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
            DropdownMenuItem(value: 'sign_in', child: Text('Sign in')),
          ],
          onChanged: (value) => setState(() => _type = value ?? 'other'),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Send notification',
          loading: _sending,
          onPressed: _sending ? null : _send,
        ),
        const SizedBox(height: 20),
        if (_loading && _items == null)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (_error != null && _items == null)
          ErrorState(message: describeError(_error!), onRetry: _load)
        else if ((_items ?? const []).isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications',
              message: 'Messages you send appear here.',
            ),
          )
        else
          for (final item in _items!) ...[
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.message, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          '${_typeLabel(item.type)} · ${relativeTime(item.timestamp)}',
                          style: TextStyle(color: context.palette.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () => _delete(item),
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _AccountTab extends StatefulWidget {
  const _AccountTab({required this.registration});

  final String registration;

  @override
  State<_AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<_AccountTab> {
  bool _loading = true;
  Object? _error;
  bool _exists = false;
  DateTime? _created;
  DateTime? _lastSignIn;
  bool _busy = false;

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
      final account = await context.read<ApiService>().getAccount(widget.registration);
      if (!mounted) return;
      setState(() {
        _exists = account.exists;
        _created = account.created;
        _lastSignIn = account.lastSignIn;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setPassword() async {
    final password = await _askPassword(context);
    if (password == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<ApiService>().setAccountPassword(widget.registration, password);
      if (!mounted) return;
      showAdminNotice(context, 'Password updated.');
    } catch (error) {
      if (!mounted) return;
      showAdminNotice(context, describeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    final confirmed = await confirmAction(
      context,
      title: 'Remove app account?',
      message: 'The student record stays. They will need to sign up again.',
      confirmLabel: 'Remove account',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<ApiService>().deleteAccount(widget.registration);
      await _load();
      if (!mounted) return;
      showAdminNotice(context, 'App account removed.');
    } catch (error) {
      if (!mounted) return;
      showAdminNotice(context, describeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorState(message: describeError(_error!), onRetry: _load);
    final format = DateFormat('d MMM y, h:mm a');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _exists ? 'Signed up' : 'No app account yet',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _exists
                    ? 'Created ${format.format((_created ?? DateTime.now()).toLocal())}'
                    : 'This student can create an account from the sign-up screen.',
                style: TextStyle(color: context.palette.muted),
              ),
              if (_exists && _lastSignIn != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Last sign-in ${format.format(_lastSignIn!.toLocal())}',
                  style: TextStyle(color: context.palette.muted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Set new password',
          icon: Icons.lock_reset_rounded,
          loading: _busy,
          onPressed: !_exists || _busy ? null : _setPassword,
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Remove app account',
          variant: AppButtonVariant.danger,
          onPressed: !_exists || _busy ? null : _remove,
        ),
      ],
    );
  }
}

String _typeLabel(String type) {
  return switch (type) {
    'fee_challan_ready' => 'Fee challan',
    'roll_slip_ready' => 'Roll slip',
    'sign_in' => 'Sign in',
    _ => 'Other',
  };
}

Future<bool> _confirmTyped(
  BuildContext context, {
  required String title,
  required String message,
  required String expected,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final matches = controller.text.trim().toUpperCase() == expected.toUpperCase();
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(labelText: expected),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                onPressed: matches ? () => Navigator.pop(context, true) : null,
                child: const Text('Delete', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      );
    },
  );
  controller.dispose();
  return result ?? false;
}

Future<String?> _askPassword(BuildContext context) async {
  final password = TextEditingController();
  final confirm = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final result = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Set new password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
                validator: (value) => validatePassword(value ?? ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm password'),
                validator: (value) => value == password.text ? null : 'Passwords do not match',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, password.text);
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
  password.dispose();
  confirm.dispose();
  return result;
}
