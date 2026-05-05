class InsightData {
  final double positivePercent;
  final double neutralPercent;
  final double negativePercent;
  final int totalArticlesAnalyzed;
  final List<String> hotTopics;
  final List<TrendPoint> trendPoints;
  final List<TopEntity> topEntities;
  final double sentimentVolatility;
  final List<EntityPulse> entityPulse;

  const InsightData({
    required this.positivePercent,
    required this.neutralPercent,
    required this.negativePercent,
    required this.totalArticlesAnalyzed,
    required this.hotTopics,
    required this.trendPoints,
    required this.topEntities,
    this.sentimentVolatility = 0.0,
    this.entityPulse = const [],
  });

  factory InsightData.mock() {
    return const InsightData(
      positivePercent: 52,
      neutralPercent: 30,
      negativePercent: 18,
      totalArticlesAnalyzed: 86,
      hotTopics: ['AI', 'Inflation', 'Elections', 'Tech Earnings', 'Climate'],
      trendPoints: [
        TrendPoint(label: 'Mon', value: 18),
        TrendPoint(label: 'Tue', value: 22),
        TrendPoint(label: 'Wed', value: 16),
        TrendPoint(label: 'Thu', value: 28),
        TrendPoint(label: 'Fri', value: 24),
        TrendPoint(label: 'Sat', value: 12),
        TrendPoint(label: 'Sun', value: 19),
      ],
      topEntities: [
        TopEntity(name: 'OpenAI', mentions: 34, sentiment: 'positive', type: 'company'),
        TopEntity(name: 'NVIDIA', mentions: 29, sentiment: 'positive', type: 'company'),
        TopEntity(name: 'IMF', mentions: 22, sentiment: 'negative', type: 'company'),
        TopEntity(name: 'Pakistan', mentions: 18, sentiment: 'neutral', type: 'location'),
      ],
      sentimentVolatility: 0.12,
      entityPulse: [
        EntityPulse(name: 'AI', points: [10, 15, 25, 40]),
        EntityPulse(name: 'Finance', points: [20, 18, 22, 19]),
      ],
    );
  }
}

class TrendPoint {
  final String label;
  final double value;
  const TrendPoint({required this.label, required this.value});
}

class TopEntity {
  final String name;
  final int mentions;
  final String sentiment;
  final String type;
  const TopEntity({required this.name, required this.mentions, required this.sentiment, required this.type});
}

class EntityPulse {
  final String name;
  final List<double> points;
  const EntityPulse({required this.name, required this.points});
}

class AdvancedMiningData {
  final List<KeywordRelation> network;
  final Map<String, int> sentimentDistribution;
  final List<EmergingTrend> trends;

  AdvancedMiningData({
    required this.network,
    required this.sentimentDistribution,
    required this.trends,
  });

  factory AdvancedMiningData.mock() {
    return AdvancedMiningData(
      network: [
        KeywordRelation(source: 'AI', target: 'GPU', weight: 8),
        KeywordRelation(source: 'Inflation', target: 'Rates', weight: 6),
      ],
      sentimentDistribution: {
        'very_positive': 5,
        'positive': 15,
        'neutral': 20,
        'negative': 10,
        'very_negative': 2,
      },
      trends: [
        EmergingTrend(topic: 'Regenerative Ag', strength: 0.75),
        EmergingTrend(topic: 'Space Tourism', strength: 0.6),
      ],
    );
  }
}

class KeywordRelation {
  final String source, target;
  final int weight;
  KeywordRelation({required this.source, required this.target, required this.weight});
}

class EmergingTrend {
  final String topic;
  final double strength;
  EmergingTrend({required this.topic, required this.strength});
}
