// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remark_bean.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RemarkListBeanAdapter extends TypeAdapter<RemarkListBean> {
  @override
  final int typeId = 8;

  @override
  RemarkListBean read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RemarkListBean(
      size: fields[0] as int,
      listId: fields[1] as String,
      next: fields[2] as String,
      remarks: (fields[3] as Map)?.cast<String, RemarkBean>(),
    );
  }

  @override
  void write(BinaryWriter writer, RemarkListBean obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.size)
      ..writeByte(1)
      ..write(obj.listId)
      ..writeByte(2)
      ..write(obj.next)
      ..writeByte(3)
      ..write(obj.remarks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemarkListBeanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RemarkBeanAdapter extends TypeAdapter<RemarkBean> {
  @override
  final int typeId = 9;

  @override
  RemarkBean read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RemarkBean(
      fields[0] as String,
      fields[1] as String,
      fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RemarkBean obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.friendUserId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.userRemarkId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemarkBeanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
