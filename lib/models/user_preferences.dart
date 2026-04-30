import 'package:hive/hive.dart';

part 'user_preferences.g.dart';

@HiveType(typeId: 1)
class UserPreferences extends HiveObject {
  @HiveField(0)
  final String displayName;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final List<String> interests;

  @HiveField(3)
  final String region;

  @HiveField(4)
  final String preferredLanguage;

  @HiveField(5)
  final bool eli5Mode;

  @HiveField(6)
  final bool breakingNotifications;

  @HiveField(7)
  final bool onboardingDone;

  @HiveField(8)
  final bool isDarkMode;

  UserPreferences({
    this.displayName = '',
    this.email = '',
    this.interests = const [],
    this.region = 'Global',
    this.preferredLanguage = 'en',
    this.eli5Mode = false,
    this.breakingNotifications = true,
    this.onboardingDone = false,
    this.isDarkMode = true,
  });

  UserPreferences copyWith({
    String? displayName,
    String? email,
    List<String>? interests,
    String? region,
    String? preferredLanguage,
    bool? eli5Mode,
    bool? breakingNotifications,
    bool? onboardingDone,
    bool? isDarkMode,
  }) =>
      UserPreferences(
        displayName:           displayName           ?? this.displayName,
        email:                 email                 ?? this.email,
        interests:             interests             ?? this.interests,
        region:                region                ?? this.region,
        preferredLanguage:     preferredLanguage     ?? this.preferredLanguage,
        eli5Mode:              eli5Mode              ?? this.eli5Mode,
        breakingNotifications: breakingNotifications ?? this.breakingNotifications,
        onboardingDone:        onboardingDone        ?? this.onboardingDone,
        isDarkMode:            isDarkMode            ?? this.isDarkMode,
      );
}
