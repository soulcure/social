// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guild_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DirectMessageStruct _$DirectMessageStructFromJson(Map<String, dynamic> json) {
  return DirectMessageStruct(
    guildId: json['guild_id'] as String,
    channelId: json['channel_id'] as String,
    recipientId: json['recipient_id'] as String,
    numUnread: json['offline'] as int,
    top: json['top'] as int,
    icon: json['icon'] as String,
    name: json['name'] as String,
    type: json['type'] as int ?? 3,
    userIcons: json['user_icon'] != null
        ? (json['user_icon'] as List)
            .map<DmGroupRecipientIcon>((e) => DmGroupRecipientIcon.fromJson(e))
            .toList()
        : null,
    status: json['status'] as int ?? 0,
  );
}

Map<String, dynamic> _$DirectMessageStructToJson(
        DirectMessageStruct instance) =>
    <String, dynamic>{
      'guild_id': instance.guildId,
      'channel_id': instance.channelId,
      'recipient_id': instance.recipientId,
      'offline': instance.numUnread,
      'top': instance.top,
      'icon': instance.icon,
      'name': instance.name,
      'type': instance.type,
      'user_icon': instance.userIcons != null
          ? instance.userIcons.map((e) => e.toJson()).toList()
          : null,
      'status': instance.status,
    };
