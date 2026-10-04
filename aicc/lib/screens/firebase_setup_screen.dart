import 'package:flutter/material.dart';

import '../core/theme.dart';

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const SizedBox(height: 12),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                'AICC',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Connect the mobile Firebase project',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The app is built, but it still needs its own Firebase project for login, chat, and teacher tracking. This is separate from the backend project aicc-dummy-data.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 20),
            const _Step(number: '1', text: 'Open console.firebase.google.com and create a project named aicc-mobile.'),
            const _Step(number: '2', text: 'In that project, open Build → Authentication → Get started, then turn on Email/Password.'),
            const _Step(number: '3', text: 'Open Build → Firestore Database → Create database. Pick region asia-south1 and start in test mode.'),
            const _Step(number: '4', text: 'On this computer, install Node.js, then run: npm i -g firebase-tools and firebase login.'),
            const _Step(number: '5', text: 'In a terminal, run: dart pub global activate flutterfire_cli'),
            const _Step(number: '6', text: 'From the aicc folder, run: flutterfire configure --project=aicc-mobile --platforms=android'),
            const _Step(number: '7', text: 'In Firestore → Rules, paste the rules from aicc/firestore.rules, then Publish.'),
            const _Step(number: '8', text: 'Stop the app and run it again. You should land on the login screen.'),
            const SizedBox(height: 16),
            const Text(
              'Sample registration numbers, after the backend is seeded: FA26-BSCS-001, FA26-BBA-001, FA26-BSPSY-001.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Text(
              number,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(height: 1.4)),
          ),
        ],
      ),
    );
  }
}
