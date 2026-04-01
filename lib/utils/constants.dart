class AppConstants {
  // App Info
  static const String appName = 'Briefly AI';
  static const String appTagline = 'News, Briefed & Visualized';

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
}