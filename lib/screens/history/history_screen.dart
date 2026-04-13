// lib/screens/history/history_screen.dart
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
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

class _HistoryList extends StatelessWidget {
  final String searchQuery;
  final bool bookmarkedOnly;
  const _HistoryList({required this.searchQuery, required this.bookmarkedOnly});

  @override
  Widget build(BuildContext context) {
    // Mock data
    final all = _mockHistory();
    final filtered = all.where((h) {
      if (bookmarkedOnly && !h.bookmarked) return false;
      if (searchQuery.isNotEmpty &&
          !h.headline.toLowerCase().contains(searchQuery.toLowerCase())) return false;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              bookmarkedOnly
                  ? Icons.bookmark_border_rounded
                  : Icons.history_rounded,
              color: AppColors.textHint, size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              bookmarkedOnly
                  ? 'No bookmarks yet'
                  : searchQuery.isNotEmpty
                      ? 'No results found'
                      : 'No summaries yet',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    // Group by date
    final Map<String, List<_HistoryItem>> grouped = {};
    for (final h in filtered) {
      grouped.putIfAbsent(h.dateGroup, () => []).add(h);
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
          ...entry.value.map((h) => _HistoryTile(item: h)),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  List<_HistoryItem> _mockHistory() => [
    _HistoryItem(
      id: '1',
      headline: 'NVIDIA surpasses \$3T market cap amid AI chip demand surge',
      source: 'Reuters', timeAgo: '2h ago', sentiment: 'positive',
      inputType: 'url', bookmarked: true, dateGroup: 'TODAY',
    ),
    _HistoryItem(
      id: '2',
      headline: 'Pakistan\'s IMF deal faces fresh hurdle over energy reforms',
      source: 'Dawn', timeAgo: '5h ago', sentiment: 'negative',
      inputType: 'voice', bookmarked: false, dateGroup: 'TODAY',
    ),
    _HistoryItem(
      id: '3',
      headline: 'OpenAI releases GPT-5 with multimodal reasoning capabilities',
      source: 'The Verge', timeAgo: 'Yesterday', sentiment: 'positive',
      inputType: 'text', bookmarked: true, dateGroup: 'YESTERDAY',
    ),
    _HistoryItem(
      id: '4',
      headline: 'Fed holds rates steady; signals one cut in 2026',
      source: 'WSJ', timeAgo: 'Yesterday', sentiment: 'neutral',
      inputType: 'url', bookmarked: false, dateGroup: 'YESTERDAY',
    ),
    _HistoryItem(
      id: '5',
      headline: 'KSE-100 closes above 93,000 on IMF optimism',
      source: 'Geo News', timeAgo: '3 days ago', sentiment: 'positive',
      inputType: 'ocr', bookmarked: false, dateGroup: 'EARLIER',
    ),
  ];
}

class _HistoryItem {
  final String id, headline, source, timeAgo, sentiment, inputType, dateGroup;
  final bool bookmarked;
  const _HistoryItem({
    required this.id, required this.headline, required this.source,
    required this.timeAgo, required this.sentiment, required this.inputType,
    required this.bookmarked, required this.dateGroup,
  });
}

class _HistoryTile extends StatelessWidget {
  final _HistoryItem item;
  const _HistoryTile({required this.item});

  Color get _sentimentColor {
    switch (item.sentiment) {
      case 'positive': return AppColors.greenPositive;
      case 'negative': return AppColors.redNegative;
      default: return AppColors.textHint;
    }
  }

  IconData get _inputIcon {
    switch (item.inputType) {
      case 'voice': return Icons.mic_rounded;
      case 'url':   return Icons.link_rounded;
      case 'ocr':   return Icons.document_scanner_rounded;
      default:      return Icons.text_fields_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text(item.headline,
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
                    Text(item.source,
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 10)),
                    const SizedBox(width: 8),
                    const Text('·',
                      style: TextStyle(color: AppColors.textHint, fontSize: 10)),
                    const SizedBox(width: 8),
                    Text(item.timeAgo,
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Bookmark icon
          Icon(
            item.bookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: item.bookmarked
                ? AppColors.amberAccent
                : AppColors.textHint,
            size: 18,
          ),
        ],
      ),
    );
  }
}