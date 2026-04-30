// lib/providers/preferences_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_preferences.dart';
import '../utils/constants.dart';

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, UserPreferences>((ref) {
  return PreferencesNotifier();
});

class PreferencesNotifier extends StateNotifier<UserPreferences> {
  PreferencesNotifier() : super(UserPreferences()) {
    _load();
  }

  Box<UserPreferences> get _box =>
      Hive.box<UserPreferences>(AppConstants.hiveBoxSettings);

  void _load() {
    final saved = _box.get('prefs');
    if (saved != null) state = saved;
  }

  Future<void> save(UserPreferences prefs) async {
    state = prefs;
    await _box.put('prefs', prefs);
  }

  Future<void> setOnboardingDone() =>
      save(state.copyWith(onboardingDone: true));

  Future<void> updateInterests(List<String> interests) =>
      save(state.copyWith(interests: interests));

  Future<void> updateRegion(String region) =>
      save(state.copyWith(region: region));

  Future<void> updateLanguage(String lang) =>
      save(state.copyWith(preferredLanguage: lang));

  Future<void> toggleEli5(bool value) =>
      save(state.copyWith(eli5Mode: value));

  Future<void> toggleBreakingNotifications(bool value) =>
      save(state.copyWith(breakingNotifications: value));

  Future<void> toggleDarkMode(bool value) =>
      save(state.copyWith(isDarkMode: value));

  Future<void> updateProfile({String? displayName, String? email}) =>
      save(state.copyWith(displayName: displayName, email: email));

  /// Resets all preferences to defaults (used on Sign Out).
  Future<void> resetPreferences() => save(UserPreferences());
}
