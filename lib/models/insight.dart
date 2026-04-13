class InsightData {
	final double positivePercent;
	final double neutralPercent;
	final double negativePercent;
	final int totalArticlesAnalyzed;
	final List<String> hotTopics;

	const InsightData({
		required this.positivePercent,
		required this.neutralPercent,
		required this.negativePercent,
		required this.totalArticlesAnalyzed,
		required this.hotTopics,
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
		);
	}
}
