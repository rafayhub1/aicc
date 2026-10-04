import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../chat/chat_engine.dart';
import '../../chat/intent.dart';
import '../../core/api_config.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/chat_message.dart';
import '../../providers/session_provider.dart';
import '../../services/activity_service.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_repository.dart';
import '../../services/faculty_repository.dart';
import '../../services/voice_service.dart';
import '../../widgets/document_webview.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/waking_banner.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.sessionId,
    this.readOnly = false,
    this.embedded = false,
  });

  final String? sessionId;
  final bool readOnly;
  final bool embedded;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _voice = VoiceService();
  late final ChatEngine _engine;
  late final ActivityService _activity;
  late final AnimationController _pulse;

  final List<ChatMessage> _messages = [];
  String? _sessionId;
  bool _loadingHistory = false;
  bool _replying = false;
  bool _listening = false;
  bool _speakerOn = true;
  bool _loggedCompletion = false;
  bool _stopRequested = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _activity = context.read<ActivityService>();
    _engine = ChatEngine(
      api: context.read<ApiService>(),
      facultyLoader: () => context.read<FacultyRepository>().fetchAll(),
    );
    _sessionId = widget.sessionId;
    _speakerOn = context.read<SharedPreferences>().getBool(kSpeakerEnabledPrefsKey) ?? true;
    if (_sessionId != null) _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final messages = await context.read<ChatRepository>().listMessages(_sessionId!);
      if (!mounted) return;
      setState(() => _messages.addAll(messages));
      _scrollToEnd();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = describeError(error));
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  @override
  void dispose() {
    if (!widget.readOnly && _messages.isNotEmpty && !_loggedCompletion) {
      _loggedCompletion = true;
      _activity.log('chat_completed').then((_) {}, onError: (_, _) {});
    }
    _pulse.dispose();
    _voice.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _replying || widget.readOnly) return;
    final repo = context.read<ChatRepository>();
    final session = context.read<SessionProvider>();
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;

    _input.clear();
    setState(() => _replying = true);
    final now = DateTime.now();
    try {
      _sessionId ??= await repo.createSession(chatTitleFrom(text));
      final userMessage = ChatMessage(
        id: 'local-user-$now',
        sessionId: _sessionId!,
        userId: uid,
        role: 'user',
        content: text,
        createdAt: now,
      );
      setState(() => _messages.add(userMessage));
      _scrollToEnd();
      await repo.addMessage(userMessage);

      final reply = await _engine.respond(text: text, student: session.student);
      if (!mounted) return;
      final assistant = ChatMessage(
        id: 'local-assistant-${DateTime.now().microsecondsSinceEpoch}',
        sessionId: _sessionId!,
        userId: uid,
        role: 'assistant',
        content: reply.text,
        createdAt: DateTime.now(),
        actionLabel: reply.action?.label,
        actionUrl: reply.action?.url,
      );
      setState(() => _messages.add(assistant));
      _scrollToEnd();
      await repo.addMessage(assistant);
      if (_speakerOn) await _voice.speak(reply.text);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = describeError(error));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeError(error))),
      );
    } finally {
      if (mounted) setState(() => _replying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        if (widget.readOnly)
          Container(
            width: double.infinity,
            color: AppColors.primary.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Text(
              'Past conversation. This replay is read only.',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        Expanded(child: _messageList()),
        if (!widget.readOnly) _composer(),
      ],
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.readOnly ? 'Chat replay' : 'New Chat'),
        actions: [_speakerButton()],
      ),
      body: body,
    );
  }

  Widget _speakerButton() {
    return IconButton(
      tooltip: _speakerOn ? 'Mute replies' : 'Read replies aloud',
      onPressed: () async {
        final next = !_speakerOn;
        setState(() => _speakerOn = next);
        await context.read<SharedPreferences>().setBool(kSpeakerEnabledPrefsKey, next);
        if (!next) await _voice.stopSpeaking();
      },
      icon: Icon(_speakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded),
    );
  }

  Widget _messageList() {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _messages.isEmpty) {
      return EmptyState(
        icon: Icons.forum_outlined,
        title: 'Chat unavailable',
        message: _error!,
      );
    }
    if (_messages.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          const Text(
            'Ask about fees, attendance, courses, or a teacher.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.3),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can type, or tap the microphone and speak.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final question in suggestedQuestions)
                ActionChip(
                  label: Text(question),
                  onPressed: () {
                    _input.text = question;
                    _send();
                  },
                ),
            ],
          ),
        ],
      );
    }
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        for (final message in _messages) _Bubble(message: message),
        if (_replying) const _TypingIndicator(),
        WakingBanner(active: _replying),
      ],
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            if (widget.embedded)
              Align(alignment: Alignment.centerRight, child: _speakerButton()),
            if (_listening)
              FadeTransition(
                opacity: Tween<double>(begin: 0.4, end: 1).animate(_pulse),
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Listening… speak your question',
                    style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            Row(
              children: [
                _RoundIconButton(
                  tooltip: _listening ? 'Stop listening' : 'Speak a question',
                  icon: _listening ? Icons.stop_rounded : Icons.mic_rounded,
                  filled: _listening,
                  onPressed: _toggleMic,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Ask AICC…',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _RoundIconButton(
                  tooltip: 'Send',
                  icon: Icons.send_rounded,
                  filled: true,
                  onPressed: _replying ? null : () => _send(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleMic() async {
    if (_voice.isListening) {
      _stopRequested = true;
      await _voice.stopListening();
      if (mounted) setState(() => _listening = false);
      final spoken = _input.text.trim();
      if (spoken.isNotEmpty) _send();
      return;
    }
    try {
      _stopRequested = false;
      final ready = await _voice.prepare();
      if (!ready) {
        _showMicHelp('Speech recognition is not available on this phone.');
        return;
      }
      setState(() => _listening = true);
      await _voice.listen(
        onResult: (words, isFinal) {
          if (!mounted || _stopRequested) return;
          _input.text = words;
          _input.selection = TextSelection.collapsed(offset: _input.text.length);
          if (isFinal) {
            setState(() => _listening = false);
            if (words.trim().isNotEmpty) _send();
          }
        },
      );
    } catch (_) {
      if (mounted) setState(() => _listening = false);
      _showMicHelp(
        'Microphone permission is needed to speak a question. Allow it when Android asks, or turn the microphone on for AICC in system settings.',
      );
    }
  }

  void _showMicHelp(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.isUser;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          boxShadow: mine ? null : AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: mine ? Colors.white : AppColors.ink,
                height: 1.35,
              ),
            ),
            if (!mine && message.actionUrl != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => openDocument(
                  context,
                  title: message.actionLabel ?? 'Document',
                  url: message.actionUrl!,
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(message.actionLabel ?? 'Open document'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Text('AICC is typing…', style: TextStyle(color: AppColors.muted)),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton.filled(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: filled ? AppColors.primary : AppColors.background,
          foregroundColor: filled ? Colors.white : AppColors.primary,
        ),
        icon: Icon(icon),
      ),
    );
  }
}
