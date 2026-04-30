import 'package:hive/hive.dart';

part 'summary.g.dart';

@HiveType(typeId: 0)
class Summary extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String originalText;

  @HiveField(2)
  final String headline;

  @HiveField(3)
  final List<String> bullets;

  @HiveField(4)
  final String? sourceUrl;

  @HiveField(5)
  final String? translatedHeadline;

  @HiveField(6)
  final List<String>? translatedBullets;

  @HiveField(7)
  final String? translatedTo;

  @HiveField(8)
  final String sentiment; // 'positive' | 'negative' | 'neutral'

  @HiveField(9)
  final double sentimentScore;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final bool isBookmarked;

  @HiveField(12)
  final String inputType; // 'text' | 'url' | 'voice' | 'ocr'

  Summary({
    required this.id,
    required this.originalText,
    required this.headline,
    required this.bullets,
    this.sourceUrl,
    this.translatedHeadline,
    this.translatedBullets,
    this.translatedTo,
    required this.sentiment,
    required this.sentimentScore,
    required this.createdAt,
    this.isBookmarked = false,
    required this.inputType,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      id:             json['id'] ?? '',
      originalText:   json['original_text'] ?? '',
      headline:       json['headline'] ?? '',
      bullets:        List<String>.from(json['bullets'] ?? []),
      sourceUrl:      json['source_url'],
      translatedHeadline: json['translated_headline'],
      translatedBullets:  json['translated_bullets'] != null
          ? List<String>.from(json['translated_bullets'])
          : null,
      translatedTo:   json['translated_to'],
      sentiment:      json['sentiment'] ?? 'neutral',
      sentimentScore: (json['sentiment_score'] ?? 0.0).toDouble(),
      createdAt:      json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isBookmarked:   json['is_bookmarked'] ?? false,
      inputType:      json['input_type'] ?? 'text',
    );
  }

  Summary copyWith({
    bool? isBookmarked,
    String? translatedTo,
    String? translatedHeadline,
    List<String>? translatedBullets,
  }) {
    return Summary(
      id:                 id,
      originalText:       originalText,
      headline:           headline,
      bullets:            bullets,
      sourceUrl:          sourceUrl,
      translatedHeadline: translatedHeadline ?? this.translatedHeadline,
      translatedBullets:  translatedBullets ?? this.translatedBullets,
      translatedTo:       translatedTo ?? this.translatedTo,
      sentiment:          sentiment,
      sentimentScore:     sentimentScore,
      createdAt:          createdAt,
      isBookmarked:       isBookmarked ?? this.isBookmarked,
      inputType:          inputType,
    );
  }

  /// Returns a copy of this summary with all translation fields cleared.
  /// Use this to revert a translated message back to its original language.
  Summary clearTranslation() => Summary(
        id:             id,
        originalText:   originalText,
        headline:       headline,
        bullets:        bullets,
        sourceUrl:      sourceUrl,
        translatedHeadline: null,
        translatedBullets:  null,
        translatedTo:       null,
        sentiment:      sentiment,
        sentimentScore: sentimentScore,
        createdAt:      createdAt,
        isBookmarked:   isBookmarked,
        inputType:      inputType,
      );
}
