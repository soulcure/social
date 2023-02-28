import 'dart:async';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/config.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/live_provider/live_api_provider.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/tool/url_handler/link_handler.dart';
import 'package:im/routes.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:pedantic/pedantic.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveLinkHandler extends LinkHandler {
  LiveLinkHandler();

  LiveLinkInfo parseParams(String url) {
    // 检验直播间链接参数
    if (!url.hasValue || !LiveLinkHandler().match(url)) return null;
    Map<String, List<String>> queryParamsMap = {};
    try {
      queryParamsMap = Uri.parse(url).queryParametersAll ?? {};
    } catch (e) {
      logger.warning('解析直播链接出错${e.toString()}');
    }
    final liveRoomID = queryParamsMap['roomid']?.first ?? '';
    final guildId = queryParamsMap['guildId']?.first ?? '';
    final channelId = queryParamsMap['channelId']?.first ?? '';
    if (!liveRoomID.hasValue || !guildId.hasValue || !channelId.hasValue) {
      return null;
    }
    return LiveLinkInfo(
        url: url, guildId: guildId, channelId: channelId, roomId: liveRoomID);
  }

  @override
  bool match(String url) {
    if (url == null || url.isEmpty) return false;
    // 直播分享url在openInstall中解析时的兼容处理
    // (https://xxxx/path?k-v 在浏览器中会重定向为 http://xxxx/path/?k-v）
    return url.startsWith('https://${Config.liveShareUrlPrefix}') ||
        url.startsWith('http://${Config.liveShareUrlPrefix}');
  }

  @override
  Future handle(String url, {RefererChannelSource refererChannelSource}) async {
    final linkInfo = parseParams(url);
    if (linkInfo == null) return;

    final _hasPermission = PermissionUtils.isChannelVisible(
        PermissionModel.getPermission(linkInfo.guildId), linkInfo.channelId);

    // 如果用户有直播间所属频道的频道权限(即对直播间所属频道可见)，则进入直播间原生页面
    // 其它情况进入h5当游客处理观看
    if (FBLiveApiProvider.instance.hasLive) {
      return;
    }
    if (UniversalPlatform.isMobileDevice) {
      if (_hasPermission) {
        JiGouLiveAPI.linkJumpLive(
            Global.navigatorKey.currentContext, linkInfo.roomId);
      } else {
        Routes.pushToH5LivePage(url);
      }
    } else {
      if (!kIsWeb) {
        Routes.pushToH5LivePage(url);
      } else {
        unawaited(launch(url, forceWebView: true, webOnlyWindowName: "live"));
      }
    }

    // final uri = Uri.parse(url);

    // final guildId = uri.queryParameters["guildId"];
    // final channelId = uri.queryParameters["channelId"];
    // final roomId = uri.queryParameters["roomid"];
    //
    // /// 有正在观看的直播
    // if (FBAPI.hasLive) {
    //   if (roomId == FBAPI.currentLiveRoomId) {
    //     /// 如果正在观看该直播，进入全屏模式
    //     FBAPI.enterFullScreen();
    //     return;
    //   }
    //
    //   /// 如果当前有正在观看的直播，且点击的分享链接不是该直播间，提醒用户先关闭当前直播
    //   if (!await checkAndExitLiveRoom()) {
    //     return;
    //   }
    // }

    //   if (guildId != null && channelId != null) {
    //     final gp = PermissionModel.getPermission(guildId);
    //     final isVisible = PermissionUtils.isChannelVisible(gp, channelId);
    //     if (isVisible) {
    //       /// 没有观看直播，直接跳转到直播页面
    //       unawaited(FBAPI.pushToLiveRoom(roomId));
    //       return;
    //     } else {
    //       showToast('没有权限查看此直播'.tr);
    //     }
    //   }
    //
    //   /// 直播分享链接
    //   if (!kIsWeb)
    //     Routes.pushToH5LivePage(url);
    //   else
    //     unawaited(launch(url, forceWebView: true, webOnlyWindowName: "live"));
  }
}

class LiveLinkInfo {
  String url;
  String guildId;
  String channelId;
  String roomId;

  LiveLinkInfo({
    this.url,
    this.guildId,
    this.channelId,
    this.roomId,
  });
}
