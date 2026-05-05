class AppConstants {
  static const String appName    = 'Briefly AI';
  static const String appTagline = 'News, Briefed & Visualized';
  static const String appVersion = '1.0.0';
  static const String googleClientId = '42588087428-fqv20t82af0vbpivsl8kc4uv7a7ju5gq.apps.googleusercontent.com';

  static const String apiBaseUrl   = 'http://10.7.184.87:8000';
  static const String apiSummarize = '/summarize';
  static const String apiTranslate = '/translate';
  static const String apiInsights  = '/insights';
  static const String apiAuthLogin    = '/auth/login';
  static const String apiAuthRegister = '/auth/register';
  static const String apiAuthGoogle   = '/auth/google';

  static const String hiveBoxHistory   = 'history_box';
  static const String hiveBoxSettings  = 'settings_box';
  static const String hiveBoxAuth      = 'auth_box';

  static const double radiusSm  = 12.0;
  static const double radiusMd  = 16.0;
  static const double radiusLg  = 24.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 24.0;

  static const List<String> newsCategories = [
    'Technology', 'Finance', 'Politics', 'Science',
    'Health', 'Sports', 'Business', 'Entertainment',
    'Climate', 'World', 'Pakistan', 'Startups',
  ];
  static const List<String> regions = [
    'Global', 'Asia', 'Pakistan', 'USA',
    'Europe', 'Middle East', 'South Asia', 'Africa',
  ];
  static const List<String> timeFilters = [
    'Today', 'Last 7 Days', 'Last 30 Days', 'Last 3 Months',
  ];
  static const Map<String, String> supportedLanguages = {
    'en': 'English', 'ur': 'اردو', 'es': 'Español',
    'fr': 'Français', 'ar': 'العربية', 'zh': '中文', 'hi': 'हिन्दी',
  };
}
