import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im/core/config.dart';
import 'package:im/global.dart';
import 'package:oktoast/oktoast.dart';

class ShareLinkButton extends StatelessWidget {
  final Widget child;
  final int channelId;
  final int guildId;
  const ShareLinkButton(
      {@required this.child, @required this.channelId, @required this.guildId});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final params = {
          'action': 'join',
          'channelId': channelId.toString(),
          'guildId': guildId.toString(),
          'inviterId': Global.user.id.toString(),
          'v': DateTime.now().millisecondsSinceEpoch.toString(),
        };
        final Uri uri = Uri(
            scheme: Config.useHttps ? 'https' : 'http',
            host: Config.host2,
            path: '/invite.html',
            queryParameters: params);
        final ClipboardData data = ClipboardData(text: uri.toString());
        Clipboard.setData(data);
        showToast('邀请链接已复制'.tr);
      },
      child: child,
    );
  }
}
