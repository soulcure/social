// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalUser _$LocalUserFromJson(Map<String, dynamic> json) {
  return LocalUser()
    ..id = json['user_id'] as String
    ..nickname = json['nickname'] as String
    ..username = json['username'] as String
    ..avatar = json['avatar'] as String
    ..token = json['token'] as String
    ..mobile = getMobileByBase64(json['encryption_mobile'] as String, json['mobile'] as String)
    ..gender = json['gender'] as int
    ..connected = json['connected'] as bool
    ..presenceStatus = presenceStatusFromJson(json['presence_status'] as int);
}

Map<String, dynamic> _$LocalUserToJson(LocalUser instance) => <String, dynamic>{
      'user_id': instance.id,
      'nickname': instance.nickname,
      'username': instance.username,
      'avatar': instance.avatar,
      'token': instance.token,
      'mobile': instance.mobile,
      'gender': instance.gender,
      'connected': instance.connected,
      'presence_status': presenceStatusToJson(instance.presenceStatus),
    };
