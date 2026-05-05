// lib/providers/insights_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/insight.dart';
import '../services/api_service.dart';
import 'preferences_provider.dart';

final insightDataProvider =
    FutureProvider.autoDispose<InsightData>((ref) async {
  final prefs = ref.watch(preferencesProvider);

  final result = await ApiService.instance.getInsights(
    region:     prefs.region,
    timeFilter: 'Today',
    interests:  prefs.interests,
  );

  if (result.isSuccess) {
    final r = result.data!;
    return InsightData(
      positivePercent:      r.positivePercent,
      neutralPercent:       r.neutralPercent,
      negativePercent:      r.negativePercent,
      totalArticlesAnalyzed: r.totalArticles,
      hotTopics:            r.hotTopics,
      trendPoints: r.trendPoints
          .map((tp) => TrendPoint(
                label: tp['date']?.toString() ?? '',
                value: (tp['value'] ?? 0.0).toDouble(),
              ))
          .toList(),
      topEntities: r.topEntities
          .map((te) => TopEntity(
                name:      te['name']?.toString()      ?? '',
                mentions:  (te['mentions'] ?? 0)        as int,
                sentiment: te['sentiment']?.toString() ?? 'neutral',
                type:      te['type']?.toString()      ?? 'company',
              ))
          .toList(),
      sentimentVolatility: (result.data?.data?['sentiment_volatility'] ?? 0.0).toDouble(),
      entityPulse: (result.data?.data?['entity_pulse'] as List? ?? [])
          .map((ep) => EntityPulse(
                name:   ep['name']?.toString() ?? '',
                points: List<double>.from((ep['pulse'] as List? ?? []).map((p) => (p ?? 0.0).toDouble())),
              ))
          .toList(),
    );
  }

  return InsightData.mock();
});
