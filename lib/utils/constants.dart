class AppConstants {
  // App Info
  static const String appName = 'Briefly AI';
  static const String appTagline = 'News, Briefed & Visualized';
  static const String appVersion = '1.0.0';

  // API
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator localhost

  // Hive Box Names
  static const String chatBoxName = 'chat_history';
  static const String summaryBoxName = 'summaries';
  static const String preferencesBoxName = 'user_preferences';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Pagination
  static const int pageSize = 20;

  // Spacing
  static const double paddingSm = 8.0;
  static const double paddingMd = 12.0;
  static const double paddingLg = 16.0;
  static const double paddingXl = 24.0;

  // Border Radius
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;

  // Onboarding
  static const List<String> newsCategories = [
    'Technology',
    'Business',
    'Health',
    'Science',
    'Sports',
    'Entertainment',
    'Politics',
    'World'
  ];

  static const List<String> regions = [
    'Global',
    'US',
    'UK',
    'India',
    'Canada',
    'Australia',
    'Middle East',
    'Europe'
  ];

  // Analytics
  static const List<String> timeFilters = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 90 Days',
  ];

  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'zh': '中文',
    'ar': 'العربية',
    'hi': 'हिन्दी',
    'ja': '日本語',
  };
}
