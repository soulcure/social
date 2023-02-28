import 'package:fb_live_flutter/live/model/live/live_simple_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/pages/other/link_loading_page.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';
import 'package:fb_live_flutter/live/utils/other/float/float_mode.dart';
import 'package:fb_live_flutter/live/utils/ui/dialog_util.dart';
import 'package:fb_live_flutter/live/utils/ui/loading.dart';
import 'package:flutter/material.dart';

class LinkLoadingBloc extends BaseAppCubit<int> with BaseAppCubitState {
  LinkLoadingBloc() : super(0);

  late State<LinkLoadingPage> statePage;

  /*
  * 房间概要信息模型
  * */
  LiveSimpleModel? model;

  /*
  * 上下文
  * */
  BuildContext get context {
    return statePage.context;
  }

  /*
  * 初始化
  * */
  void init(State<LinkLoadingPage> state) {
    statePage = state;
    startBroadcastStatus();
    return;
  }

  /*
  * 检测开播状态
  * */
  Future startBroadcastStatus() async {
    final Map dataMap = await Api.checkRoom();
    if (dataMap["code"] == 200) {
      final String? roomId = dataMap["data"]["roomId"];
      final String? serverId = dataMap["data"]["serverId"];
      final int? liveType = dataMap["data"]["liveType"];
      final String? channelId = dataMap["data"]["channelId"];

      final bool cantRestoreHandle = await DialogUtil.cantRestoreHandle(
          context, channelId, serverId, roomId, liveType);
      if (cantRestoreHandle) {
        return;
      }

      if (dataMap["data"]["status"] == 2 &&
          floatWindow.isHaveFloat &&
          statePage.widget.roomId != roomId) {
        RouteUtil.pop();
        Loading.cleanContext();
        Loading.showConfirmDialog(
            context,
            {
              'content': '你当前正处在直播中，请关闭直播后再重试',
              'confirmText': '确认',
              "cancelShow": false
            },
            () {});
        return;
      }
      await checkRoom();
    } else {
      await checkRoom();
    }
  }

  /*
  * 检测房间
  * */
  Future checkRoom() async {
    final Map resultData = await Api.liveSimple(statePage.widget.roomId);
    if (resultData["code"] == 200) {
      try {
        model = LiveSimpleModel.fromJson(resultData["data"]);
      } catch (e) {
        popErrorMsg("出现错误");
      }
      handleJumpToPage();
    } else {
      popErrorMsg(resultData['msg']);
    }
  }

  /*
  * 处理跳转页面逻辑
  * */
  void handleJumpToPage() {
    onRefresh();
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
