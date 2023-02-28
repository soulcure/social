import 'dart:async';
import 'dart:collection';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/event_bus_model/community_llive_bus.dart';
import 'package:fb_live_flutter/live/model/room_list_model.dart';
import 'package:fb_live_flutter/live/net/address.dart';
import 'package:fb_live_flutter/live/net/http_manager.dart';
import 'package:fb_live_flutter/live/pages/room_list/widget/create_room_button.dart';
import 'package:fb_live_flutter/live/utils/other/float/float_mode.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/widgets.dart';

/// 虚拟社区版本，固定直播间所属服务器及直播频道
/// TODO 修改需要指定guildId及channelId
const _roomGuildId = '236013604103520256'; // for test
const _roomChannelId = '276329091005677570'; // for test
const _userId = ''; // 可以获取指定主播userid的直播间 for test

/// 虚拟社区版本，提供相关直播操作接口
class CommunityLiveApi {
  /// 1.判断是否在直播接口
  /// 如果为空无直播，否则返回直播间模型
  static Future<RoomListModel?> getLivingStatus(
      String guildId, String channelId,
      {String userId = ''}) {
    return _getLivingStatus(guildId, channelId, userId);
  }

  /// 2.观众进入直播间接口
  /// 在确定有直播的情况下，传入[model]直播间模型
  static Future<void> enterLivingRoom(
    BuildContext context,
    RoomListModel model,
  ) {
    return _enterLivingRoom(context, model);
  }

  /// 3.关闭直播间接口
  /// 关闭直播小窗口
  static void closeLivingRoom() {
    initiativeCloseLiveEventBus.fire(InitiativeCloseLiveEvent());
    FloatPlugin.initiativeCloseLive();
  }

  /// 4.开始直播接口
  static void startLive(BuildContext context,
          {String? guildId, String? channelId}) =>
      navigatorCreateRoom(context, guildId: guildId, channelId: channelId);

  /// 5.是否有权限开播
  static bool hasPermission({String? guildId, String? channelId}) =>
      fbApi.canStartLive(guildId: guildId, channelId: channelId);

  /// 获取指定[guildId]及[channelId]正在直播的直播间
  static Future<RoomListModel?> _getLivingStatus(
    String guildId,
    String channelId,
    String userId,
  ) async {
    final params = SplayTreeMap<String, dynamic>();
    params["serverId"] = guildId;
    params["channelId"] = channelId;
    params["pageSize"] = 10;
    params["pageNum"] = 1;
    params["withObs"] = true;
    if (userId.isNotEmpty) params["anchorId"] = userId;
    final response = await HttpManager.getInstance()
        .get(Address.videolistUrl, params: params);
    final code = response['code'] ?? -1;
    final data = response['data'] ?? {};
    if (code != 200 || data['result'] == null) return null;
    final roomList = (data['result'] ?? []) as List<dynamic>;
    if (roomList.isEmpty) return null;
    return RoomListModel.fromJson(roomList[0] as Map<String, dynamic>);
  }

  /// 观众进入直播间
  static Future<void> _enterLivingRoom(
    BuildContext context,
    RoomListModel model,
  ) async {
    final bool isInAVChannel = fbApi.inAVChannel();
    if (isInAVChannel) {
      // 有音视频线程
      if (await fbApi.exitAVChannel()) {
        await _navigatorToLiveRoom(context, model);
      }
    } else {
      // 无音视频线程
      await _navigatorToLiveRoom(context, model);
    }
  }

  static Future<void> _navigatorToLiveRoom(
      BuildContext context, RoomListModel model) async {
    if (!floatWindow.isHaveFloat) {
      await _pushLiveRoom(context, model);
    } else {
      if (floatWindow.liveValueModel?.getRoomId != model.roomId) {
        await _pushLiveRoom(context, model);
        return;
      }

      floatWindow.pushToLive(FBLiveEvent.fullscreen);
    }
  }

  static Future<void> _pushLiveRoom(
    BuildContext context,
    RoomListModel model,
  ) async {
    unawaited(floatWindow.close());
    final bool isExternal = model.liveType == 3;

    final LiveValueModel liveValueModel = LiveValueModel();

    /// 设置logo
    liveValueModel.roomInfoObject!.roomLogo = model.roomLogo!;
    liveValueModel.roomInfoObject!.roomId = model.roomId!;
    liveValueModel.roomInfoObject!.channelId = model.channelId!;
    liveValueModel.roomInfoObject!.serverId = model.serverId!;
    liveValueModel.isAnchor = false;

    liveValueModel.setObs(isExternal);

    await fbApi
        .push(
            context,
            RoomMiddlePage(
              // ignore: avoid_bool_literals_in_conditional_expressions
              isOverlayViewPush: false,
              liveValueModel: liveValueModel,
            ),
            "/liveRoom")
        .then((value) async {
      /// 如果还是横屏则先等待反应好后再执行刷新列表
      if (FrameSize.isHorizontal()) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      // if (statePage.mounted) {
      //   await refreshController.requestRefresh();
      // }
    });
  }
}
