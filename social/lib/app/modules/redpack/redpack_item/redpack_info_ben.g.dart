// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redpack_info_ben.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RedPackInfoBeanAdapter extends TypeAdapter<RedPackInfoBean> {
  @override
  final int typeId = 23;

  @override
  RedPackInfoBean read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RedPackInfoBean(
      messageId: fields[0] as String,
      id: fields[1] as String,
      status: fields[2] as int,
      subMoney: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RedPackInfoBean obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.messageId)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.subMoney);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RedPackInfoBeanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
