// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../models/summary.dart';
import '../../models/insight.dart';
import '../../providers/history_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/insights_provider.dart';
import '../analytics/analytics_screen.dart';
import '../chat/chat_screen.dart';
import '../camera/camera_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../article_detail/article_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [
      _HomeFeedView(),
      ChatScreen(),
      AnalyticsScreen(),
      HistoryScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: IndexedStack(index: _selectedIndex, children: pages),

      // FAB (Camera)
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CameraScreen()),
        ),
        backgroundColor: AppColors.amberAccent,
        child: const Icon(Icons.document_scanner_rounded, color: Colors.black, size: 22),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.dividerColor)),
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex > 1 ? _selectedIndex + 1 : _selectedIndex,
        onDestinationSelected: (i) {
          // Skip index 2 (FAB slot)
          setState(() => _selectedIndex = i > 2 ? i - 1 : i);
        },
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: SizedBox.shrink(), // FAB slot
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

// ─── Home Feed ───────────────────────────────────────────────────────────────

class _HomeFeedView extends ConsumerWidget {
  const _HomeFeedView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 18 ? 'Good Afternoon' : 'Good Evening';
    final insightAsync = ref.watch(insightDataProvider);
    final history = ref.watch(historyProvider);
    final recent  = history.take(5).toList();
    final prefs   = ref.watch(preferencesProvider);
    final displayName = prefs.displayName.isNotEmpty ? prefs.displayName : 'User';
    final initial = displayName[0].toUpperCase();

    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          pinned: true,
          title: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.purpleAi],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('B', style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Briefly AI'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {},
            ),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                width: 32, height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.amberAccent, AppColors.primaryBlue],
                  ),
                ),
                child: Center(
                  child: Text(initial,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.all(AppConstants.paddingLg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Greeting
              Text('$greeting 👋',
                style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 4),
              const Text('Here\'s your news briefing',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 20),

              // Quick action pills
              _QuickActions(),

              const SizedBox(height: 24),

              // InsightLens widget — live data from API
              insightAsync.when(
                data:    (data)  => _InsightLensCard(data: data),
                loading: ()      => const _InsightLensCardShimmer(),
                error:   (_, __) => _InsightLensCard(data: InsightData.mock()),
              ),

              const SizedBox(height: 24),

              // Recent summaries section
              Row(
                children: [
                  const Text('Recent Summaries',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17, fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const HistoryScreen())),
                    child: const Text('See all',
                      style: TextStyle(color: AppColors.primaryBlue, fontSize: 13)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (recent.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                    border: Border.all(color: AppColors.dividerColor),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.history_rounded, color: AppColors.textHint, size: 36),
                      SizedBox(height: 8),
                      Text('No summaries yet. Start chatting!',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                )
              else
                ...recent.map((s) => _SummaryListTile(summary: s)),

              const SizedBox(height: 80), // FAB clearance
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionPill(
          icon: Icons.link_rounded,
          label: 'Paste URL',
          color: AppColors.primaryBlue,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ChatScreen())),
        ),
        const SizedBox(width: 10),
        _ActionPill(
          icon: Icons.mic_rounded,
          label: 'Voice',
          color: AppColors.purpleAi,
          onTap: () {},
        ),
        const SizedBox(width: 10),
        _ActionPill(
          icon: Icons.document_scanner_rounded,
          label: 'Scan',
          color: AppColors.amberAccent,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CameraScreen())),
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionPill({required this.icon, required this.label,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: color,
                  fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── InsightLens Card ─────────────────────────────────────────────────────────

class _InsightLensCard extends StatelessWidget {
  final InsightData data;
  const _InsightLensCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryBlue.withOpacity(0.12),
              AppColors.purpleAi.withOpacity(0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.insights_rounded,
                  color: AppColors.primaryBlue, size: 18),
                SizedBox(width: 6),
                Text('InsightLens',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3,
                  ),
                ),
                Spacer(),
                Text('Today',
                  style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.textHint, size: 11),
              ],
            ),
            const SizedBox(height: 16),

            // Sentiment bar
            const Text('Sentiment Overview',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15, fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text('${data.totalArticlesAnalyzed} articles analysed',
              style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  Flexible(
                    flex: data.positivePercent.toInt(),
                    child: Container(
                      height: 8,
                      color: AppColors.greenPositive,
                    ),
                  ),
                  Flexible(
                    flex: data.neutralPercent.toInt(),
                    child: Container(
                      height: 8,
                      color: AppColors.textHint,
                    ),
                  ),
                  Flexible(
                    flex: data.negativePercent.toInt(),
                    child: Container(
                      height: 8,
                      color: AppColors.redNegative,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            Row(
              children: [
                _SentimentDot(color: AppColors.greenPositive,
                    label: '${data.positivePercent.toInt()}% Positive'),
                const SizedBox(width: 16),
                _SentimentDot(color: AppColors.textHint,
                    label: '${data.neutralPercent.toInt()}% Neutral'),
                const SizedBox(width: 16),
                _SentimentDot(color: AppColors.redNegative,
                    label: '${data.negativePercent.toInt()}% Negative'),
              ],
            ),

            const SizedBox(height: 16),

            // Hot topics
            const Text('Hot Topics',
              style: TextStyle(color: AppColors.textPrimary,
                  fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 6,
              children: data.hotTopics.take(4).map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.dividerColor),
                ),
                child: Text(t,
                  style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SentimentDot extends StatelessWidget {
  final Color color;
  final String label;
  const _SentimentDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(
        color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(
        color: AppColors.textHint, fontSize: 10)),
    ],
  );
}

// ─── InsightLens Shimmer (loading state) ──────────────────────────────────────

class _InsightLensCardShimmer extends StatelessWidget {
  const _InsightLensCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBox(120, 14),
          const SizedBox(height: 16),
          _shimmerBox(180, 16),
          const SizedBox(height: 8),
          _shimmerBox(100, 12),
          const SizedBox(height: 12),
          _shimmerBox(double.infinity, 8),
          const SizedBox(height: 16),
          Row(
            children: [
              _shimmerBox(80, 12),
              const SizedBox(width: 16),
              _shimmerBox(80, 12),
              const SizedBox(width: 16),
              _shimmerBox(80, 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.dividerColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ─── Summary List Tile (uses real Summary model) ──────────────────────────────

class _SummaryListTile extends StatelessWidget {
  final Summary summary;
  const _SummaryListTile({required this.summary});

  Color get _sentimentColor {
    switch (summary.sentiment) {
      case 'positive': return AppColors.greenPositive;
      case 'negative': return AppColors.redNegative;
      default: return AppColors.textHint;
    }
  }

  String get _timeAgo {
    final diff = DateTime.now().difference(summary.createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${summary.createdAt.day}/${summary.createdAt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ArticleDetailScreen(summary: summary))),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _sentimentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: _sentimentColor, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(summary.sentiment[0].toUpperCase() +
                        summary.sentiment.substring(1),
                      style: TextStyle(color: _sentimentColor,
                          fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Spacer(),
              Text(_timeAgo,
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 11)),
            ],
          ),

          const SizedBox(height: 10),

          Text(summary.headline,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14, fontWeight: FontWeight.w600, height: 1.35,
            ),
          ),

          const SizedBox(height: 10),

          ...summary.bullets.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 4, height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(b,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12, height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(_inputIcon, color: AppColors.textHint, size: 12),
              const SizedBox(width: 4),
              Text(summary.inputType,
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 11)),
              const Spacer(),
              Icon(
                summary.isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: summary.isBookmarked
                    ? AppColors.amberAccent
                    : AppColors.textHint,
                size: 16,
              ),
              const SizedBox(width: 12),
              const Icon(Icons.ios_share_rounded,
                  color: AppColors.textHint, size: 16),
            ],
          ),
        ],
      ),
    ),
    );
  }

  IconData get _inputIcon {
    switch (summary.inputType) {
      case 'voice': return Icons.mic_rounded;
      case 'url':   return Icons.link_rounded;
      case 'ocr':   return Icons.document_scanner_rounded;
      default:      return Icons.text_fields_rounded;
    }
  }
}