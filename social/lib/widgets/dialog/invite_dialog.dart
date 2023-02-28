import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/home/home_page.dart';
import 'package:im/pages/tool/url_handler/invite_link_handler.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/invite_code/invite_code_util.dart';

/// 应用周期内没有显示过邀请页(用来处理首次启动从粘贴板获取邀请链接)
bool isLifeCycleNotDisplayInvite = true;

Future<void> checkClipboardInvite(BuildContext context) async {
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  final text = (data?.text ?? '').pureValue;
  final url = filterLinkFromText(text);

  if (url.noValue) return;

  if (const InviteLinkHandler().match(url)) {
    final inviteUrlStream = InviteUrlStream(url, InviteURLFrom.clipBoard);

    final lastInviteUrl = SpService.to.getString(SP.inviteUrl);
    if (lastInviteUrl == inviteUrlStream.url && !isLifeCycleNotDisplayInvite)
      return;
    await SpService.to.setString(SP.inviteUrl, inviteUrlStream.url);
    InviteCodeUtil.setInviteCode(url);
    HomePage.inviteStream.add(inviteUrlStream);
  }

  isLifeCycleNotDisplayInvite = false;
}
