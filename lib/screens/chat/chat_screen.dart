// lib/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/history_provider.dart';
import '../../services/speech_service.dart';
import '../camera/camera_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isLoading = false;
  bool _isListening = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text, {InputType type = InputType.text}) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    setState(() => _isLoading = true);
    await ref.read(chatProvider.notifier).send(
      content:   text.trim(),
      inputType: type,
    );
    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _openCamera() async {
    final text = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    if (text != null && text.isNotEmpty && mounted) {
      _sendMessage(text, type: InputType.ocr);
    }
  }

  Future<void> _toggleListening() async {
    final svc = SpeechService.instance;
    if (_isListening) {
      await svc.stop();
      setState(() => _isListening = false);
      return;
    }
    final ok = await svc.initialize();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone not available on this device')),
      );
      return;
    }
    setState(() => _isListening = true);
    await svc.startListening(onResult: (words, isFinal) {
      _controller.text = words;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: words.length),
      );
      if (isFinal) {
        setState(() => _isListening = false);
        if (words.trim().isNotEmpty) {
          _sendMessage(words.trim(), type: InputType.voice);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final eli5Mode = ref.watch(preferencesProvider).eli5Mode;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          // ELI5 toggle
          GestureDetector(
            onTap: () async {
              final prefs = ref.read(preferencesProvider);
              await ref.read(preferencesProvider.notifier).toggleEli5(!prefs.eli5Mode);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: eli5Mode
                    ? AppColors.amberAccent.withOpacity(0.15)
                    : AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: eli5Mode
                      ? AppColors.amberAccent
                      : AppColors.dividerColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.child_care_rounded,
                    color: eli5Mode ? AppColors.amberAccent : AppColors.textHint,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ELI5',
                    style: TextStyle(
                      color: eli5Mode ? AppColors.amberAccent : AppColors.textHint,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Clear chat
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            onPressed: () => ref.read(chatProvider.notifier).clearChat(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildWelcome()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _buildMessage(messages[i]),
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Welcome state ─────────────────────────────────────────────────────────

  Widget _buildWelcome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.purpleAi],
                ),
              ),
              child: const Center(
                child: Text('B', style: TextStyle(
                  color: Colors.white, fontSize: 36,
                  fontWeight: FontWeight.w800,
                )),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ask Briefly AI anything',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18, fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Paste a URL, type news text, or scan a newspaper.\nI\'ll summarise it in 3 bullet points.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Message rendering ─────────────────────────────────────────────────────

  Widget _buildMessage(ChatMessage msg) {
    if (msg.role == MessageRole.user) return _buildUserBubble(msg);
    if (msg.isLoading) return _buildShimmerCard();
    if (msg.error != null) return _buildErrorCard(msg);
    if (msg.summary != null) return _buildSummaryCard(msg);
    return const SizedBox.shrink();
  }

  Widget _buildUserBubble(ChatMessage msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.15),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (msg.inputType != InputType.text) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_inputIcon(msg.inputType),
                        color: AppColors.primaryBlue, size: 10),
                    const SizedBox(width: 3),
                    Text(msg.inputType.name.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primaryBlue, fontSize: 9,
                        fontWeight: FontWeight.w700,
                      )),
                  ],
                ),
              ),
            ],
            Text(
              msg.content.length > 200
                  ? '${msg.content.substring(0, 200)}…'
                  : msg.content,
              style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13, height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 48),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(color: AppColors.dividerColor),
        ),
        child: Shimmer.fromColors(
          baseColor: AppColors.dividerColor,
          highlightColor: AppColors.dividerColor.withOpacity(0.5),
          period: const Duration(milliseconds: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 180, height: 14,
                decoration: BoxDecoration(
                  color: AppColors.dividerColor,
                  borderRadius: BorderRadius.circular(4),
                )),
              const SizedBox(height: 12),
              Container(width: double.infinity, height: 10,
                decoration: BoxDecoration(
                  color: AppColors.dividerColor,
                  borderRadius: BorderRadius.circular(4),
                )),
              const SizedBox(height: 8),
              Container(width: double.infinity, height: 10,
                decoration: BoxDecoration(
                  color: AppColors.dividerColor,
                  borderRadius: BorderRadius.circular(4),
                )),
              const SizedBox(height: 8),
              Container(width: 140, height: 10,
                decoration: BoxDecoration(
                  color: AppColors.dividerColor,
                  borderRadius: BorderRadius.circular(4),
                )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(ChatMessage msg) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 48),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.redNegative.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(color: AppColors.redNegative.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.redNegative, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    msg.error ?? 'Something went wrong',
                    style: const TextStyle(
                      color: AppColors.redNegative, fontSize: 12, height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Retry: find the last user message and re-send
                final messages = ref.read(chatProvider);
                final lastUser = messages.lastWhere(
                  (m) => m.role == MessageRole.user,
                  orElse: () => msg,
                );
                if (lastUser.role == MessageRole.user) {
                  _sendMessage(lastUser.content, type: lastUser.inputType);
                }
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Retry',
                style: TextStyle(
                  color: AppColors.redNegative, fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ChatMessage msg) {
    final s = msg.summary!;
    final showTranslated = s.translatedHeadline != null;
    final headline = showTranslated ? s.translatedHeadline! : s.headline;
    final bullets = showTranslated ? s.translatedBullets! : s.bullets;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: AppColors.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sentiment badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _sentimentColor(s.sentiment).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: _sentimentColor(s.sentiment),
                          shape: BoxShape.circle,
                        )),
                      const SizedBox(width: 4),
                      Text(
                        '${s.sentiment[0].toUpperCase()}${s.sentiment.substring(1)} · ${(s.sentimentScore * 100).toInt()}%',
                        style: TextStyle(
                          color: _sentimentColor(s.sentiment),
                          fontSize: 10, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Bookmark
                GestureDetector(
                  onTap: () => ref.read(historyProvider.notifier).toggleBookmark(s.id),
                  child: Icon(
                    s.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: s.isBookmarked
                        ? AppColors.amberAccent
                        : AppColors.textHint,
                    size: 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Headline
            Text(
              headline,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15, fontWeight: FontWeight.w600, height: 1.3,
              ),
            ),

            const SizedBox(height: 12),

            // Numbered bullets
            ...bullets
                .asMap()
                .entries
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 18, height: 18,
                            margin: const EdgeInsets.only(right: 8, top: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('${e.key + 1}',
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 10, fontWeight: FontWeight.w700,
                                )),
                            ),
                          ),
                          Expanded(
                            child: Text(e.value,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13, height: 1.45,
                              )),
                          ),
                        ],
                      ),
                    )),

            const SizedBox(height: 10),

            // Action row
            Row(
              children: [
                // Translate
                _ActionChip(
                  icon: Icons.translate_rounded,
                  label: showTranslated ? 'Original' : 'Translate',
                  onTap: () async {
                    if (showTranslated) {
                      ref.read(chatProvider.notifier).revertTranslation(msg.id);
                      return;
                    }
                    await ref.read(chatProvider.notifier).translate(
                      messageId:      msg.id,
                      headline:       s.headline,
                      bullets:        s.bullets,
                      targetLanguage: ref.read(preferencesProvider).preferredLanguage,
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Share
                _ActionChip(
                  icon: Icons.ios_share_rounded,
                  label: 'Share',
                  onTap: () {
                    final buf = StringBuffer();
                    buf.writeln(headline);
                    buf.writeln();
                    for (var i = 0; i < bullets.length; i++) {
                      buf.writeln('${i + 1}. ${bullets[i]}');
                    }
                    buf.write('\n— Shared via Briefly AI');
                    Share.share(buf.toString());
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(
          color: AppColors.bgDark,
          border: Border(top: BorderSide(color: AppColors.dividerColor)),
        ),
        child: Row(
          children: [
            // Camera
            IconButton(
              icon: const Icon(Icons.document_scanner_rounded,
                  color: AppColors.amberAccent, size: 20),
              onPressed: _openCamera,
            ),
            // Mic — voice input
            IconButton(
              icon: Icon(
                _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                color: _isListening ? AppColors.redNegative : AppColors.purpleAi,
                size: 20,
              ),
              onPressed: _toggleListening,
            ),
            // Text input
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: (t) => _sendMessage(t),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Paste URL or type text…',
                  hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.bgCard,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                    borderSide: const BorderSide(color: AppColors.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                    borderSide: const BorderSide(color: AppColors.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                    borderSide: const BorderSide(color: AppColors.primaryBlue),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send
            GestureDetector(
              onTap: _isLoading ? null : () => _sendMessage(_controller.text),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _isLoading
                      ? AppColors.dividerColor
                      : AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  IconData _inputIcon(InputType type) {
    switch (type) {
      case InputType.voice: return Icons.mic_rounded;
      case InputType.url: return Icons.link_rounded;
      case InputType.ocr: return Icons.document_scanner_rounded;
      default: return Icons.text_fields_rounded;
    }
  }

  Color _sentimentColor(String sentiment) {
    switch (sentiment) {
      case 'positive': return AppColors.greenPositive;
      case 'negative': return AppColors.redNegative;
      default: return AppColors.textHint;
    }
  }
}

// ── Action chip widget ──────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bgCardAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textHint, size: 12),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 11,
              fontWeight: FontWeight.w500,
            )),
          ],
        ),
      ),
    );
  }
}
