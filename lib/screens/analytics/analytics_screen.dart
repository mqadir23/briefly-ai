// lib/screens/analytics/analytics_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../models/insight.dart';
import '../../services/api_service.dart';
import '../../providers/preferences_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedTime = 'Last 7 Days';
  String _selectedRegion = 'Global';
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  InsightData? _data;
  AdvancedMiningData? _advancedData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _loadInsights();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final prefs = ref.read(preferencesProvider);
    final insightsFuture = ApiService.instance.getInsights(
      region: _selectedRegion,
      timeFilter: _selectedTime,
      interests: prefs.interests,
    );

    // Using mock for advanced mining for now as we just added the endpoint
    // In a real app, you'd fetch it from ApiService
    await Future.delayed(const Duration(milliseconds: 800));

    final result = await insightsFuture;
    final miningResult = await ApiService.instance.getAdvancedMining(region: _selectedRegion);

    if (!mounted) return;

    if (result.isSuccess) {
      final r = result.data!;
      setState(() {
        _data = InsightData(
          positivePercent: r.positivePercent,
          neutralPercent: r.neutralPercent,
          negativePercent: r.negativePercent,
          totalArticlesAnalyzed: r.totalArticles,
          hotTopics: r.hotTopics,
          trendPoints: r.trendPoints
              .map((tp) => TrendPoint(
                    label: tp['date']?.toString() ?? '',
                    value: (tp['value'] ?? 0.0).toDouble(),
                  ))
              .toList(),
          topEntities: r.topEntities
              .map((te) => TopEntity(
                    name: te['name']?.toString() ?? '',
                    mentions: (te['mentions'] ?? 0) as int,
                    sentiment: te['sentiment']?.toString() ?? 'neutral',
                    type: te['type']?.toString() ?? 'company',
                  ))
              .toList(),
          sentimentVolatility: (result.data?.data?['sentiment_volatility'] ?? 0.0).toDouble(),
          entityPulse: (result.data?.data?['entity_pulse'] as List? ?? [])
              .map((ep) => EntityPulse(
                    name: ep['name']?.toString() ?? '',
                    points: List<double>.from((ep['pulse'] as List? ?? [])
                        .map((p) => (p ?? 0.0).toDouble())),
                  ))
              .toList(),
        );
        
        if (miningResult.isSuccess) {
          final m = miningResult.data!;
          _advancedData = AdvancedMiningData(
            network: (m['keyword_network'] as List? ?? []).map((n) => KeywordRelation(
              source: n['source'] ?? '',
              target: n['target'] ?? '',
              weight: (n['weight'] ?? 1) as int,
            )).toList(),
            sentimentDistribution: Map<String, int>.from(m['sentiment_distribution'] ?? {}),
            trends: (m['emerging_trends'] as List? ?? []).map((t) => EmergingTrend(
              topic: t['topic'] ?? '',
              strength: (t['strength'] ?? 0.0).toDouble(),
            )).toList(),
          );
        } else {
          _advancedData = AdvancedMiningData.mock();
        }
        
        _loading = false;
      });
      _fadeCtrl.reset();
      _fadeCtrl.forward();
    } else {
      setState(() {
        _data = InsightData.mock();
        _advancedData = AdvancedMiningData.mock();
        _loading = false;
        _error = result.error;
      });
      _fadeCtrl.reset();
      _fadeCtrl.forward();
    }
  }

  void _onFilterChange() {
    _loadInsights();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100, right: -50,
            child: _GlowOrb(color: AppColors.primaryBlue.withOpacity(0.15), size: 300),
          ),
          Positioned(
            bottom: 100, left: -50,
            child: _GlowOrb(color: AppColors.purpleAi.withOpacity(0.1), size: 250),
          ),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                if (_loading)
                  SliverFillRemaining(child: _buildLoadingState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(AppConstants.paddingLg),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (_error != null) ...[
                          _buildErrorBanner(),
                          const SizedBox(height: 12),
                        ],
                        _buildFilters(),
                        const SizedBox(height: 24),
                        
                        _GlassCard(
                          title: 'Sentiment Distribution',
                          icon: Icons.pie_chart_rounded,
                          child: _buildSentimentPie(),
                        ),
                        const SizedBox(height: 20),

                        _GlassCard(
                          title: 'News Pulse',
                          icon: Icons.show_chart_rounded,
                          child: _buildTrendChart(),
                        ),
                        const SizedBox(height: 20),

                        _GlassCard(
                          title: 'Entity Volatility',
                          icon: Icons.analytics_rounded,
                          child: _buildVolatilityPulse(),
                        ),
                        const SizedBox(height: 20),

                        _GlassCard(
                          title: 'Top Entities',
                          icon: Icons.people_alt_rounded,
                          child: _buildTopEntities(),
                        ),
                        const SizedBox(height: 20),

                        _GlassCard(
                          title: 'Hot Topics',
                          icon: Icons.local_fire_department_rounded,
                          child: _buildHotTopics(),
                        ),
                        const SizedBox(height: 20),

                        _GlassCard(
                          title: 'Keyword Network (Data Mining)',
                          icon: Icons.hub_rounded,
                          child: _buildKeywordNetwork(),
                        ),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text('Advanced Analytics', 
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _onFilterChange,
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: _FilterDropdown(
            value: _selectedTime,
            items: AppConstants.timeFilters,
            icon: Icons.access_time_rounded,
            onChanged: (v) {
              setState(() => _selectedTime = v!);
              _onFilterChange();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FilterDropdown(
            value: _selectedRegion,
            items: AppConstants.regions,
            icon: Icons.public_rounded,
            onChanged: (v) {
              setState(() => _selectedRegion = v!);
              _onFilterChange();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSentimentPie() {
    final d = _data!;
    return Row(
      children: [
        SizedBox(
          width: 140, height: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 35,
              sections: [
                PieChartSectionData(
                  value: d.positivePercent,
                  color: AppColors.greenPositive,
                  radius: 12, showTitle: false,
                ),
                PieChartSectionData(
                  value: d.neutralPercent,
                  color: AppColors.textHint,
                  radius: 10, showTitle: false,
                ),
                PieChartSectionData(
                  value: d.negativePercent,
                  color: AppColors.redNegative,
                  radius: 12, showTitle: false,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PieLegend(color: AppColors.greenPositive, label: 'Positive', percent: d.positivePercent),
              const SizedBox(height: 8),
              _PieLegend(color: AppColors.textHint, label: 'Neutral', percent: d.neutralPercent),
              const SizedBox(height: 8),
              _PieLegend(color: AppColors.redNegative, label: 'Negative', percent: d.negativePercent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChart() {
    final spots = _data!.trendPoints.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), e.value.value)).toList();

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primaryBlue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.3),
                    AppColors.primaryBlue.withOpacity(0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolatilityPulse() {
    final pulse = _data!.entityPulse;
    if (pulse.isEmpty) return const Center(child: Text('No pulse data'));

    return Column(
      children: pulse.map((p) {
        final spots = p.points.asMap().entries.map((e) =>
            FlSpot(e.key.toDouble(), e.value)).toList();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(width: 70, child: Text(p.name, 
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
              Expanded(
                child: SizedBox(
                  height: 30,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppColors.purpleAi,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopEntities() {
    return Column(
      children: _data!.topEntities.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(e.type == 'company' ? Icons.business_rounded : Icons.person_rounded, 
                color: AppColors.textHint, size: 16),
            const SizedBox(width: 12),
            Expanded(child: Text(e.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14))),
            Text('${e.mentions} mentions', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
            const SizedBox(width: 12),
            Container(width: 6, height: 6, decoration: BoxDecoration(
              color: e.sentiment == 'positive' ? AppColors.greenPositive : AppColors.redNegative,
              shape: BoxShape.circle,
            )),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildHotTopics() {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: _data!.hotTopics.map((t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
        ),
        child: Text(t, style: const TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.w600)),
      )).toList(),
    );
  }

  Widget _buildKeywordNetwork() {
    final net = _advancedData!.network;
    return Column(
      children: net.map((n) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            _Pill(n.source),
            const Icon(Icons.link_rounded, color: AppColors.textHint, size: 14),
            _Pill(n.target),
            Text('weight: ${n.weight}', style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.redNegative.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('Error: $_error', style: const TextStyle(color: AppColors.redNegative, fontSize: 12)),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _GlassCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primaryBlue, size: 18),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: size / 2, spreadRadius: 0)],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCardAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
    );
  }
}

class _PieLegend extends StatelessWidget {
  final Color color;
  final String label;
  final double percent;
  const _PieLegend({required this.color, required this.label, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const Spacer(),
        Text('${percent.toInt()}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String?> onChanged;
  const _FilterDropdown({required this.value, required this.items,
    required this.icon, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.bgCardAlt,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint, size: 18),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          items: items.map((i) => DropdownMenuItem(
            value: i,
            child: Row(
              children: [
                Icon(icon, color: AppColors.textHint, size: 14),
                const SizedBox(width: 8),
                Text(i),
              ],
            ),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
