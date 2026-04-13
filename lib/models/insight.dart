class InsightData {
	final double positivePercent;
	final double neutralPercent;
	final double negativePercent;
	final int totalArticlesAnalyzed;
	final List<String> hotTopics;
	final List<TrendPoint> trendPoints;
	final List<TopEntity> topEntities;

	const InsightData({
		required this.positivePercent,
		required this.neutralPercent,
		required this.negativePercent,
		required this.totalArticlesAnalyzed,
		required this.hotTopics,
		required this.trendPoints,
		required this.topEntities,
	});

	factory InsightData.mock() {
		return const InsightData(
			positivePercent: 52,
			neutralPercent: 30,
			negativePercent: 18,
			totalArticlesAnalyzed: 86,
			hotTopics: <String>[
				'AI',
				'Inflation',
				'Elections',
				'Tech Earnings',
				'Climate',
			],
			trendPoints: <TrendPoint>[
				TrendPoint(label: 'Mon', value: 18),
				TrendPoint(label: 'Tue', value: 22),
				TrendPoint(label: 'Wed', value: 16),
				TrendPoint(label: 'Thu', value: 28),
				TrendPoint(label: 'Fri', value: 24),
				TrendPoint(label: 'Sat', value: 12),
				TrendPoint(label: 'Sun', value: 19),
			],
			topEntities: <TopEntity>[
				TopEntity(name: 'OpenAI', mentions: 34, sentiment: 'positive', type: 'company'),
				TopEntity(name: 'NVIDIA', mentions: 29, sentiment: 'positive', type: 'company'),
				TopEntity(name: 'IMF', mentions: 22, sentiment: 'negative', type: 'company'),
				TopEntity(name: 'Pakistan', mentions: 18, sentiment: 'neutral', type: 'location'),
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

	const TopEntity({
		required this.name,
		required this.mentions,
		required this.sentiment,
		required this.type,
	});
}
