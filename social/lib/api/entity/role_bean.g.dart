// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_bean.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoleBeanAdapter extends TypeAdapter<RoleBean> {
  @override
  final int typeId = 14;

  @override
  RoleBean read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoleBean()
      ..keyValue = fields[0] as String
      ..roleIds = (fields[1] as List)?.cast<String>();
  }

  @override
  void write(BinaryWriter writer, RoleBean obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.keyValue)
      ..writeByte(1)
      ..write(obj.roleIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoleBeanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
