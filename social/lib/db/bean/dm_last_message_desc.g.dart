// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dm_last_message_desc.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DmLastMessageDescAdapter extends TypeAdapter<DmLastMessageDesc> {
  @override
  final int typeId = 16;

  @override
  DmLastMessageDesc read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DmLastMessageDesc(
      messageId: fields[0] as BigInt,
      desc: fields[1] as String,
      senderId: fields[2] as String,
      senderNiceName: fields[3] as String,
      guildId: fields[4] as String,
      userIdList: (fields[5] as List)?.cast<String>(),
      lastReaction: (fields[6] as List)?.cast<LastReactionItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, DmLastMessageDesc obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.messageId)
      ..writeByte(1)
      ..write(obj.desc)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.senderNiceName)
      ..writeByte(4)
      ..write(obj.guildId)
      ..writeByte(5)
      ..write(obj.userIdList)
      ..writeByte(6)
      ..write(obj.lastReaction);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DmLastMessageDescAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
