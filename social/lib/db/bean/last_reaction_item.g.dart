// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_reaction_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LastReactionItemAdapter extends TypeAdapter<LastReactionItem> {
  @override
  final int typeId = 21;

  @override
  LastReactionItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LastReactionItem(
      fields[0] as String,
      fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, LastReactionItem obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.emojiName)
      ..writeByte(1)
      ..write(obj.count);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LastReactionItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
