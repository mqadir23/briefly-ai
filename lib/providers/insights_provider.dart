// lib/providers/insights_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/insight.dart';
import '../services/api_service.dart';
import 'preferences_provider.dart';

/// Loads InsightLens data from the backend for the user's current
/// region and interests.  Falls back to [InsightData.mock()] when
/// the request fails so the UI always has something to show.
///
/// Uses [FutureProvider.autoDispose] so the request is re-fired
/// whenever the provider is first watched after being released.
/// Since [preferencesProvider] is watched inside, any change to
/// region or interests will also trigger a refresh.
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
    );
  }

  // Backend unreachable — use demo data so InsightLens is never blank.
  return InsightData.mock();
});
