import 'dart:async';

import 'package:flutter/foundation.dart';
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
import '../../services/places_repository.dart';
import '../../services/voice_service.dart';
import '../../widgets/document_webview.dart';
import '../../widgets/place_card.dart';
import '../../widgets/unibot.dart';
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

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _voice = VoiceService();
  late final ChatEngine _engine;
  late final ActivityService _activity;

  final List<ChatMessage> _messages = [];
  String? _sessionId;
  bool _loadingHistory = false;
  bool _replying = false;
  bool _listening = false;
  bool _transcribing = false;
  bool _speakerOn = true;
  bool _loggedCompletion = false;
  bool _unibotVisiting = false;
  String? _error;
  Timer? _unibotTimer;

  @override
  void initState() {
    super.initState();
    _activity = context.read<ActivityService>();
    _engine = ChatEngine(
      api: context.read<ApiService>(),
      facultyLoader: () => context.read<FacultyRepository>().fetchAll(),
      placesLoader: () async {
        final places = context.read<PlacesRepository>();
        await places.ensureLoaded();
        return places.places;
      },
    );
    _sessionId = widget.sessionId;
    _speakerOn = context.read<SharedPreferences>().getBool(kSpeakerEnabledPrefsKey) ?? true;
    if (_sessionId != null) _loadHistory();
    if (!widget.readOnly) _armUnibotVisit();
  }

  void _noteMicIdle() {
    if (!mounted || widget.readOnly || _listening || _transcribing) return;
    _armUnibotVisit();
  }

  void _armUnibotVisit() {
    _unibotTimer?.cancel();
    if (_listening || _transcribing) return;
    _unibotTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || _listening || _transcribing) return;
      setState(() => _unibotVisiting = true);
      _unibotTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => _unibotVisiting = false);
        _armUnibotVisit();
      });
    });
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
    _unibotTimer?.cancel();
    unawaited(_voice.dispose());
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final target = widget.readOnly ? _scroll.position.maxScrollExtent : 0.0;
      _scroll.animateTo(
        target,
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

      final prior = _messages.where((message) => message.id != userMessage.id).toList();
      final reply = await _engine.respond(
        text: text,
        student: session.student,
        history: prior.length <= 6 ? prior : prior.sublist(prior.length - 6),
      );
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
        placeIds: reply.placeIds,
        source: reply.source,
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
        Expanded(child: _conversation()),
        if (!widget.readOnly) _composer(),
      ],
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.readOnly ? 'Chat replay' : 'New Chat'),
        actions: [_speakerButton()],
      ),
      body: SafeArea(top: false, child: body),
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

  Widget _conversation() {
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
    if (widget.readOnly || _messages.isEmpty) {
      return widget.readOnly ? _messageList() : _voiceHub();
    }

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Column(
      children: [
        if (!keyboardOpen) SizedBox(height: 168, child: _voiceHub()),
        Expanded(child: _messageList()),
      ],
    );
  }

  Widget _voiceHub() {
    final busy = _replying || _transcribing;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        if (!maxHeight.isFinite || maxHeight < 64) return const SizedBox.shrink();
        final compact = maxHeight < 200;
        final showLabel = maxHeight >= 132;
        final size = compact ? 76.0 : 112.0;
        final showUnibot = _listening || _transcribing || _unibotVisiting;
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: size + 44,
                  height: size + 36,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    alignment: Alignment.bottomCenter,
                    children: [
                      Material(
                        color: _listening ? AppColors.danger : AppColors.primary,
                        elevation: 0,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: busy ? null : _toggleMic,
                          child: SizedBox(
                            width: size,
                            height: size,
                            child: Icon(
                              _transcribing
                                  ? Icons.hourglass_top_rounded
                                  : _listening
                                      ? Icons.stop_rounded
                                      : Icons.mic_rounded,
                              color: Colors.white,
                              size: compact ? 32 : 48,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 2,
                        child: IgnorePointer(
                          child: AnimatedScale(
                            scale: showUnibot ? 1 : 0,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutBack,
                            child: UnibotAvatar(
                              size: compact ? 44 : 64,
                              mood: _listening || _transcribing ? UnibotMood.thumbsUp : UnibotMood.wink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showLabel) ...[
                  SizedBox(height: compact ? 8 : 12),
                  Text(
                    _transcribing
                        ? 'Turning speech into text…'
                        : _listening
                            ? 'Listening… tap to send'
                            : 'Tap to talk',
                    style: TextStyle(
                      color: context.palette.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 13 : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _messageList() {
    final newestFirst = !widget.readOnly;
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (notification) {
        notification.disallowIndicator();
        return true;
      },
      child: ListView(
        controller: _scroll,
        reverse: newestFirst,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        children: [
          if (newestFirst) ...[
            if (_replying) const _TypingIndicator(),
            WakingBanner(active: _replying),
            for (final message in _messages.reversed) _Bubble(message: message),
          ] else ...[
            for (final message in _messages) _Bubble(message: message),
          ],
        ],
      ),
    );
  }

  Widget _suggestionQueue() {
    final palette = context.palette;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestedQuestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final question = suggestedQuestions[index];
          return ActionChip(
            visualDensity: VisualDensity.compact,
            backgroundColor: palette.card,
            side: BorderSide(color: palette.line),
            label: Text(question),
            onPressed: _replying
                ? null
                : () {
                    _input.text = question;
                    _send();
                  },
          );
        },
      ),
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
            if (_listening || _transcribing) ...[
              const _ListeningWave(),
              const SizedBox(height: 6),
              Text(
                _transcribing ? 'Turning speech into text…' : 'Listening… tap stop when you finish',
                textAlign: TextAlign.center,
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
            ],
            _suggestionQueue(),
            const SizedBox(height: 8),
            Row(
              children: [
                _RoundIconButton(
                  tooltip: _listening ? 'Stop listening' : 'Speak a question',
                  icon: _listening ? Icons.stop_rounded : Icons.mic_rounded,
                  filled: _listening,
                  onPressed: (_replying || _transcribing) ? null : _toggleMic,
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
    if (_listening || _voice.isRecording) {
      final path = await _voice.stopRecording();
      if (!mounted) return;
      setState(() {
        _listening = false;
        _transcribing = path != null;
      });
      if (path == null) {
        _noteMicIdle();
        return;
      }
      try {
        final spoken = await context.read<ApiService>().transcribeSpeech(path);
        if (!mounted) return;
        _input.text = spoken;
        _input.selection = TextSelection.collapsed(offset: _input.text.length);
        setState(() => _transcribing = false);
        _noteMicIdle();
        if (spoken.trim().isNotEmpty) {
          await _send();
        } else {
          _showMicHelp('No words were heard. Speak a little longer, then tap stop.');
        }
      } catch (error) {
        if (!mounted) return;
        setState(() => _transcribing = false);
        _noteMicIdle();
        _showMicHelp(describeError(error));
      }
      return;
    }
    try {
      await _voice.stopSpeaking();
      final ready = await _voice.prepare();
      if (!ready) {
        _showMicHelp(
          'Microphone permission is needed to speak a question. Allow it when Android asks, or turn the microphone on for AICC in system settings.',
        );
        return;
      }
      await _voice.startRecording();
      if (!mounted) return;
      _unibotTimer?.cancel();
      setState(() => _listening = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _listening = false);
      _noteMicIdle();
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
          color: mine ? Theme.of(context).colorScheme.primary : context.palette.card,
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
            if (!mine)
              for (final id in message.placeIds)
                Builder(
                  builder: (context) {
                    final place = context.read<PlacesRepository>().byId(id);
                    if (place == null) return const SizedBox.shrink();
                    return PlaceCard(place: place);
                  },
                ),
            Text(
              message.content,
              style: TextStyle(
                color: mine ? Colors.white : context.palette.ink,
                height: 1.35,
              ),
            ),
            if (!mine && kDebugMode && message.source != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'answered by: ${message.source}',
                  style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : context.palette.muted),
                ),
              ),
            if (!mine && message.actionUrl != null) ...[
              const SizedBox(height: 10),
              Material(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.control),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  onTap: () => openDocument(
                    context,
                    title: message.actionLabel ?? 'Document',
                    url: message.actionUrl!,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            message.actionLabel ?? 'View document',
                            style: AppTextStyles.label.copyWith(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListeningWave extends StatefulWidget {
  const _ListeningWave();

  @override
  State<_ListeningWave> createState() => _ListeningWaveState();
}

class _ListeningWaveState extends State<_ListeningWave> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 5; i++)
              Container(
                width: 4,
                height: 8 + 16 * _bar(_controller.value, i),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        );
      },
    );
  }

  double _bar(double t, int index) {
    final phase = (t + index / 5) % 1;
    return phase < 0.5 ? phase * 2 : (1 - phase) * 2;
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.palette.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.card,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.35 + 0.65 * _dot(_controller.value, i),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  double _dot(double t, int index) {
    final phase = (t + index / 3) % 1;
    return phase < 0.5 ? phase * 2 : (1 - phase) * 2;
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
          backgroundColor: filled ? Theme.of(context).colorScheme.primary : context.palette.background,
          foregroundColor: filled ? Colors.white : Theme.of(context).colorScheme.primary,
        ),
        icon: Icon(icon),
      ),
    );
  }
}
