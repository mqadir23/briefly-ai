// lib/screens/analytics/analytics_screen.dart
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
  String _selectedTime   = 'Last 7 Days';
  String _selectedRegion = 'Global';
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;
  InsightData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _loadInsights();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Future<void> _loadInsights() async {
    setState(() { _loading = true; _error = null; });

    final prefs  = ref.read(preferencesProvider);
    final result = await ApiService.instance.getInsights(
      region:     _selectedRegion,
      timeFilter: _selectedTime,
      interests:  prefs.interests,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      final r = result.data!;
      setState(() {
        _data = InsightData(
          positivePercent: r.positivePercent,
          neutralPercent:  r.neutralPercent,
          negativePercent: r.negativePercent,
          totalArticlesAnalyzed: r.totalArticles,
          hotTopics: r.hotTopics,
          trendPoints: r.trendPoints.map((tp) => TrendPoint(
            label: tp['date']?.toString() ?? '',
            value: (tp['value'] ?? 0.0).toDouble(),
          )).toList(),
          topEntities: r.topEntities.map((te) => TopEntity(
            name:      te['name']?.toString() ?? '',
            mentions:  (te['mentions'] ?? 0) as int,
            sentiment: te['sentiment']?.toString() ?? 'neutral',
            type:      te['type']?.toString() ?? 'company',
          )).toList(),
        );
        _loading = false;
      });
      _fadeCtrl.reset();
      _fadeCtrl.forward();
    } else {
      // Fallback to mock data on error
      setState(() {
        _data = InsightData.mock();
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
      appBar: AppBar(
        title: const Text('InsightLens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _onFilterChange,
          ),
        ],
      ),
      body: _loading
          ? _buildLoadingState()
          : FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(AppConstants.paddingLg),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Error banner
                        if (_error != null) ...[
                          _buildErrorBanner(),
                          const SizedBox(height: 12),
                        ],

                        // Filters
                        _buildFilters(),
                        const SizedBox(height: 24),

                        // Stats row
                        _buildStatsRow(),
                        const SizedBox(height: 24),

                        // Trend line chart
                        _buildSectionHeader('News Volume Trend', Icons.show_chart_rounded),
                        const SizedBox(height: 12),
                        _buildTrendChart(),
                        const SizedBox(height: 24),

                        // Sentiment pie
                        _buildSectionHeader('Sentiment Breakdown', Icons.pie_chart_rounded),
                        const SizedBox(height: 12),
                        _buildSentimentPie(),
                        const SizedBox(height: 24),

                        // Hot topics
                        _buildSectionHeader('Hot Topics', Icons.local_fire_department_rounded),
                        const SizedBox(height: 12),
                        _buildHotTopics(),
                        const SizedBox(height: 24),

                        // Top entities
                        _buildSectionHeader('Top Entities', Icons.people_alt_rounded),
                        const SizedBox(height: 12),
                        _buildTopEntities(),

                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLg),
      child: Shimmer.fromColors(
        baseColor: AppColors.dividerColor,
        highlightColor: AppColors.dividerColor.withOpacity(0.5),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter shimmer
              Row(
                children: [
                Expanded(child: Container(height: 40, decoration: BoxDecoration(
                  color: AppColors.dividerColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm)))),
                const SizedBox(width: 10),
                Expanded(child: Container(height: 40, decoration: BoxDecoration(
                  color: AppColors.dividerColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm)))),
              ],
            ),
            const SizedBox(height: 24),
            // Stats shimmer
            Row(
              children: List.generate(3, (_) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.dividerColor,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd)),
                ),
              )),
            ),
            const SizedBox(height: 24),
            // Chart shimmer
            Container(height: 180, decoration: BoxDecoration(
              color: AppColors.dividerColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusLg))),
            const SizedBox(height: 24),
            // Pie shimmer
            Container(height: 170, decoration: BoxDecoration(
              color: AppColors.dividerColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusLg))),
            const SizedBox(height: 24),
            // Entity rows shimmer
            ...List.generate(4, (_) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 48, decoration: BoxDecoration(
                color: AppColors.dividerColor,
                borderRadius: BorderRadius.circular(AppConstants.radiusMd)),
            )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amberAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(color: AppColors.amberAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.amberAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Using demo data — $_error',
              style: const TextStyle(
                color: AppColors.amberAccent, fontSize: 11, height: 1.3),
            ),
          ),
          GestureDetector(
            onTap: _loadInsights,
            child: const Icon(Icons.refresh_rounded,
                color: AppColors.amberAccent, size: 16),
          ),
        ],
      ),
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
        const SizedBox(width: 10),
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

  Widget _buildStatsRow() {
    final data = _data!;
    return Row(
      children: [
        _StatCard(
          label: 'Articles',
          value: '${data.totalArticlesAnalyzed}',
          icon: Icons.article_rounded,
          color: AppColors.primaryBlue,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Positive',
          value: '${data.positivePercent.toInt()}%',
          icon: Icons.trending_up_rounded,
          color: AppColors.greenPositive,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Negative',
          value: '${data.negativePercent.toInt()}%',
          icon: Icons.trending_down_rounded,
          color: AppColors.redNegative,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 16),
        const SizedBox(width: 8),
        Text(title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16, fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChart() {
    final data = _data!;
    final spots = data.trendPoints.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), e.value.value)).toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(0, 16, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.dividerColor,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (v, _) => Text('${v.toInt()}',
                  style: const TextStyle(
                    color: AppColors.textHint, fontSize: 10)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= data.trendPoints.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data.trendPoints[idx].label,
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 9,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primaryBlue,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 3.5,
                  color: AppColors.primaryBlue,
                  strokeWidth: 2,
                  strokeColor: AppColors.bgCard,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.25),
                    AppColors.primaryBlue.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentPie() {
    final data = _data!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130, height: 130,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 35,
                sections: [
                  PieChartSectionData(
                    value: data.positivePercent,
                    color: AppColors.greenPositive,
                    radius: 28,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: data.neutralPercent,
                    color: AppColors.textHint,
                    radius: 24,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: data.negativePercent,
                    color: AppColors.redNegative,
                    radius: 28,
                    showTitle: false,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 24),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PieLegend(
                  color: AppColors.greenPositive,
                  label: 'Positive',
                  percent: data.positivePercent,
                ),
                const SizedBox(height: 12),
                _PieLegend(
                  color: AppColors.textHint,
                  label: 'Neutral',
                  percent: data.neutralPercent,
                ),
                const SizedBox(height: 12),
                _PieLegend(
                  color: AppColors.redNegative,
                  label: 'Negative',
                  percent: data.negativePercent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotTopics() {
    final data = _data!;
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: data.hotTopics.asMap().entries.map((e) {
        final colors = [
          AppColors.primaryBlue,
          AppColors.amberAccent,
          AppColors.purpleAi,
          AppColors.greenPositive,
          AppColors.redNegative,
          AppColors.primaryBlue,
        ];
        final c = colors[e.key % colors.length];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.trending_up_rounded, color: c, size: 12),
              const SizedBox(width: 6),
              Text(e.value, style: TextStyle(
                color: c, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopEntities() {
    final data = _data!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        children: data.topEntities.asMap().entries.map((e) {
          final entity = e.value;
          final maxM   = data.topEntities.first.mentions.toDouble();
          final pct    = entity.mentions / maxM;

          Color sentColor;
          switch (entity.sentiment) {
            case 'positive': sentColor = AppColors.greenPositive; break;
            case 'negative': sentColor = AppColors.redNegative;   break;
            default:         sentColor = AppColors.textHint;
          }

          IconData typeIcon;
          switch (entity.type) {
            case 'person':  typeIcon = Icons.person_rounded;      break;
            case 'company': typeIcon = Icons.business_rounded;    break;
            default:        typeIcon = Icons.location_on_rounded;
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: e.key < data.topEntities.length - 1
                ? const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: AppColors.dividerColor)))
                : null,
            child: Row(
              children: [
                // Rank
                SizedBox(
                  width: 20,
                  child: Text('${e.key + 1}',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12, fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 10),

                // Type icon
                Icon(typeIcon, color: AppColors.textHint, size: 16),
                const SizedBox(width: 10),

                // Name + bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entity.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13, fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: AppColors.dividerColor,
                          valueColor: AlwaysStoppedAnimation(sentColor),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Mentions count
                Text('${entity.mentions}',
                  style: TextStyle(
                    color: sentColor,
                    fontSize: 12, fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.bgCardAlt,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textHint, size: 18),
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 12),
          items: items.map((i) => DropdownMenuItem(
            value: i,
            child: Row(
              children: [
                Icon(icon, color: AppColors.textHint, size: 13),
                const SizedBox(width: 6),
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

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 8),
            Text(value,
              style: TextStyle(color: color,
                  fontSize: 18, fontWeight: FontWeight.w700)),
            Text(label,
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 10)),
          ],
        ),
      ),
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
        Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(label,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text('${percent.toInt()}%',
          style: TextStyle(color: color,
              fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
