import 'dart:async';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/pages/aid/aid_set_page.dart';
import 'package:fb_live_flutter/live/utils/config/route_path.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/other/float_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../event_bus_model/refresh_room_list_model.dart';
import '../model/live/obs_rsp_model.dart';
import '../net/api.dart';
import '../pages/create_room/create_param_page.dart';
import '../pages/create_room/create_room.dart';
import '../pages/create_room/create_room_web.dart';
import '../pages/live_room/room_middle_page.dart';
import '../pages/preview/live_preview.dart';
import '../utils/func/utils_class.dart';
import '../utils/live/base_bloc.dart';
import '../utils/manager/event_bus_manager.dart';
import '../utils/manager/permission_manager.dart';
import '../utils/theme/my_toast.dart';

enum CreateRoomItemType { privacy, obs, goods }

class CreateRoomBloc extends BaseAppCubit<int> with BaseAppCubitState {
  CreateRoomBloc() : super(0);

  State<CreateRoom>? statePage;

  bool isPrivacy = true;
  bool isGoodsValue = false;
  bool isExternal = false;
  RxBool isShowClean = true.obs;
  List<String> assistants = [];

  List<FBUserInfo>? aids = [];

  int openType = 2; //服务器权限 暂时不需要
  int shareType = 1; //分享类型：0-不分享、1-分享  默认选中
  bool isShareSelected = true;

  final LiveValueModel liveValueModel = LiveValueModel();

  /// 不允许为空，否则初始化就提示频道信息错误
  FBChatChannel? _liveChannel = fbApi.getCurrentChannel();

  String? imageUrl; //直播间封面

  final TextEditingController titleTextFiledCtr = TextEditingController();
  final TextEditingController channelTextFiledCtr = TextEditingController();

  /*
  * 获取路由上下文
  * */
  BuildContext? get context {
    return statePage?.context ?? fbApi.globalNavigatorKey.currentContext;
  }

  /*
  * 隐私设置和外部推流设置选项
  * */
  List<List> items = [
    ['直播间隐私配置', '分享后，允许游客在Fanbook外观看', CreateRoomItemType.privacy],
    ['外部推流直播', '开启后，将通过外部推流进行直播', CreateRoomItemType.obs],
  ];

  /*
  * 直播带货需求
  * */
  List<List> itemsNew = [
    ['开启商品货架', '开启后，可添加商品关联直播', CreateRoomItemType.goods],
  ];

  /*
  * 显示小助手的文字
  * */
  String get showAidStr {
    if (!listNoEmpty(aids)) {
      return "";
    }

    ///
    /// 【创建直播间】小助手显示信息优化，“只显示一个昵称（最多6个字符超过...显示）+等X人”
    ///
    /// 这个需求是      昵称+等X人     这里只显示一个人员得昵称，字符长度有限制
    ///
    /// 举例1：
    /// 昵称（吃不到葡萄说葡萄酸），这里显示：  吃不到葡萄说...等1人     如果选一个选多个都这样显示，只是人数累加
    ///
    /// 举例2：
    /// 昵称（小葡萄），这里显示，小葡萄等1人    如果选一个选多个都这样显示，只是人数累加
    final String? text = aids![0].name;

    /// 一个人的时候不需要「等」1人，直接显示该用户名称。直播UI验收11.16
    /// [2021 12.1]
    final manyPeopleStr =
        (aids?.length ?? 0) > 1 ? "等${aids?.length ?? 0}人" : "";
    if (text!.length > 6) {
      /// 【APP】直播助手选择三人及以上，显示数量不对
      /// 等x人
      ///
      /// 【创建直播间】小助手显示信息优化，“只显示一个昵称（最多6个字符超过...显示）+等X人”
      return "${text.substring(0, 6)}...$manyPeopleStr";
    } else {
      return text + manyPeopleStr;
    }
  }

