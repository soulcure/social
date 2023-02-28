// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redpack_item_bean.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RedPackItemBeanAdapter extends TypeAdapter<RedPackItemBean> {
  @override
  final int typeId = 22;

  @override
  RedPackItemBean read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RedPackItemBean(
      channelId: fields[0] as String,
      redPackInfoList: (fields[1] as List)?.cast<RedPackInfoBean>(),
    );
  }

  @override
  void write(BinaryWriter writer, RedPackItemBean obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.channelId)
      ..writeByte(1)
      ..write(obj.redPackInfoList);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RedPackItemBeanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
