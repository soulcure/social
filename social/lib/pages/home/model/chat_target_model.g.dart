// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_target_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatChannelTypeAdapter extends TypeAdapter<ChatChannelType> {
  @override
  final int typeId = 2;

  @override
  ChatChannelType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ChatChannelType.guildText;
      case 1:
        return ChatChannelType.guildVoice;
      case 2:
        return ChatChannelType.guildVideo;
      case 3:
        return ChatChannelType.dm;
      case 4:
        return ChatChannelType.guildCategory;
      case 5:
        return ChatChannelType.guildCircle;
      case 6:
        return ChatChannelType.guildLive;
      case 7:
        return ChatChannelType.guildLink;
      case 8:
        return ChatChannelType.liveRoom;
      case 9:
        return ChatChannelType.task;
      case 10:
        return ChatChannelType.group_dm;
      case 11:
        return ChatChannelType.guildCircleTopic;
      case 12:
        return ChatChannelType.circleNews;
      case 13:
        return ChatChannelType.circlePostNews;
      case 256:
        return ChatChannelType.unsupported;
      default:
        return ChatChannelType.guildText;
    }
  }

  @override
  void write(BinaryWriter writer, ChatChannelType obj) {
    switch (obj) {
      case ChatChannelType.guildText:
        writer.writeByte(0);
        break;
      case ChatChannelType.guildVoice:
        writer.writeByte(1);
        break;
      case ChatChannelType.guildVideo:
        writer.writeByte(2);
        break;
      case ChatChannelType.dm:
        writer.writeByte(3);
        break;
      case ChatChannelType.guildCategory:
        writer.writeByte(4);
        break;
      case ChatChannelType.guildCircle:
        writer.writeByte(5);
        break;
      case ChatChannelType.guildLive:
        writer.writeByte(6);
        break;
      case ChatChannelType.guildLink:
        writer.writeByte(7);
        break;
      case ChatChannelType.liveRoom:
        writer.writeByte(8);
        break;
      case ChatChannelType.task:
        writer.writeByte(9);
        break;
      case ChatChannelType.group_dm:
        writer.writeByte(10);
        break;
      case ChatChannelType.guildCircleTopic:
        writer.writeByte(11);
        break;
      case ChatChannelType.circleNews:
        writer.writeByte(12);
        break;
      case ChatChannelType.circlePostNews:
        writer.writeByte(13);
        break;
      case ChatChannelType.unsupported:
        writer.writeByte(256);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatChannelTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatChannelAdapter extends TypeAdapter<ChatChannel> {
  @override
  final int typeId = 1;

  @override
  ChatChannel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatChannel(
      id: fields[0] as String,
      guildId: fields[1] as String,
      name: fields[2] as String,
      type: fields[3] as ChatChannelType,
      topic: fields[4] as String,
      parentId: fields[5] as String,
      position: fields[6] as int,
      link: fields[8] as String,
      pendingUserAccess: fields[9] as bool,
      userLimit: fields[10] == null ? 10 : fields[10] as int,
      active: fields[11] == null ? false : fields[11] as bool,
      icon: fields[12] == null ? '' : fields[12] as String,
      icons: (fields[14] as List)?.cast<DmGroupRecipientIcon>(),
      recipientId: fields[15] == null ? null : fields[15] as String,
      recipientGuildId: fields[16] == null ? null : fields[16] as String,
      botSettingList: (fields[17] as List)
          ?.map((dynamic e) => (e as Map).cast<String, String>())
          ?.toList(),
    )..description = fields[13] as String;
  }

  @override
  void write(BinaryWriter writer, ChatChannel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.guildId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.topic)
      ..writeByte(5)
      ..write(obj.parentId)
      ..writeByte(6)
      ..write(obj.position)
      ..writeByte(8)
      ..write(obj.link)
      ..writeByte(9)
      ..write(obj.pendingUserAccess)
      ..writeByte(10)
      ..write(obj.userLimit)
      ..writeByte(11)
      ..write(obj.active)
      ..writeByte(12)
      ..write(obj.icon)
      ..writeByte(13)
      ..write(obj.description)
      ..writeByte(14)
      ..write(obj.icons)
      ..writeByte(15)
      ..write(obj.recipientId)
      ..writeByte(16)
      ..write(obj.recipientGuildId)
      ..writeByte(17)
      ..write(obj.botSettingList);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatChannelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
