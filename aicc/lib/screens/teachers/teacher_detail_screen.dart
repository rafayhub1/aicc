import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/faculty.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_pill.dart';

class TeacherDetailScreen extends StatelessWidget {
  const TeacherDetailScreen({super.key, required this.faculty});

  final Faculty faculty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    initials(faculty.fullName),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faculty.fullName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${faculty.designation} · ${departmentLabel(faculty.department)}',
                        style: TextStyle(color: context.palette.muted),
                      ),
                      const SizedBox(height: 8),
                      StatusPill(label: faculty.currentStatus),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(context, 'Subjects', faculty.subjects.map((subject) => '• $subject').join('\n')),
          _section(context, 'Class schedule', faculty.classSchedule),
          _section(context, 'Consultation hours', faculty.consultationHours),
          _section(context, 'Days off', faculty.daysOff.join(', ')),
          _section(
            context,
            'Office',
            '${faculty.officeRoom}\n${faculty.officeBuilding}',
          ),
          _contact(
            context,
            label: 'Email',
            value: faculty.email,
            icon: Icons.email_outlined,
            onOpen: () => _open(context, Uri(scheme: 'mailto', path: faculty.email)),
          ),
          _contact(
            context,
            label: 'Phone',
            value: faculty.phone,
            icon: Icons.call_outlined,
            onOpen: () => _open(context, Uri(scheme: 'tel', path: faculty.phone)),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: context.palette.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(height: 1.4, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _contact(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onOpen,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onOpen,
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: context.palette.muted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  SelectableText(
                    value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Copy $label',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label copied')),
                );
              },
              icon: const Icon(Icons.copy_rounded, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri);
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the phone or email app. The address is shown above.')),
    );
  }
}
