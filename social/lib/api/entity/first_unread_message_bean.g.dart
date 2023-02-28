// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'first_unread_message_bean.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FirstUnreadMessageBeanAdapter
    extends TypeAdapter<FirstUnreadMessageBean> {
  @override
  final int typeId = 12;

  @override
  FirstUnreadMessageBean read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FirstUnreadMessageBean(
      time: fields[0] as int,
      messageId: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FirstUnreadMessageBean obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.time)
      ..writeByte(1)
      ..write(obj.messageId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FirstUnreadMessageBeanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
