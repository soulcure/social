import 'package:flutter/material.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

class ChannelIcon extends StatelessWidget {
  final ChatChannelType channelType;
  final bool private;
  final double size;
  final Color color;

  const ChannelIcon(
    this.channelType, {
    Key key,
    this.private = false,
    this.size,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(
      getChannelTypeIcon(
        channelType,
        isPrivate: private,
      ),
      size: size,
      color: color,
    );
  }

  static IconData getChannelTypeIcon(
    ChatChannelType channelType, {
    bool isPrivate = false,
  }) {
    switch (channelType) {
      case ChatChannelType.dm:
      case ChatChannelType.guildText:
        if (isPrivate) {
          return IconFont.buffSimiwenzipindao;
        } else {
          return IconFont.buffWenzipindaotubiao;
        }
        break;
      case ChatChannelType.guildVoice:
        if (isPrivate) {
          return IconFont.buffChannelVoicePriv;
        } else {
          return IconFont.buffChannelMicLittle;
        }
        break;
      case ChatChannelType.guildVideo:
        if (isPrivate) {
          return IconFont.buffChannelVideoPriv;
        } else {
          return IconFont.buffChannelVideocamLittle;
        }
        break;
      case ChatChannelType.guildCategory:
        break;
      case ChatChannelType.guildLink:
        if (isPrivate) {
          return IconFont.buffChannelLinkPriv;
        } else {
          return IconFont.buffChannelLink;
        }
        break;
      case ChatChannelType.guildLive:
        if (isPrivate) {
          return IconFont.buffChannelLivePriv;
        } else {
          return IconFont.buffChannelLive;
        }
        break;
      case ChatChannelType.guildCircleTopic:
        return IconFont.buffChannelMessageSolid;
        break;
      default:
        break;
    }
    return null;
  }
}
