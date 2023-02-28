import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:im/api/api.dart';
import 'package:im/global.dart';

import 'html_page.dart' if (dart.library.html) 'html_page_web.dart';

Future showFeedbackPage(BuildContext context) {
  final queryStr = "udx=93${DateTime.now().millisecondsSinceEpoch}3c&user_name=${Uri.encodeQueryComponent(Global.user.username)}&user_id=${Global.user.id}&nickname=${Uri.encodeQueryComponent(Global.user.nickname)}";
//  final encodedQueryStr = Uri.encodeQueryComponent(queryStr);
  return showDialog(
    context: context,
    builder: (_) => HtmlPage(
      url: 'https://${ApiUrl.feedbackUrl}?$queryStr',
      title: '意见反馈'.tr,
    ),
  );
}

Future showToTipOffPage(BuildContext context,{
  @required String accusedUserId,
  @required String accusedName,
  int complaintType = 2,
}) {
  final _accusedNickName = Uri.encodeQueryComponent(accusedName);
  final userName = Uri.encodeQueryComponent(Global.user.username);
  final nickName = Uri.encodeQueryComponent(Global.user.nickname);
  final String url =
      'https://${ApiUrl.reportUrl}?complaint_type=$complaintType&accused_id=$accusedUserId&accused_name=$_accusedNickName&user_name=$userName&user_id=${Global.user.id}&nickname=$nickName&udx=93${DateTime.now().millisecondsSinceEpoch}3c';
  return showDialog(
    context: context,
    builder: (_) => HtmlPage(
      url: url,
      title: '举报'.tr,
    ),
  );
}

