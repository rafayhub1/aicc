import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_config.dart';
import '../../core/formatters.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../services/activity_service.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/waking_banner.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.onLoginTap});

  final VoidCallback onLoginTap;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _regController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _regController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final registration = _regController.text.trim().toUpperCase();
    _regController.value = TextEditingValue(
      text: registration,
      selection: TextSelection.collapsed(offset: registration.length),
    );
    final api = context.read<ApiService>();
    final auth = context.read<AuthService>();
    final activity = context.read<ActivityService>();
    final prefs = context.read<SharedPreferences>();
    try {
      final student = await api.getStudent(registration);
      final user = await auth.createAccount(
        student: student,
        password: _passwordController.text,
      );
      await ProfileService().saveRegistration(user, student.registrationNumber);
      try {
        await activity.log('signup');
      } catch (_) {}
      await prefs.setBool(kSignupSuccessPrefsKey, true);
      await auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      return;
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(error, signup: true));
    } on FirebaseException {
      await auth.signOut();
      if (!mounted) return;
      setState(() {
        _error =
            'The university record was found, but the profile could not be saved. Publish the Firestore rules in aicc-mobile, then try again.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = describeError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Back to login',
                onPressed: widget.onLoginTap,
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
              ),
            ),
            const BrandHeader(
              title: 'Create your account',
              subtitle: 'We check your registration number against university records before creating the login.',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WakingBanner(active: _loading),
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.control),
                        ),
                        child: Text(
                          _error!,
                          style: AppTextStyles.muted.copyWith(color: AppColors.danger),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    AppTextField(
                      controller: _regController,
                      label: 'Registration number',
                      hint: 'FA26-BSCS-001',
                      prefixIcon: Icons.badge_outlined,
                      textInputAction: TextInputAction.next,
                      validator: (value) => validateRegistration(value ?? ''),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use a real record, such as FA26-BSCS-001 (Ayesha Malik), FA26-BBA-001 (Ayesha Sheikh), or FA26-BSPSY-001 (Ayesha Khan).',
                      style: AppTextStyles.muted.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      obscure: true,
                      prefixIcon: Icons.lock_outline_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (value) => validatePassword(value ?? ''),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _confirmController,
                      label: 'Confirm password',
                      obscure: true,
                      prefixIcon: Icons.lock_outline_rounded,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return validatePassword(value ?? '');
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Create account',
                      loading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
