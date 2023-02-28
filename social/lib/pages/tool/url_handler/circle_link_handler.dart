import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/models/circle_post_data_model.dart';
import 'package:im/app/modules/circle_detail/circle_detail_router.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/config.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/circle_page.dart';
import 'package:im/pages/guild_setting/circle/circle_share/circle_share_item.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/routes.dart' as old_routes;
import 'package:pedantic/pedantic.dart';

import 'link_handler.dart';

enum CircleLinkHandlerState {
  unhandled,
  handleJoined,
  handleUnJoined,
}

class CircleLinkHandler extends LinkHandler {
  CircleLinkHandlerState lastHandlerState = CircleLinkHandlerState.unhandled;

  final bool autoOpenHtml;

  CircleLinkHandler({this.autoOpenHtml = true});

  @override
  bool match(String url) {
    return url.startsWith(Config.circleShareUrl);
  }

  @override
  Future handle(String url, {RefererChannelSource refererChannelSource}) async {
    lastHandlerState = CircleLinkHandlerState.unhandled;
    final uri = Uri.parse(url);
    final postId = uri.pathSegments[1];
    if (postId.noValue) return;

    String guildId;
    CirclePostDataModel data;
    try {
      data = await getModelFromNet(null, null, postId, showErrorToast: true);
      guildId = data.postInfoDataModel.guildId;
    } catch (e) {
      debugPrint('circlePostDetail e = $e');
      return;
    }

    if (ChatTargetsModel.instance.isJoinGuild(guildId)) {
      lastHandlerState = CircleLinkHandlerState.handleJoined;
      unawaited(CircleDetailRouter.push(
        CircleDetailData(
          data,
          extraData: ExtraData(extraType: ExtraType.fromLink),
        ),
      ));
    } else {
      lastHandlerState = CircleLinkHandlerState.handleUnJoined;
      if (autoOpenHtml) {
        unawaited(old_routes.Routes.pushHtmlPageWithUri(Get.context, uri));
      }
    }
  }
}
