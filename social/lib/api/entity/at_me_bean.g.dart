// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'at_me_bean.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AtMeBeanAdapter extends TypeAdapter<AtMeBean> {
  @override
  final int typeId = 11;

  @override
  AtMeBean read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AtMeBean(
      num: fields[0] as int,
      channelId: fields[1] as String,
      messageIdMap: (fields[2] as Map)?.cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, AtMeBean obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.num)
      ..writeByte(1)
      ..write(obj.channelId)
      ..writeByte(2)
      ..write(obj.messageIdMap);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AtMeBeanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
