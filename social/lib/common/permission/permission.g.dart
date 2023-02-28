// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GuildPermissionAdapter extends TypeAdapter<GuildPermission> {
  @override
  final int typeId = 4;

  @override
  GuildPermission read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GuildPermission(
      guildId: fields[0] as String,
      ownerId: fields[1] as String,
      permissions: fields[2] as int,
      userRoles: fields[3] == null ? [] : (fields[3] as List)?.cast<String>(),
      roles: fields[4] == null ? [] : (fields[4] as List)?.cast<Role>(),
      channelPermission: fields[5] == null
          ? []
          : (fields[5] as List)?.cast<ChannelPermission>(),
    );
  }

  @override
  void write(BinaryWriter writer, GuildPermission obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.guildId)
      ..writeByte(1)
      ..write(obj.ownerId)
      ..writeByte(2)
      ..write(obj.permissions)
      ..writeByte(3)
      ..write(obj.userRoles)
      ..writeByte(4)
      ..write(obj.roles)
      ..writeByte(5)
      ..write(obj.channelPermission);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuildPermissionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChannelPermissionAdapter extends TypeAdapter<ChannelPermission> {
  @override
  final int typeId = 6;

  @override
  ChannelPermission read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChannelPermission(
      channelId: fields[0] as String,
      overwrites: (fields[1] as List)?.cast<PermissionOverwrite>(),
    );
  }

  @override
  void write(BinaryWriter writer, ChannelPermission obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.channelId)
      ..writeByte(1)
      ..write(obj.overwrites);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelPermissionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PermissionOverwriteAdapter extends TypeAdapter<PermissionOverwrite> {
  @override
  final int typeId = 7;

  @override
  PermissionOverwrite read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PermissionOverwrite(
      id: fields[0] as String,
      guildId: fields[1] as String,
      channelId: fields[2] as String,
      deny: fields[3] as int,
      allows: fields[4] as int,
      actionType: fields[5] as String,
      name: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PermissionOverwrite obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.guildId)
      ..writeByte(2)
      ..write(obj.channelId)
      ..writeByte(3)
      ..write(obj.deny)
      ..writeByte(4)
      ..write(obj.allows)
      ..writeByte(5)
      ..write(obj.actionType)
      ..writeByte(6)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermissionOverwriteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
