// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoleAdapter extends TypeAdapter<Role> {
  @override
  final int typeId = 5;

  @override
  Role read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Role(
      id: fields[0] as String,
      name: fields[1] as String,
      position: fields[4] as int,
      hoist: fields[2] as bool,
      color: fields[3] as int,
      permissions: fields[5] as int,
      managed: fields[6] as bool,
      mentionable: fields[7] as bool,
      memberCount: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Role obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.hoist)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.position)
      ..writeByte(5)
      ..write(obj.permissions)
      ..writeByte(6)
      ..write(obj.managed)
      ..writeByte(7)
      ..write(obj.mentionable)
      ..writeByte(8)
      ..write(obj.memberCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
