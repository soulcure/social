import 'package:flutter/material.dart';
import 'package:im/widgets/realtime_user_info.dart';

class CircleUserNickName extends StatelessWidget {
  final String userId;
  final TextStyle style;
  final bool preferentialRemark;
  final String nickName;

  //从消息列表打开圈子详情时，需要guildId来显示服务器昵称
  final String guildId;

  const CircleUserNickName(this.userId, this.style,
      {this.preferentialRemark = false, this.nickName = "", this.guildId});

  @override
  Widget build(BuildContext context) {
    return RealtimeNickname(
      userId: userId,
      style: style,
      showNameRule: ShowNameRule.remarkAndGuild,
      guildId: guildId,
    );
  }
}
