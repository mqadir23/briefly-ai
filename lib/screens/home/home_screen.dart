// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../models/insight.dart';
import '../analytics/analytics_screen.dart';
import '../chat/chat_screen.dart';
import '../camera/camera_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    _HomeFeedView(),
    ChatScreen(),
    AnalyticsScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: IndexedStack(index: _selectedIndex, children: _pages),

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

class _HomeFeedView extends StatelessWidget {
  const _HomeFeedView();

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 18 ? 'Good Afternoon' : 'Good Evening';
    final insightData = InsightData.mock();

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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.amberAccent, AppColors.primaryBlue],
                  ),
                ),
                child: const Center(
                  child: Text('D',
                    style: TextStyle(color: Colors.white,
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

              // InsightLens widget
              _InsightLensCard(data: insightData),

              const SizedBox(height: 24),

              // Recent summaries section
              const Row(
                children: [
                  Text('Recent Summaries',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17, fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Text('See all',
                    style: TextStyle(color: AppColors.primaryBlue, fontSize: 13)),
                ],
              ),

              const SizedBox(height: 12),

              ..._mockSummaries().map((s) => _SummaryListTile(summary: s)),

              const SizedBox(height: 80), // FAB clearance
            ]),
          ),
        ),
      ],
    );
  }

  List<_MockSummary> _mockSummaries() => [
    _MockSummary(
      headline: 'NVIDIA surpasses \$3T market cap amid AI chip demand surge',
      bullets: ['Revenue up 122% YoY', 'H100 GPU demand still outpacing supply', 'New Blackwell architecture ships Q2'],
      sentiment: 'positive',
      timeAgo: '2h ago',
      source: 'Reuters',
    ),
    _MockSummary(
      headline: 'Pakistan\'s IMF deal faces fresh hurdle over energy reforms',
      bullets: ['IMF demands circular debt plan', 'Govt. proposes 3-year restructuring', 'Next tranche of \$1.1B at stake'],
      sentiment: 'negative',
      timeAgo: '5h ago',
      source: 'Dawn',
    ),
    _MockSummary(
      headline: 'OpenAI releases GPT-5 with multimodal reasoning capabilities',
      bullets: ['Significantly better at complex reasoning', 'Native image & audio understanding', 'Available to Plus subscribers first'],
      sentiment: 'positive',
      timeAgo: '8h ago',
      source: 'The Verge',
    ),
  ];
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
            Row(
              children: [
                const Icon(Icons.insights_rounded,
                  color: AppColors.primaryBlue, size: 18),
                const SizedBox(width: 6),
                const Text('InsightLens',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                const Text('Today',
                  style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded,
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

// ─── Summary List Tile ────────────────────────────────────────────────────────

class _MockSummary {
  final String headline, sentiment, timeAgo, source;
  final List<String> bullets;
  const _MockSummary({
    required this.headline, required this.bullets,
    required this.sentiment, required this.timeAgo, required this.source,
  });
}

class _SummaryListTile extends StatelessWidget {
  final _MockSummary summary;
  const _SummaryListTile({required this.summary});

  Color get _sentimentColor {
    switch (summary.sentiment) {
      case 'positive': return AppColors.greenPositive;
      case 'negative': return AppColors.redNegative;
      default: return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Text(summary.timeAgo,
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
              const Icon(Icons.language_rounded,
                  color: AppColors.textHint, size: 12),
              const SizedBox(width: 4),
              Text(summary.source,
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 11)),
              const Spacer(),
              const Icon(Icons.bookmark_border_rounded,
                  color: AppColors.textHint, size: 16),
              const SizedBox(width: 12),
              const Icon(Icons.ios_share_rounded,
                  color: AppColors.textHint, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}