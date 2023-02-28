import 'package:flutter/cupertino.dart';

class AcceptInviteParam {
  final String guildId;
  final String channelId;

  /// NOTE: 2021/12/16 服务端开发确认，该参数不是必填项，可以未""和null
  final String postId;
  final String inviteCode;
  final Object notifier;
  final bool isExpire;
  final String inviterId;

  AcceptInviteParam({
    @required this.guildId,
    @required this.channelId,
    @required this.inviteCode,
    @required this.inviterId,
    this.postId = '',
    this.isExpire = false,
    this.notifier,
  });
}