  /*
  * 初始化
  * */
  Future<void> initBloc({
    State<CreateRoom>? creteRoom,
    State<CreateRoomWeb>? creteRoomWeb,
    FBChatChannel? liveChannel,
  }) async {
    _liveChannel = liveChannel ?? fbApi.getCurrentChannel();
    channelTextFiledCtr.text = _liveChannel?.name ?? '';
    statePage = creteRoom;

    /// 视图初始化第一帧检测频道
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      if (!strNoEmpty(_liveChannel?.id)) {
        /// 频道为空弹出提示，点任何一个按钮都直接退出当前页面
        Get.back();
        myFailToast("创建失败");
      }
    });

    /// web的在其他地方改
    if (!kIsWeb) {
      final userInfo = await fbApi.getUserInfo(
        fbApi.getUserId()!,
        guildId: _liveChannel!.guildId,
      );
      final String _name = userInfo.name ?? creteRoom!.widget.nickName;
      titleTextFiledCtr.text =
          "${_name.length > 8 ? "${_name.substring(0, 7)}..." : _name}的直播间";
    }
    isShowClean.value = strNoEmpty(titleTextFiledCtr.text);
    await getHasCommerce();

    await fbApi
        .getUserInfo(fbApi.getUserId()!, guildId: _liveChannel!.guildId)
        .then((userInfo) {
      imageUrl ??= userInfo.avatar;
      onRefresh();
    });

    /// 【APP】创建直播页有小窗
    unawaited(FloatUtil.dismissFloat(200));
  }

  /*
  * 主播是否具备带货能力
  * */
  Future getHasCommerce() async {
    final value = await Api.hasCommerce();
    if (value["code"] != 200) {
      return;
    }
    if (value['data']['hasCommerce']) {
      items.add(['开启商品货架', '开启后，可添加商品关联直播', CreateRoomItemType.goods]);
    }
    onRefresh();
  }

  /*
  * 选择完小助手数据点确定
  * */
  // ignore: type_annotate_public_apis
  void handleThen(List<FBUserInfo>? value) {
    if (value != null) {
      aids = value;
      final StringBuffer bufferId = StringBuffer();
      aids!.forEach((element) {
        bufferId.write(element.userId +
            (element.userId == aids![aids!.length - 1].userId ? "" : ","));
      });
      assistants = bufferId.toString().split(',');
      onRefresh();
    }
  }

  /*
  * 跳转到设置页面
  * */
  Future pushAidSet() async {
    if (!listNoEmpty(aids)) {
      /// 无数据时
      await fbApi
          .pushAddAssistantsPage(_liveChannel!.guildId, aids)
          .then((v) => handleThen(v as List<FBUserInfo>?));
    } else {
      /// 有数据时
      await fbApi
          .push(context!, AidSetPage(aids), "/aid_set_page")
          .then((v) => handleThen(v as List<FBUserInfo>?));
    }
  }

  /*
  * 设置图片url
  * */
  void setImageUrl(String img) {
    imageUrl = img;
    onRefresh();
  }

  /*
  * 创建房间
  * */
  Future createdRoom(FBChatChannel currentChannel) async {
    final Map dataMap = await Api.createLiveRoom(
      currentChannel.guildId,
      currentChannel.guildName,
      currentChannel.id,
      currentChannel.name,
      titleTextFiledCtr.text,
      imageUrl,
      [],
      [],
      openType,
      shareType,
      isExternal,
      isGoodsValue,
      assistants,
    );
    if (dataMap["code"] == 200) {
      final String? roomId = dataMap["data"]["roomId"];
      if (isExternal) {
        final obsAddressValue = await Api.obsAddress(roomId!);
        if (obsAddressValue['code'] != 200) {
          myFailToast('创建失败，请重试');
          return;
        }

        liveValueModel.obsModel = ObsRspModel.fromJson(obsAddressValue['data']);
        liveValueModel.setObs();
        if (!strNoEmpty(liveValueModel.obsModel?.url)) {
          myFailToast('obs地址为空，请重试');
          return;
        }
        await RouteUtil.push(
            context,
            CreateParamPage(roomId, imageUrl, currentChannel, liveValueModel),
            'createParamPage');
        return;
      }

      /*
      * 跳转直播事件
      * */
      if (roomId != null) {
        liveValueModel.isAnchor = true;
        liveValueModel.setRoomInfo(
            roomId: roomId,
            serverId: currentChannel.guildId,
            channelId: currentChannel.id,
            roomLogo: imageUrl ?? "",
            status: 2,
            liveType: 4,
            roomInfoObject: liveValueModel.roomInfoObject);

        if (kIsWeb) {
          await RouteUtil.push(
              context,
              RoomMiddlePage(
                liveValueModel: liveValueModel,
              ),
              "liveRoomWebContainer",
              isReplace: true);
        } else {
          await RouteUtil.push(
              context,
              LivePreviewPage(
                liveChannel: currentChannel,
                liveValueModel: liveValueModel,
              ),
              RoutePath.livePreviewPage,
              isReplace: true);
        }
      } else {
        myToast(dataMap["msg"]);
      }
    } else {
      myToast(dataMap["msg"]);
    }
  }

  /*
  * FBAPI--查询是否有音视频频道
  * */
  Future<bool> fbApiGetAVChannel() {
    final bool isInAVChannel = fbApi.inAVChannel();
    final Completer<bool> completer = Completer();

    // 有音视频线程
    if (isInAVChannel) {
      fbApi.exitAVChannel().then((_bool) {
        // 不同意退出
        if (!_bool) {
          // 返回上一层
          Navigator.pop(context!);
          EventBusManager.eventBus.fire(RefreshRoomListModel(true));
        } else {
          completer.complete(true);
        }
      });
    } else {
      completer.complete(true);
    }

    return completer.future;
  }

  /*
  * 发送开直播
  * */
  Future openLiveRoom() async {
    await fbApiGetAVChannel();

    final bool isCanStart = fbApi.canStartLive(
      guildId: _liveChannel?.guildId,
      channelId: _liveChannel?.id,
    );

    // 无开播权限
    if (!isCanStart) {
      myFailToast('您暂无开播权限, 请联系管理员！');
      return;
    }

    // 敏感信息查询
    final boolValue =
        await fbApi.inspectLiveRoom(desc: titleTextFiledCtr.text, tags: []);

    if (!boolValue) {
      return;
    }

    await createdRoom(_liveChannel!);
  }

  /*
  * 进入直播间
  * */
  Future interLive(BuildContext context) async {
    if (!strNoEmpty(titleTextFiledCtr.text)) {
      myFailToast('请输入直播间标题');
    } else if (titleTextFiledCtr.text.length > 20) {
      myFailToast('直播间标题输入有误，请重新输入');
    } else {
      await _createdLiveRoom();
    }
  }

  /*
  * 创建直播房间事件
  * */
  Future _createdLiveRoom() async {
    if (imageUrl == null) {
      final FBUserInfo? userInfo = await fbApi.getUserInfo(fbApi.getUserId()!,
          guildId: _liveChannel!.guildId);
      imageUrl = userInfo!.avatar;
    }
    if (!strNoEmpty(titleTextFiledCtr.text)) {
      myFailToast("请填写直播间标题");
      return;
    }
    if (!kIsWeb) {
      if (!await PermissionManager.requestPermission(
          type: PermissionType.createRoom)) {
        myFailToast('开启直播需要相机/录音权限，当前权限被禁用');
        return;
      }
    }

    // 创建开播请求
    await openLiveRoom();
  }

  /*
  * 开关切换且刷新
  * */
  void switchChange(
      bool isOut, bool isGoods, bool value, StateSetter refreshState) {
    if (isOut) {
      isExternal = value;
    } else if (isGoods) {
      isGoodsValue = value;
    } else {
      isPrivacy = value;
    }
    shareType = !isPrivacy ? 0 : 1;

    if (isGoods) {
      /// 因为货架开启需要显示小助手
      onRefresh();
    } else {
      /// 最简单的局部刷新
      refreshState(() {});
    }
  }
}
