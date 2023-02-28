import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/topic_db.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/themes/const.dart';

import '../../../routes.dart';

// TODO 换个地方，删除此文件
///key为quoteId, value为回复数量
Map<String, int> mesIdReplyNum = {};

Widget buildReplyNum(BuildContext context, int num) {
  return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
      decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor.withOpacity(0.65),
          borderRadius: BorderRadius.circular(3)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "%s条回复".trArgs([num.toString()]),
            style: TextStyle(
              fontSize: 12,
              color: Get.theme.primaryColor,
              height: 1.33,
            ),
          ),
          Icon(IconFont.buffXiayibu, color: Get.theme.primaryColor, size: 10),
        ],
      ));
}

Widget buildParentTopic(Widget child, BuildContext context, MessageEntity mes) {
  /// 当消息包含链接，并且链接为消息链接，当文纯文本处理
  final alreadyHasPadding = mes.content is TextEntity &&
      ((mes.content as TextEntity).numUrls == 1 &&
          !((mes.content as TextEntity).urlList?.first?.isMessageLink ??
              false));

  const normalPadding = EdgeInsets.fromLTRB(12, 12, 16, 8);
  const linkPadding = EdgeInsets.fromLTRB(0, 0, 0, 8);

  return GestureDetector(
    onTap: () {
      Routes.pushTopicPage(context, mes);
    },
    child: Container(
      padding: alreadyHasPadding ? linkPadding : normalPadding,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        color: appThemeData.scaffoldBackgroundColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          Container(
            height: 27,
            margin: EdgeInsets.only(
                top: alreadyHasPadding ? 0 : 10,
                left: alreadyHasPadding ? 12 : 0),
            child: FutureBuilder<int>(
              key: UniqueKey(),
              future: getMesCount(mes),
              initialData: initCount(mes.channelId, mes.messageId),
              builder: (ctx, snap) {
                if (snap.hasData) {
                  return buildReplyNum(context, snap.data);
                } else {
                  return sizedBox;
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}

int initCount(String channelId, String messageId) {
  final tcController = TextChannelController.to(channelId: channelId);
  final local = tcController.messageList
      .where((element) =>
          element.quoteL1 == messageId &&
          element.localStatus == MessageLocalStatus.normal &&
          element.deleted == 0)
      .length;
  return local;
}

void setMesCount(MessageEntity mes) {
  if (mes.quoteTotal == null && mes.quoteL1 == null) return;
  if (mes.quoteTotal != null && mes.quoteL1 != null) {
    final replyNum = mes.quoteTotal;
    final curNum = mesIdReplyNum[mes.quoteL1] ?? 0;
    mesIdReplyNum[mes.quoteL1] = max(replyNum, curNum);
  } else if (mes.quoteTotal == null && mes.quoteL1 != null)
    mesIdReplyNum[mes.quoteL1] = 0;
}

Future<int> getMesCount(MessageEntity mes) async {
  int local = 0;
  final tcController = TextChannelController.to(channelId: mes.channelId);
  if (kIsWeb || !tcController.canReadHistory) {
    local = tcController.messageList
        .where((element) =>
            element.quoteL1 == mes.messageId &&
            element.localStatus == MessageLocalStatus.normal &&
            element.deleted == 0)
        .length;
  } else {
    local = await TopicTable.getAllMessageLengthByQuote(mes.messageId);
    if (local == 0) {
      local = initCount(mes.channelId, mes.messageId);
    }
  }

  mesIdReplyNum[mes.messageId] = local;
  return local;
}

bool isParentTopic(String id) => mesIdReplyNum[id] != null;
