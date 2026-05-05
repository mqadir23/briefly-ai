// lib/screens/home/home_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
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
    final displayName = prefs.displayName.isNotEmpty ? prefs.displayName : (prefs.email.isNotEmpty ? prefs.email.split('@')[0] : 'User');
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Stack(
      children: [
        Positioned(top: -50, right: -50, child: _Glow(color: AppColors.primaryBlue.withOpacity(0.08))),
        CustomScrollView(
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
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  const _Glow({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: 300, height: 300, decoration: BoxDecoration(
      shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 150, spreadRadius: 0)],
    ));
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
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ChatScreen(startWithVoice: true))),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
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

                Builder(
                  builder: (context) {
                    final pos = data.positivePercent.toInt();
                    final neu = data.neutralPercent.toInt();
                    final neg = data.negativePercent.toInt();
                    final total = pos + neu + neg;
                    
                    if (total == 0) {
                      return Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.dividerColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    }

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: [
                          if (pos > 0)
                            Flexible(
                              flex: pos,
                              child: Container(height: 8, color: AppColors.greenPositive),
                            ),
                          if (neu > 0)
                            Flexible(
                              flex: neu,
                              child: Container(height: 8, color: AppColors.textHint),
                            ),
                          if (neg > 0)
                            Flexible(
                              flex: neg,
                              child: Container(height: 8, color: AppColors.redNegative),
                            ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
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
    return Shimmer.fromColors(
      baseColor: AppColors.dividerColor,
      highlightColor: AppColors.dividerColor.withOpacity(0.5),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
      ),
    );
  }
}

// ─── Summary List Tile ────────────────────────────────────────────────────────

class _SummaryListTile extends StatelessWidget {
  final Summary summary;
  const _SummaryListTile({required this.summary});

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
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(color: AppColors.dividerColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.article_rounded, color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(summary.headline,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14, fontWeight: FontWeight.w600, height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: summary.sentiment == 'positive'
                              ? AppColors.greenPositive
                              : summary.sentiment == 'negative'
                              ? AppColors.redNegative
                              : AppColors.textHint,
                          shape: BoxShape.circle,
                        )),
                      const SizedBox(width: 6),
                      Text('${summary.sentiment[0].toUpperCase()}${summary.sentiment.substring(1)}',
                        style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}