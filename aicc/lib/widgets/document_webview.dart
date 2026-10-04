import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/theme.dart';
import 'error_state.dart';

class DocumentWebView extends StatefulWidget {
  const DocumentWebView({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  State<DocumentWebView> createState() => _DocumentWebViewState();
}

class _DocumentWebViewState extends State<DocumentWebView> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() => _failed = false);
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame == false) return;
            setState(() => _failed = true);
          },
        ),
      );
    _load();
  }

  void _load() {
    setState(() {
      _failed = false;
      _progress = 0;
    });
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _failed
          ? ErrorState(
              message: 'This document could not be opened. Check your connection and try again.',
              onRetry: _load,
            )
          : Column(
              children: [
                if (_progress < 100)
                  LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress / 100,
                    minHeight: 3,
                    color: AppColors.accent,
                    backgroundColor: AppColors.line,
                  ),
                Expanded(child: WebViewWidget(controller: _controller)),
              ],
            ),
    );
  }
}

void openDocument(BuildContext context, {required String title, required String url}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DocumentWebView(title: title, url: url),
    ),
  );
}
