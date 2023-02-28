import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/routes.dart';

import 'link_handler.dart';

class CircleChannelLinkHandler extends LinkHandler {
  @override
  bool match(String url) {
    if (url.length > 5 && url.startsWith("#T") && url.contains('-')) {
      return true;
    }
    return false;
  }

  @override
  Future handle(String url, {RefererChannelSource refererChannelSource}) {
    final str = url.substring(2);
    final ids = str.split('-');
    if (ids.length < 2) return Future.error('#circle error');
    final gt = ChatTargetsModel.instance.getChatTarget(ids.last) as GuildTarget;
    final String circleId = gt.circleData['channel_id'] ?? '';
    if (circleId.noValue) return Future.error('#circle circleId error');
    return Routes.pushCircleMainPage(Get.context, ids.last, circleId,
        topicId: ids.first);
  }
}
