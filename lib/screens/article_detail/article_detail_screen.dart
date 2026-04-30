// lib/screens/article_detail/article_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/summary.dart';
import '../../providers/history_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

class ArticleDetailScreen extends ConsumerStatefulWidget {
  final Summary summary;
  const ArticleDetailScreen({super.key, required this.summary});

  @override
  ConsumerState<ArticleDetailScreen> createState() =>
      _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen>
    with SingleTickerProviderStateMixin {
  late Summary _summary;
  bool _showTranslated = false;
  bool _translating = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _summary = widget.summary;
    _showTranslated = _summary.translatedHeadline != null;
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Computed helpers ────────────────────────────────────────────────────────

  Color get _sentimentColor {
    switch (_summary.sentiment) {
      case 'positive': return AppColors.greenPositive;
      case 'negative': return AppColors.redNegative;
      default:         return AppColors.textHint;
    }
  }

  String get _displayHeadline =>
      _showTranslated && _summary.translatedHeadline != null
          ? _summary.translatedHeadline!
          : _summary.headline;

  List<String> get _displayBullets =>
      _showTranslated && _summary.translatedBullets != null
          ? _summary.translatedBullets!
          : _summary.bullets;

  String get _timeAgo {
    final diff = DateTime.now().difference(_summary.createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return '${_summary.createdAt.day}/${_summary.createdAt.month}/${_summary.createdAt.year}';
  }

  IconData get _inputIcon {
    switch (_summary.inputType) {
      case 'voice': return Icons.mic_rounded;
      case 'url':   return Icons.link_rounded;
      case 'ocr':   return Icons.document_scanner_rounded;
      default:      return Icons.text_fields_rounded;
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _toggleBookmark() async {
    await ref.read(historyProvider.notifier).toggleBookmark(_summary.id);
    final updated = ref
        .read(historyProvider)
        .firstWhere((s) => s.id == _summary.id, orElse: () => _summary);
    if (mounted) {
      setState(() => _summary = _summary.copyWith(
            isBookmarked: updated.isBookmarked,
          ));
    }
  }

  void _share() {
    final buf = StringBuffer();
    buf.writeln(_displayHeadline);
    buf.writeln();
    for (var i = 0; i < _displayBullets.length; i++) {
      buf.writeln('${i + 1}. ${_displayBullets[i]}');
    }
    buf.write('\n— Shared via Briefly AI');
    Share.share(buf.toString());
  }

  void _copyToClipboard() {
    final buf = StringBuffer();
    buf.writeln(_displayHeadline);
    buf.writeln();
    for (var i = 0; i < _displayBullets.length; i++) {
      buf.writeln('${i + 1}. ${_displayBullets[i]}');
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Future<void> _handleTranslate() async {
    // Already translated — just toggle display
    if (_summary.translatedHeadline != null) {
      setState(() => _showTranslated = !_showTranslated);
      return;
    }

    final lang = ref.read(preferencesProvider).preferredLanguage;
    if (lang == 'en') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Set a non-English language in Settings to enable translation.'),
        ),
      );
      return;
    }

    setState(() => _translating = true);

    final result = await ApiService.instance.translate(
      headline:       _summary.headline,
      bullets:        _summary.bullets,
      targetLanguage: lang,
    );

    if (!mounted) return;
    setState(() => _translating = false);

    if (result.isSuccess) {
      final r = result.data!;
      setState(() {
        _summary = _summary.copyWith(
          translatedHeadline: r.translatedHeadline,
          translatedBullets:  r.translatedBullets,
          translatedTo:       lang,
        );
        _showTranslated = true;
      });
      // Persist to Hive so history list reflects the translation
      await ref.read(historyProvider.notifier).updateTranslation(
        _summary.id,
        translatedHeadline: r.translatedHeadline,
        translatedBullets:  r.translatedBullets,
        translatedTo:       lang,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Translation failed')),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppConstants.paddingLg, 20,
                  AppConstants.paddingLg, 48),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildMeta(),
                  const SizedBox(height: 20),
                  _buildHeadline(),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.dividerColor),
                  const SizedBox(height: 20),
                  _buildKeyPoints(),
                  if (_summary.sourceUrl != null) ...[
                    const SizedBox(height: 20),
                    _buildSourceLink(),
                  ],
                  if (_summary.translatedTo != null) ...[
                    const SizedBox(height: 14),
                    _buildTranslationBadge(),
                  ],
                  const SizedBox(height: 28),
                  _buildActions(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.bgDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_inputIcon, color: AppColors.textHint, size: 13),
          const SizedBox(width: 6),
          Text(
            _summary.inputType.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textHint,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            _summary.isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: _summary.isBookmarked
                ? AppColors.amberAccent
                : AppColors.textSecondary,
          ),
          onPressed: _toggleBookmark,
        ),
        IconButton(
          icon: const Icon(Icons.ios_share_rounded,
              color: AppColors.textSecondary),
          onPressed: _share,
        ),
      ],
    );
  }

