import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_text_field.dart';
import '../widgets/brand_header.dart';
import '../widgets/waking_banner.dart';

/// Temporary Milestone 1 screen. Removed after both endpoints respond.
class BackendCheckScreen extends StatefulWidget {
  const BackendCheckScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<BackendCheckScreen> createState() => _BackendCheckScreenState();
}

class _BackendCheckScreenState extends State<BackendCheckScreen> {
  late final TextEditingController _urlController;
  bool _checking = false;
  String? _healthResult;
  String? _catalogResult;
  String? _error;
  bool _bothOk = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: context.read<ApiService>().baseUrl,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || Uri.tryParse(url)?.hasScheme != true) {
      setState(() {
        _error = 'Enter a full address, starting with https://';
        _healthResult = null;
        _catalogResult = null;
        _bothOk = false;
      });
      return;
    }

    setState(() {
      _checking = true;
      _error = null;
      _healthResult = null;
      _catalogResult = null;
      _bothOk = false;
    });

    final api = context.read<ApiService>();
    await api.setBaseUrl(url);

    try {
      final health = await api.getHealth();
      if (!mounted) return;
      final status = health['status'] ?? 'ok';
      setState(() => _healthResult = 'Health is $status');
      debugPrint('Backend /health: $health');

      final catalog = await api.getCatalog();
      if (!mounted) return;
      final summary =
          '${catalog.departments.length} departments, ${catalog.semesters.length} semesters, ${catalog.sections.length} sections';
      setState(() {
        _catalogResult = 'Catalog loaded: $summary.';
        _bothOk = true;
      });
      debugPrint('Backend /api/catalog: $summary');
    } catch (error) {
      debugPrint('Backend check failed: $error');
      if (!mounted) return;
      setState(() => _error = describeError(error));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          children: [
            const BrandHeader(
              title: 'Check the university server',
              subtitle:
                  'This temporary check calls /health and /api/catalog. The first request can take about a minute if the server has been idle.',
            ),
            const SizedBox(height: 22),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WakingBanner(active: _checking),
                  AppTextField(
                    controller: _urlController,
                    label: 'Server address',
                    hint: 'https://your-app.onrender.com',
                    prefixIcon: Icons.cloud_outlined,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_checking) _check();
                    },
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Check backend',
                    icon: Icons.wifi_tethering_rounded,
                    loading: _checking,
                    onPressed: _checking ? null : _check,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ResultRow(
              title: '/health',
              detail: _healthResult,
              ok: _healthResult != null,
            ),
            const SizedBox(height: 10),
            _ResultRow(
              title: '/api/catalog',
              detail: _catalogResult,
              ok: _catalogResult != null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger, height: 1.35),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A 404 means this Render address has no running service yet. Deploy aicc-data-service, paste the new address, and check again.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ],
            if (_bothOk) ...[
              const SizedBox(height: 20),
              AppButton(
                label: 'Continue',
                variant: AppButtonVariant.secondary,
                onPressed: widget.onContinue,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.title,
    required this.detail,
    required this.ok,
  });

  final String title;
  final String? detail;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.accent : AppColors.muted;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  detail ?? 'Not checked yet',
                  style: TextStyle(color: color, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
