// lib/screens/history/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../models/summary.dart';
import '../../providers/history_provider.dart';
import '../article_detail/article_detail_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primaryBlue,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'All Briefs'),
            Tab(text: 'Bookmarked'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMd),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14),
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search summaries…',
                prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textHint, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                    color: AppColors.textHint, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _HistoryList(searchQuery: _searchQuery, bookmarkedOnly: false),
                _HistoryList(searchQuery: _searchQuery, bookmarkedOnly: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  final String searchQuery;
  final bool bookmarkedOnly;
  const _HistoryList({required this.searchQuery, required this.bookmarkedOnly});

  String _dateGroup(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date  = DateTime(dt.year, dt.month, dt.day);
    final diff  = today.difference(date).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    return '${dt.day.toString().padLeft(2, '0')} ${_monthName(dt.month)}';
  }

  String _monthName(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final notifier = ref.read(historyProvider.notifier);

    List<Summary> filtered;
    if (bookmarkedOnly) {
      filtered = notifier.bookmarked;
    } else if (searchQuery.isNotEmpty) {
      filtered = notifier.search(searchQuery);
    } else {
      filtered = history;
    }

    // Also apply search to bookmarked
    if (bookmarkedOnly && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered.where((s) =>
          s.headline.toLowerCase().contains(q) ||
          s.originalText.toLowerCase().contains(q)).toList();
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              bookmarkedOnly
                  ? Icons.bookmark_border_rounded
                  : searchQuery.isNotEmpty
                      ? Icons.search_off_rounded
                      : Icons.history_rounded,
              color: AppColors.textHint, size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              bookmarkedOnly
                  ? 'No bookmarks yet'
                  : searchQuery.isNotEmpty
                      ? 'No results for \'$searchQuery\''
                      : 'No summaries yet. Start chatting!',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    // Group by date
    final Map<String, List<Summary>> grouped = {};
    for (final s in filtered) {
      final group = _dateGroup(s.createdAt);
      grouped.putIfAbsent(group, () => []).add(s);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(entry.key,
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8,
              ),
            ),
          ),
          ...entry.value.map((s) => _HistoryTile(
            summary: s,
            timeAgo: _timeAgo(s.createdAt),
            onBookmarkTap: () => ref.read(historyProvider.notifier).toggleBookmark(s.id),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => ArticleDetailScreen(summary: s))),
          )),
        ],
        const SizedBox(height: 80),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Summary summary;
  final String timeAgo;
  final VoidCallback onBookmarkTap;
  final VoidCallback? onTap;
  const _HistoryTile({required this.summary, required this.timeAgo,
    required this.onBookmarkTap, this.onTap});

  Color get _sentimentColor {
    switch (summary.sentiment) {
      case 'positive': return AppColors.greenPositive;
      case 'negative': return AppColors.redNegative;
      default: return AppColors.textHint;
    }
  }

  IconData get _inputIcon {
    switch (summary.inputType) {
      case 'voice': return Icons.mic_rounded;
      case 'url':   return Icons.link_rounded;
      case 'ocr':   return Icons.document_scanner_rounded;
      default:      return Icons.text_fields_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: sentiment bar
          Container(
            width: 3, height: 56,
            decoration: BoxDecoration(
              color: _sentimentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summary.headline,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13, fontWeight: FontWeight.w500, height: 1.35,
                  ),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(_inputIcon, color: AppColors.textHint, size: 10),
                    const SizedBox(width: 4),
                    Text(summary.inputType,
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 10)),
                    const SizedBox(width: 8),
                    const Text('·',
                      style: TextStyle(color: AppColors.textHint, fontSize: 10)),
                    const SizedBox(width: 8),
                    Text(timeAgo,
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Bookmark icon
          GestureDetector(
            onTap: onBookmarkTap,
            child: Icon(
              summary.isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: summary.isBookmarked
                  ? AppColors.amberAccent
                  : AppColors.textHint,
              size: 18,
            ),
          ),
        ],
      ),
    ),
    );
  }
}