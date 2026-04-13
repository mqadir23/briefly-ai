// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

// ── Response models ────────────────────────────────────────────────────────────

class SummaryResponse {
  final String headline;
  final List<String> bullets;
  final String sentiment;      // 'positive' | 'negative' | 'neutral'
  final double sentimentScore; // -1.0 to 1.0
  final String? sourceUrl;
  final String inputType;      // 'text' | 'url' | 'voice' | 'ocr'

  const SummaryResponse({
    required this.headline,
    required this.bullets,
    required this.sentiment,
    required this.sentimentScore,
    this.sourceUrl,
    required this.inputType,
  });

  factory SummaryResponse.fromJson(Map<String, dynamic> j) {
    return SummaryResponse(
      headline:       j['headline']        ?? 'No headline returned',
      bullets:        List<String>.from(j['bullets'] ?? []),
      sentiment:      j['sentiment']       ?? 'neutral',
      sentimentScore: (j['sentiment_score'] ?? 0.0).toDouble(),
      sourceUrl:      j['source_url'],
      inputType:      j['input_type']      ?? 'text',
    );
  }
}

class TranslationResponse {
  final String translatedHeadline;
  final List<String> translatedBullets;
  final String targetLanguage;

  const TranslationResponse({
    required this.translatedHeadline,
    required this.translatedBullets,
    required this.targetLanguage,
  });

  factory TranslationResponse.fromJson(Map<String, dynamic> j) {
    return TranslationResponse(
      translatedHeadline: j['translated_headline'] ?? '',
      translatedBullets:  List<String>.from(j['translated_bullets'] ?? []),
      targetLanguage:     j['target_language']     ?? 'en',
    );
  }
}

class InsightsResponse {
  final double positivePercent;
  final double negativePercent;
  final double neutralPercent;
  final int    totalArticles;
  final List<Map<String, dynamic>> trendPoints;   // [{date, value}]
  final List<Map<String, dynamic>> topEntities;   // [{name, type, mentions, sentiment}]
  final List<String> hotTopics;

  const InsightsResponse({
    required this.positivePercent,
    required this.negativePercent,
    required this.neutralPercent,
    required this.totalArticles,
    required this.trendPoints,
    required this.topEntities,
    required this.hotTopics,
  });

  factory InsightsResponse.fromJson(Map<String, dynamic> j) {
    return InsightsResponse(
      positivePercent: (j['positive_percent'] ?? 0.0).toDouble(),
      negativePercent: (j['negative_percent'] ?? 0.0).toDouble(),
      neutralPercent:  (j['neutral_percent']  ?? 0.0).toDouble(),
      totalArticles:   j['total_articles']    ?? 0,
      trendPoints:     List<Map<String, dynamic>>.from(j['trend_points'] ?? []),
      topEntities:     List<Map<String, dynamic>>.from(j['top_entities'] ?? []),
      hotTopics:       List<String>.from(j['hot_topics'] ?? []),
    );
  }
}

// ── API result wrapper ─────────────────────────────────────────────────────────
// Every public method returns ApiResult<T> so callers never need try/catch.

class ApiResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const ApiResult._({this.data, this.error, required this.isSuccess});

  factory ApiResult.success(T data) =>
      ApiResult._(data: data, isSuccess: true);

  factory ApiResult.failure(String error) =>
      ApiResult._(error: error, isSuccess: false);

  @override
  String toString() =>
      isSuccess ? 'ApiResult.success($data)' : 'ApiResult.failure($error)';
}

// ── API Service ────────────────────────────────────────────────────────────────

class ApiService {
  // Singleton pattern — one instance across the whole app
  ApiService._();
  static final ApiService instance = ApiService._();

  final String _base = AppConstants.apiBaseUrl;

  // Shared http client (re-used across calls, better performance)
  final http.Client _client = http.Client();

  // Default timeout for all requests
  static const Duration _timeout = Duration(seconds: 20);

  // ── Headers ──────────────────────────────────────────────────────────────────

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
  };

  // ── 1. Summarise ──────────────────────────────────────────────────────────────
  // Accepts plain text, a URL, or OCR-extracted text.
  // inputType: 'text' | 'url' | 'ocr' | 'voice'

  Future<ApiResult<SummaryResponse>> summarise({
    required String content,
    required String inputType,
    bool eli5 = false,
  }) async {
    try {
      final body = jsonEncode({
        'content':    content,
        'input_type': inputType,
        'eli5':       eli5,
      });

      final response = await _client
          .post(
            Uri.parse('$_base${AppConstants.apiSummarize}'),
            headers: _headers,
            body: body,
          )
          .timeout(_timeout);

      return _handleResponse<SummaryResponse>(
        response,
        (json) => SummaryResponse.fromJson(json),
      );
    } catch (e) {
      return ApiResult.failure(_friendlyError(e));
    }
  }

  // ── 2. Translate ──────────────────────────────────────────────────────────────
  // Translates a previously generated summary into a target language.

  Future<ApiResult<TranslationResponse>> translate({
    required String headline,
    required List<String> bullets,
    required String targetLanguage, // e.g. 'ur', 'es', 'fr'
  }) async {
    try {
      final body = jsonEncode({
        'headline':        headline,
        'bullets':         bullets,
        'target_language': targetLanguage,
      });

      final response = await _client
          .post(
            Uri.parse('$_base${AppConstants.apiTranslate}'),
            headers: _headers,
            body: body,
          )
          .timeout(_timeout);

      return _handleResponse<TranslationResponse>(
        response,
        (json) => TranslationResponse.fromJson(json),
      );
    } catch (e) {
      return ApiResult.failure(_friendlyError(e));
    }
  }

  // ── 3. Insights ───────────────────────────────────────────────────────────────
  // Fetches analytics data for InsightLens dashboard.

  Future<ApiResult<InsightsResponse>> getInsights({
    required String region,     // e.g. 'Global', 'Pakistan'
    required String timeFilter, // e.g. 'Last 7 Days'
    List<String> interests = const [],
  }) async {
    try {
      // Build query parameters
      final uri = Uri.parse('$_base${AppConstants.apiInsights}').replace(
        queryParameters: {
          'region':      region,
          'time_filter': timeFilter,
          'interests':   interests.join(','),
        },
      );

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(_timeout);

      return _handleResponse<InsightsResponse>(
        response,
        (json) => InsightsResponse.fromJson(json),
      );
    } catch (e) {
      return ApiResult.failure(_friendlyError(e));
    }
  }

  // ── 4. Health check ───────────────────────────────────────────────────────────
  // Call this on app start to verify backend is reachable.

  Future<bool> isBackendReachable() async {
    try {
      final response = await _client
          .get(Uri.parse('$_base/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────────

  ApiResult<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResult.success(fromJson(json));
      } catch (e) {
        return ApiResult.failure('Could not parse server response.');
      }
    }

    // Try to extract a message from the error body
    String errorMsg;
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      errorMsg = json['detail'] ?? json['message'] ?? 'Server error ${response.statusCode}';
    } catch (_) {
      errorMsg = 'Server error ${response.statusCode}';
    }

    return ApiResult.failure(errorMsg);
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') ||
        msg.contains('Connection refused') ||
        msg.contains('TimeoutException')) {
      return 'Cannot reach the server. Make sure FastAPI is running on port 8000.';
    }
    return 'Something went wrong. Please try again.';
  }

  void dispose() => _client.close();
}