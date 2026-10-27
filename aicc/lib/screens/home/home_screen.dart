import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/academics.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../core/transitions.dart';
import '../../models/course.dart';
import '../../models/student.dart';
import '../../models/student_document.dart';
import '../../providers/session_provider.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/document_webview.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/fade_in.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/unibot.dart';
import '../../widgets/waking_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onNewChat,
    required this.onTeachers,
    required this.onNotifications,
  });

  final VoidCallback onNewChat;
  final VoidCallback onTeachers;
  final VoidCallback onNotifications;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Course>? _courses;
  Object? _courseError;
  bool _loadingCourses = false;
  String? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final student = context.read<SessionProvider>().student;
    if (student != null && _loadedFor != student.id) {
      _loadedFor = student.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadCourses();
      });
    }
  }

  Future<void> _loadCourses() async {
    final session = context.read<SessionProvider>();
    final student = session.student;
    if (student == null) {
      if (session.loading) return;
      final user = context.read<AuthService>().currentUser;
      if (user != null && session.error != null) return;
      return;
    }
    setState(() {
      _loadingCourses = true;
      _courseError = null;
    });
    try {
      final courses = await context.read<ApiService>().getCourses(
            student.id,
            semester: student.semester,
          );
      if (!mounted) return;
      setState(() => _courses = courses);
    } catch (error) {
      if (!mounted) return;
      setState(() => _courseError = error);
    } finally {
      if (mounted) setState(() => _loadingCourses = false);
    }
  }

  Future<void> _refresh() async {
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      await context.read<SessionProvider>().bind(user, force: true);
    }
    await _loadCourses();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    if (session.loading && session.student == null) {
      return const DashboardSkeleton();
    }
    if (session.error != null && session.student == null) {
      return ErrorState(
        message: describeError(session.error!),
        onRetry: _refresh,
      );
    }
    final student = session.student;
    if (student == null) {
      return const EmptyState(
        icon: Icons.person_outline_rounded,
        title: 'No student record yet',
        message: 'Pull to refresh once your account is linked to a registration number.',
      );
    }

    final courses = _courses ?? const <Course>[];
    final average = averageAttendance(courses);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg + bottomInset,
        ),
        children: [
          FadeIn(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _WelcomeCard(student: student)),
                const SizedBox(width: AppSpacing.sm),
                const UnibotAvatar(size: 112, interactive: true, showName: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FadeIn(
            delayMs: 40,
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _InfoChip(icon: Icons.school_outlined, label: departmentLabel(student.department)),
                _InfoChip(icon: Icons.layers_outlined, label: 'Semester ${student.semester}'),
                _InfoChip(icon: Icons.groups_outlined, label: 'Section ${student.section}'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          WakingBanner(active: _loadingCourses && _courses == null),
          if (_courseError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                describeError(_courseError!),
                style: AppTextStyles.muted.copyWith(color: AppColors.danger),
              ),
            ),
          FadeIn(
            delayMs: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _CgpaCard(cgpa: student.cgpaOverall)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _AttendanceCard(
                    average: average,
                    loading: _loadingCourses && _courses == null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'This semester',
            style: AppTextStyles.title.copyWith(fontSize: 18, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_loadingCourses && _courses == null) ...[
            const SkeletonBox(height: 88),
            const SizedBox(height: AppSpacing.sm),
            const SkeletonBox(height: 88),
            const SizedBox(height: AppSpacing.sm),
            const SkeletonBox(height: 88),
          ] else if (courses.isEmpty)
            const AppCard(
              child: EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No courses yet',
                message: 'Courses for this semester will show up here.',
              ),
            )
          else
            for (var i = 0; i < courses.length; i++) ...[
              FadeIn(delayMs: 30 * i, child: _CourseTile(course: courses[i])),
              const SizedBox(height: AppSpacing.sm),
            ],
          const SizedBox(height: AppSpacing.md),
          Text(
            'Quick actions',
            style: AppTextStyles.title.copyWith(fontSize: 18, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.forum_rounded,
                  label: 'Chat',
                  onTap: widget.onNewChat,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActionTile(
                  icon: Icons.description_outlined,
                  label: 'Documents',
                  onTap: () => _openDocuments(student),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActionTile(
                  icon: Icons.groups_rounded,
                  label: 'Teachers',
                  onTap: widget.onTeachers,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openDocuments(Student student) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.palette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: _DocumentsSheet(studentId: student.id),
        );
      },
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${greetingFor(DateTime.now())},',
            style: AppTextStyles.muted.copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            firstName(student.name),
            style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 28),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            student.registrationNumber,
            style: AppTextStyles.muted.copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

class _CgpaCard extends StatelessWidget {
  const _CgpaCard({required this.cgpa});

  final double cgpa;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (cgpa / 4).clamp(0, 1)),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return CustomPaint(
                  painter: _RingPainter(progress: value, track: context.palette.line),
                  child: Center(
                    child: Text(
                      cgpa.toStringAsFixed(2),
                      style: AppTextStyles.title.copyWith(fontSize: 18, color: context.palette.ink),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('CGPA', style: AppTextStyles.label.copyWith(color: context.palette.muted)),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.track});

  final double progress;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = track;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = AppColors.accent;
    canvas.drawArc(rect.deflate(6), -1.5708, 6.2832, false, paint);
    canvas.drawArc(rect.deflate(6), -1.5708, 6.2832 * progress, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.track != track;
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.average, required this.loading});

  final double? average;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final tone = average == null
        ? context.palette.muted
        : average! < 75
            ? AppColors.danger
            : average! < 85
                ? AppColors.warning
                : AppColors.accent;
    return AppCard(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            loading ? '…' : average == null ? '—' : '${average!.toStringAsFixed(0)}%',
            style: AppTextStyles.display.copyWith(fontSize: 32, color: tone),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Attendance', style: AppTextStyles.label.copyWith(color: context.palette.muted)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.label.copyWith(color: context.palette.ink)),
        ],
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final tone = course.attendancePercent < 75
        ? AppColors.danger
        : course.attendancePercent < 85
            ? AppColors.warning
            : AppColors.accent;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  course.courseName,
                  style: TextStyle(fontWeight: FontWeight.w700, color: context.palette.ink),
                ),
              ),
              Text(
                '${course.attendancePercent.toStringAsFixed(0)}%',
                style: TextStyle(color: tone, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(course.courseCode, style: TextStyle(color: context.palette.muted, fontSize: 12)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (course.attendancePercent / 100).clamp(0, 1)),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  color: tone,
                  backgroundColor: context.palette.line,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.palette.ink),
          ),
        ],
      ),
    );
  }
}

