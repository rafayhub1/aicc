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
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/document_webview.dart';
import '../../widgets/waking_banner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onSignupTap});

  final VoidCallback onSignupTap;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _regController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<SharedPreferences>();
    if (prefs.getBool(kSignupSuccessPrefsKey) == true) {
      _notice = 'Account created. Log in with your registration number.';
      prefs.remove(kSignupSuccessPrefsKey);
    }
  }

  @override
  void dispose() {
    _regController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final raw = _regController.text.trim();
    final registration = registrationPattern.hasMatch(raw) ? raw.toUpperCase() : raw;
    _regController.value = TextEditingValue(
      text: registration,
      selection: TextSelection.collapsed(offset: registration.length),
    );
    final auth = context.read<AuthService>();
    final activity = context.read<ActivityService>();
    final api = context.read<ApiService>();
    try {
      final user = await auth.signIn(
        registrationNumber: registration,
        password: _passwordController.text,
        bootstrap: api.bootstrapAdmin,
      );
      if (!registrationPattern.hasMatch(registration) && !await auth.isAdmin(user)) {
        await api.bootstrapAdmin();
        await user.getIdToken(true);
      }
      try {
        await activity.log('login');
      } catch (_) {}
      if (!mounted) return;
      final admin = await auth.isAdmin(user);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        admin ? AppRoutes.admin : AppRoutes.home,
        (route) => false,
      );
      return;
    } on FirebaseAuthException {
      if (!mounted) return;
      setState(() => _error = kLoginErrorMessage);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = describeError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editServer() async {
    final api = context.read<ApiService>();
    final controller = TextEditingController(text: api.baseUrl);
    var testing = false;
    String? resultText;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('University server'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paste the public server address. Do not add a slash at the end.',
                    style: TextStyle(color: context.palette.muted, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Server address',
                      hintText: 'https://your-service.up.railway.app',
                    ),
                  ),
                  if (resultText != null) ...[
                    const SizedBox(height: 12),
                    Text(resultText!, style: const TextStyle(height: 1.35)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: testing
                      ? null
                      : () async {
                          setDialogState(() {
                            testing = true;
                            resultText = null;
                          });
                          await api.setBaseUrl(controller.text);
                          try {
                            final health = await api.getHealth();
                            final catalog = await api.getCatalog();
                            setDialogState(() {
                              resultText =
                                  'Connected. Health: ${health['status']}. Departments: ${catalog.departments.join(', ')}.';
                            });
                          } catch (error) {
                            setDialogState(() => resultText = describeError(error));
                          } finally {
                            setDialogState(() => testing = false);
                          }
                        },
                  child: Text(testing ? 'Testing…' : 'Test connection'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }

  void _previewDocument(String title, String path) {
    final base = context.read<ApiService>().baseUrl;
    openDocument(
      context,
      title: title,
      url: '$base/students/FA26-BSCS-001/$path',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          children: [
            const BrandHeader(
              title: 'Welcome back',
              subtitle: 'Sign in with the registration number on your university record.',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    WakingBanner(active: _loading),
                    if (_notice != null) ...[
                      _Banner(text: _notice!, color: AppColors.accent),
                      const SizedBox(height: 12),
                    ],
                    if (_error != null) ...[
                      _Banner(text: _error!, color: AppColors.danger),
                      const SizedBox(height: 12),
                    ],
                    AppTextField(
                      controller: _regController,
                      label: 'Registration number',
                      hint: 'FA26-BSCS-001',
                      prefixIcon: Icons.badge_outlined,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.visiblePassword,
                      validator: (value) => validateLoginIdentifier(value ?? ''),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      obscure: true,
                      prefixIcon: Icons.lock_outline_rounded,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (value) => validatePassword(value ?? ''),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Log in',
                      loading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: widget.onSignupTap,
              child: const Text('New student? Create an account'),
            ),
            TextButton(
              onPressed: _editServer,
              child: const Text('University server address'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Temporary check for the document viewer. These open a sample student record.',
              style: AppTextStyles.muted,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: 'Preview fee challan',
              variant: AppButtonVariant.secondary,
              icon: Icons.receipt_long_outlined,
              onPressed: () => _previewDocument('Fee challan', 'fee-challan'),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Preview roll slip',
              variant: AppButtonVariant.secondary,
              icon: Icons.badge_outlined,
              onPressed: () => _previewDocument('Roll number slip', 'roll-slip'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Text(text, style: TextStyle(color: color, height: 1.35)),
    );
  }
}
