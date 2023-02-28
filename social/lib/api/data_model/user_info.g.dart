/*
 * @FilePath       : /social/lib/api/data_model/user_info.g.dart
 * 
 * @Info           : 
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-04-13 11:25:57
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-04-13 11:32:26
 * 
 */
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserInfoAdapter extends TypeAdapter<UserInfo> {
  @override
  final int typeId = 0;

  @override
  UserInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserInfo(
      userId: fields[0] as String,
      avatar: fields[1] as String,
      nickname: fields[2] as String,
      gender: fields[4] as int,
      username: fields[3] as String,
      phoneNumber: fields[5] as String,
      roles: (fields[6] as List)?.cast<String>(),
      isBot: fields[7] as bool,
      guildNickNames: fields[8] as Map,
      avatarNft: fields[9] as String,
      avatarNftId: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserInfo obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.avatar)
      ..writeByte(2)
      ..write(obj.nickname)
      ..writeByte(3)
      ..write(obj.username)
      ..writeByte(4)
      ..write(obj.gender)
      ..writeByte(5)
      ..write(obj.phoneNumber)
      ..writeByte(6)
      ..write(obj.roles)
      ..writeByte(7)
      ..write(obj.isBot)
      ..writeByte(8)
      ..write(obj.guildNickNames)
      ..writeByte(9)
      ..write(obj.avatarNft)
      ..writeByte(10)
      ..write(obj.avatarNftId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