class _DocumentsSheet extends StatefulWidget {
  const _DocumentsSheet({required this.studentId});

  final String studentId;

  @override
  State<_DocumentsSheet> createState() => _DocumentsSheetState();
}

class _DocumentsSheetState extends State<_DocumentsSheet> {
  late final Future<List<StudentDocument>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ApiService>().getDocuments(widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: FutureBuilder<List<StudentDocument>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text(describeError(snapshot.error!)),
              );
            }
            final documents = snapshot.data ?? const <StudentDocument>[];
            if (documents.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No documents on your record yet.'),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your documents', style: AppTextStyles.title.copyWith(fontSize: 20, color: palette.ink)),
                const SizedBox(height: 6),
                Text(
                  'Open a document here, or download it in the browser to save or print.',
                  style: AppTextStyles.muted.copyWith(color: palette.muted),
                ),
                const SizedBox(height: 14),
                for (final document in documents) ...[
                  _DocumentCard(document: document, studentId: widget.studentId),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document, required this.studentId});

  final StudentDocument document;
  final String studentId;

  String get _title => document.docType == 'roll_number_slip' ? 'Roll number slip' : 'Fee challan';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final url = document.resolvedUrl(context.read<ApiService>().baseUrl, studentId);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                document.docType == 'roll_number_slip' ? Icons.badge_outlined : Icons.receipt_long_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(_title, style: AppTextStyles.label.copyWith(fontSize: 16, color: palette.ink))),
              StatusPill(label: document.isReady ? 'Ready' : 'Pending'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            document.isReady
                ? 'Issued and ready to open.'
                : 'Not issued yet. You can still open the page.',
            style: AppTextStyles.muted.copyWith(color: palette.muted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'View',
                  icon: Icons.visibility_outlined,
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    navigator.push(
                      fadeSlideRoute<void>(DocumentWebView(title: _title, url: url)),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'Download',
                  icon: Icons.download_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => downloadDocument(context, url),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
