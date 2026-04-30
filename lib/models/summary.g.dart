// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SummaryAdapter extends TypeAdapter<Summary> {
  @override
  final int typeId = 0;

  @override
  Summary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Summary(
      id: fields[0] as String,
      originalText: fields[1] as String,
      headline: fields[2] as String,
      bullets: (fields[3] as List).cast<String>(),
      sourceUrl: fields[4] as String?,
      translatedHeadline: fields[5] as String?,
      translatedBullets: (fields[6] as List?)?.cast<String>(),
      translatedTo: fields[7] as String?,
      sentiment: fields[8] as String,
      sentimentScore: fields[9] as double,
      createdAt: fields[10] as DateTime,
      isBookmarked: fields[11] as bool,
      inputType: fields[12] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Summary obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.originalText)
      ..writeByte(2)
      ..write(obj.headline)
      ..writeByte(3)
      ..write(obj.bullets)
      ..writeByte(4)
      ..write(obj.sourceUrl)
      ..writeByte(5)
      ..write(obj.translatedHeadline)
      ..writeByte(6)
      ..write(obj.translatedBullets)
      ..writeByte(7)
      ..write(obj.translatedTo)
      ..writeByte(8)
      ..write(obj.sentiment)
      ..writeByte(9)
      ..write(obj.sentimentScore)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.isBookmarked)
      ..writeByte(12)
      ..write(obj.inputType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