  Widget _buildMeta() {
    return Row(
      children: [
        // Sentiment badge
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color:  _sentimentColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: _sentimentColor.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                    color: _sentimentColor,
                    shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                '${_summary.sentiment[0].toUpperCase()}'
                '${_summary.sentiment.substring(1)}'
                '  ·  '
                '${(_summary.sentimentScore.abs() * 100).toInt()}%',
                style: TextStyle(
                  color: _sentimentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(_timeAgo,
            style: const TextStyle(
                color: AppColors.textHint, fontSize: 11)),
      ],
    );
  }

  Widget _buildHeadline() {
    return Text(
      _displayHeadline,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildKeyPoints() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KEY POINTS',
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        ..._displayBullets.asMap().entries.map(
              (e) => _BulletPoint(index: e.key + 1, text: e.value),
            ),
      ],
    );
  }

  Widget _buildSourceLink() {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(
            ClipboardData(text: _summary.sourceUrl!));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Source URL copied')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius:
              BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(color: AppColors.dividerColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.link_rounded,
                color: AppColors.primaryBlue, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _summary.sourceUrl!,
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primaryBlue,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.copy_rounded,
                color: AppColors.textHint, size: 13),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationBadge() {
    final langName =
        AppConstants.supportedLanguages[_summary.translatedTo] ??
            _summary.translatedTo!.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.purpleAi.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purpleAi.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.translate_rounded,
              color: AppColors.purpleAi, size: 12),
          const SizedBox(width: 5),
          Text(
            _showTranslated
                ? 'Translated → $langName'
                : 'Showing original',
            style: const TextStyle(
              color: AppColors.purpleAi,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    String translateLabel;
    if (_translating) {
      translateLabel = 'Translating…';
    } else if (_summary.translatedHeadline != null) {
      translateLabel = _showTranslated ? 'Show Original' : 'Translated';
    } else {
      translateLabel = 'Translate';
    }

    return Row(
      children: [
        _ActionBtn(
          icon: _translating
              ? Icons.hourglass_empty_rounded
              : Icons.translate_rounded,
          label: translateLabel,
          accent: AppColors.purpleAi,
          onTap: _translating ? null : _handleTranslate,
        ),
        const SizedBox(width: 10),
        _ActionBtn(
          icon: Icons.ios_share_rounded,
          label: 'Share',
          accent: AppColors.primaryBlue,
          onTap: _share,
        ),
        const SizedBox(width: 10),
        _ActionBtn(
          icon: Icons.copy_rounded,
          label: 'Copy',
          accent: AppColors.amberAccent,
          onTap: _copyToClipboard,
        ),
      ],
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _BulletPoint extends StatelessWidget {
  final int index;
  final String text;
  const _BulletPoint({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(right: 12, top: 1),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.purpleAi],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: onTap == null ? 0.4 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusMd),
              border: Border.all(color: accent.withOpacity(0.30)),
            ),
            child: Column(
              children: [
                Icon(icon, color: accent, size: 18),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
