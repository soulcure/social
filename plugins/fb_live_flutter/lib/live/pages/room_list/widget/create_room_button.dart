import 'package:fb_live_flutter/live/api/fblive_model.dart';
import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/net/error_handle.dart';
import 'package:fb_live_flutter/live/pages/create_room/create_room_web.dart';
import 'package:fb_live_flutter/live/utils/config/route_path.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/other/float/float_mode.dart';
import 'package:fb_live_flutter/live/utils/other/float_util.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/dialog_util.dart';
import 'package:fb_live_flutter/live/utils/ui/theme_dialog.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

import '../../../net/api.dart';
import '../../../utils/manager/permission_manager.dart';
import '../../../utils/ui/loading.dart';
import '../../create_room/create_room.dart';
import '../../live_room/room_middle_page.dart';

class CreateRoomButton extends StatelessWidget {
  final String? title;
  final Size? size;
  final double? circular;
  final GestureTapCallback? onTap;

  const CreateRoomButton({
    Key? key,
    this.title,
    this.size,
    this.circular,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClickEvent(
      onTap: () async {
        if (onTap != null) {
          onTap!();
          return;
        }
        await navigatorCreateRoom(context);
      },
      child: Container(
        alignment: Alignment.center,
        height: size!.height,
        width: size!.width,
        decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(circular!)),
        child: Text(title!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1,
            )),
      ),
    );
  }
}

Future closeLive(String roomId) async {
  final Map status = await Api.mandatoryClose(roomId);
  if (status["code"] == 200) {
    myToast("暂无直播权限");
  }
}

Future<void> againLive(
    BuildContext context, String? roomId, String? roomLogo, bool isObs) async {
  final LiveValueModel liveValueModel = LiveValueModel();

  liveValueModel.setRoomInfo(
      roomId: roomId!,
      serverId: fbApi.getCurrentChannel()!.guildId,
      channelId: fbApi.getCurrentChannel()!.id,
      roomLogo: roomLogo ?? "",
      status: 2,
      liveType: 4,
      roomInfoObject: liveValueModel.roomInfoObject);

  if (kIsWeb) {
    liveValueModel.isAnchor = true;

    /// 设置是否obs
    liveValueModel.setObs(isObs);

    await RouteUtil.push(
        context,
        RoomMiddlePage(
          liveValueModel: liveValueModel,
        ),
        "liveRoomWebContainer");
  } else {
    if (!await PermissionManager.requestPermission(
        type: PermissionType.createRoom)) {
      // "获取权限失败";
      myFailToast('开启直播需要相机/录音权限，当前权限被禁用');
      return;
    }

    liveValueModel.setObs(isObs);
    liveValueModel.isAnchor = true;

    await RouteUtil.push(
        context,
        RoomMiddlePage(
          liveValueModel: liveValueModel,
        ),
        "/liveRoom");
  }
}

/*
* 跳转到创建房间页面
*
* isToPage：是否需要跳转页面，主动点击开播按钮值为true，列表初始化调用值为false；
* isToPage-true：当无法恢复直播时会弹出提示，当有悬浮窗实体且房间是同一个会直接打开；
* isToPage-false：当无法恢复直播时不会弹出提示；
* */
Future navigatorCreateRoom(
  BuildContext context, {
  bool isToPage = true,
  String? guildId,
  String? channelId,
}) async {
  final liveChannel =
      fbApi.getLiveChannel(guildId, channelId) ?? fbApi.getCurrentChannel();
  final LiveValueModel liveValueModel = LiveValueModel();

  final Map dataMap = await Api.checkRoom();

  /// 情况如下：
  /// 1。接口调用失败，请求异常：如果isToPage为true弹出异常toast
  /// 2。接口调用成功，接口200：有开启的直播间
  /// 3。接口调用成功，接口404：没有开启的直播间
  if (ExceptionHandle.isReqError(dataMap['code'])) {
    if (isToPage) {
      dismissAllToast();
      myFailToast(ExceptionHandle.reqErrorText[dataMap['code']]);
    }
    return;
  }

  if (dataMap["code"] == 200) {
    final String? roomId = dataMap["data"]["roomId"];
    final String? roomLogo = dataMap["data"]["roomLogo"];
    final String? serverId = dataMap["data"]["serverId"];
    final int? liveType = dataMap["data"]["liveType"];
    final String? channelId = dataMap["data"]["channelId"];

    liveValueModel.setRoomInfo(
        roomId: roomId!,
        serverId: serverId!,
        channelId: channelId!,
        roomLogo: roomLogo ?? "",
        status: 2,
        liveType: 4,
        roomInfoObject: liveValueModel.roomInfoObject);

    final bool cantRestoreHandle = await DialogUtil.cantRestoreHandle(
        context, channelId, serverId, roomId, liveType,
        isShowDialog: isToPage);
    if (cantRestoreHandle) {
      return;
    }

    if (dataMap["data"]["status"] == 2 && floatWindow.isHaveFloat) {
      Loading.cleanContext();
      if (isToPage) {
        floatWindow.pushToLive(FBLiveEvent.fullscreen);
      }
      return;
    }
    await ThemeDialog.themeDialogDoubleItem(
      context,
      title: '恢复直播提示',
      okText: "恢复直播",
      text: '直播意外中断了，是否继续恢复直播？',
      onPressed: () {
        if (liveChannel?.guildId == serverId) {
          againLive(
              context, roomId, roomLogo, dataMap["data"]["liveType"] == 3);
        } else {
          closeLive(roomId);
        }
      },
    );
  } else {
    if (!isToPage) {
      return;
    }

    final int isToPreview = await FloatUtil.pushToPreView(liveValueModel);

    /// 已跳到预览，不需要执行后面的了
    if (isToPreview == 1) {
      return;
    }

    final String? userId = fbApi.getUserId();
    await fbApi
        .getUserInfo(userId!, guildId: fbApi.getCurrentChannel()!.guildId)
        .then((value) {
      if (kIsWeb) {
        RouteUtil.push(
            context, CreateRoomWeb(nickName: value.name!), "createRoomWeb");
      } else {
        /// 关闭小窗
        floatWindow.close();

        /// 跳转到开播页面
        RouteUtil.push(
          context,
          CreateRoom(
            nickName: value.name!,
            liveChannel: liveChannel,
          ),
          RoutePath.liveCreateRoom,
        );
      }
    });
  }
}
