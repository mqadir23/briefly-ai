// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserPreferencesAdapter extends TypeAdapter<UserPreferences> {
  @override
  final int typeId = 1;

  @override
  UserPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPreferences(
      displayName: fields[0] as String,
      email: fields[1] as String,
      interests: (fields[2] as List).cast<String>(),
      region: fields[3] as String,
      preferredLanguage: fields[4] as String,
      eli5Mode: fields[5] as bool,
      breakingNotifications: fields[6] as bool,
      onboardingDone: fields[7] as bool,
      isDarkMode: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserPreferences obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.displayName)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.interests)
      ..writeByte(3)
      ..write(obj.region)
      ..writeByte(4)
      ..write(obj.preferredLanguage)
      ..writeByte(5)
      ..write(obj.eli5Mode)
      ..writeByte(6)
      ..write(obj.breakingNotifications)
      ..writeByte(7)
      ..write(obj.onboardingDone)
      ..writeByte(8)
      ..write(obj.isDarkMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
