import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fb_live_flutter/fb_live_flutter.dart' hide Loading, Api;
import 'package:fb_live_flutter/live/pages/live_room/widget/balance_widget.dart';
import 'package:fb_live_flutter/live/utils/pop_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/invite_api.dart';
import 'package:im/api/pay_api.dart';
import 'package:im/api/text_chat_api.dart';
import 'package:im/app/modules/mute/controllers/mute_listener_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/extension/uri_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/config.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/http_middleware/interceptor/logging_interceptor.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/db/db.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/global.dart';
import 'package:im/hybrid/jpush_util.dart';
import 'package:im/icon_font.dart';
import 'package:im/live_provider/widgets/emoji_keyboard.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/universal_rich_input_controller.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/tool/html_page.dart';
import 'package:im/pages/tool/url_handler/mini_program_link_handler.dart';
import 'package:im/pay/pay_manager.dart';
import 'package:im/routes.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/check_media_conflict_util.dart';
import 'package:im/utils/cos_file_upload.dart';
import 'package:im/utils/get_image_fom_camera_or_file.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/show_bottom_modal.dart' as modal;
import 'package:im/utils/universal_platform.dart';
import 'package:im/web/utils/image_picker/image_picker.dart' as web_img_picker;
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:im/widgets/circular_progress.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/select_button.dart';
import 'package:im/widgets/share_link_popup/share_link_popup.dart' as share;
import 'package:im/widgets/share_link_popup/share_link_popup.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart' as user_popup;
import 'package:im/ws/live_status_handler.dart';
import 'package:im/ws/ws.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

/// 提供给直播模块使用的接口类
class FBLiveApiProvider extends LiveApiProvider {
  FBLiveApiProvider._();

  static final FBLiveApiProvider _instance = FBLiveApiProvider._();

  static FBLiveApiProvider get instance => _instance;

  static const String kickOutOfGuild = "kickOutOfGuild";
  static const String showGiftConfirmDialog = "shoGiftConfirmDialog";

  /// 用来处理socket消息事件
  FBLiveMsgHandler _handler;

  /// 用来监听socket消息
  StreamSubscription _wsSubscription;

  /// 关闭小窗回调通知
  Set<OnLiveClose> _onLiveCloseListeners;
  Set<FBLiveEventListener> _fbEventListeners;

  /// ws连接状态回调
  FBWsConnectionStatusCallback _callback;

  /// 正在观看的直播间id
  LiveRoomInfo _currentLiveRoom;

  /// 是否正在直播或正在观看直播
  bool get hasLive => _currentLiveRoom != null;

  bool get isStreamer => _currentLiveRoom?.isStreamer;

  String get currentLiveRoomId => _currentLiveRoom?.roomId;

  @override
  GlobalKey<NavigatorState> get globalNavigatorKey => Global.navigatorKey;

  @override
  Logger get fbLogger => Logger.root;

  @override
  Interceptor get loggingInterceptor => LoggingInterceptor();

  /// 获取当前用户token
  @override
  String getToken() {
    return Config.token;
  }

  /// 获取当前用户id
  @override
  String getUserId() {
    return Global.user.id;
  }

  void closePayPage() {
    if (!UniversalPlatform.isAndroid) return;
    platform.invokeMethod('closePayPage');
  }

  // /// 直播间列表(直播首页)返回事件
  // @override
  // void roomListBackAction() {
  //   final _isNotRecording = RecordSoundState.instance.second == 0;
  //   HomeScaffoldController.to.gotoWindow(0);
  // }

  /// 根据id获取用户信息
  @override
  Future<FBUserInfo> getUserInfo(String userId, {String guildId}) async {
    final userInfo = await UserInfo.get(getUserId());
    return userInfo2FB(userInfo, guildId: guildId);
  }

  /// 这种方式获取到的guildName有可能为空
  FBUserInfo userInfo2FB(UserInfo userInfo, {String guildId}) {
    return FBUserInfo(
      userId: userInfo.userId,
      shortId: userInfo.username,
      avatar: userInfo.avatar,
      nickname: userInfo.nickname,
      guildName: userInfo.gnick,
      name: userInfo.showName(guildId: guildId),
    );
  }

  FBUserInfo _fbUserFromJson(Map<String, dynamic> json) {
    final userId = (json['user_id'] ?? '') as String;
    final authorInfo = (json['author'] ?? {}) as Map<String, dynamic>;
    final shortId = (authorInfo['username'] ?? '') as String;
    final avatar = (authorInfo['avatar'] ?? '') as String;
    final nickname = (authorInfo['nickname'] ?? '') as String;
    final memberInfo = (json['member'] ?? {}) as Map<String, dynamic>;
    final guildName = (memberInfo['nick'] ?? '') as String;

    final u = FBUserInfo(
      userId: userId,
      shortId: shortId,
      avatar: avatar,
      nickname: nickname,
      guildName: guildName,
      name: guildName,
    );
    final markName = getMarkName(userId);
    final mName = markName.hasValue ? markName : null;
    final gName = guildName.hasValue ? guildName : null;
    u.name = (mName ?? gName) ?? nickname;
    return u;
  }

  /// 获取指定用户id列表各自应显示的名称，其规则为：备注 > 服务器昵称 > 原昵称
  /// 如果[guildId]不为空时，会分别为[userIds]获取[guildId]的服务器昵称(提前是没有备注）
  @override
  Future<Map<String, String>> getShowNames(List<String> userIds,
      {String guildId}) async {
    final Map<String, String> showNames = {};
    if (userIds == null || userIds.isEmpty) return showNames;
    final userList = await Future.wait(
        userIds.map((uid) => UserInfo.getUserInfoForGuild(uid, guildId)));
    userList.forEach((userInfo) {
      if (userInfo != null) {
        showNames[userInfo.userId] = userInfo.showName(guildId: guildId);
      }
    });
    return showNames;
  }

  /// 获取指定用户显示名，批量获取见[getShowNames]
  @override
  Future<String> getShowName(String userId, {String guildId}) async {
    final userInfo = await UserInfo.getUserInfoForGuild(userId, guildId);
    // final userInfo = await UserInfo.(userId);
    return userInfo.showName(guildId: guildId);
  }

  /// 获取传入所有用户的备注名
  /// @param userIds: 想要获取备注的用户id集合
  /// @return: 返回一个Map，键为用户id，值为用户的备注名
  @override
  Map<String, String> getMarkNames(List userIds) {
    if (userIds == null) return null;
    final markNames = {};
    String markName;
    for (final id in userIds) {
      markName = Db.remarkBox.get(id)?.name;
      if (markName != null && markName.isNotEmpty) {
        markNames[id] = markName;
      }
    }
    return markNames;
  }

  @override
  String getMarkName(String userId) {
    if (userId == null) return null;
    return Db.remarkBox.get(userId)?.name;
  }

  /// 返回展示用户名的组件，当修改备注或昵称时会实时同步
  @override
  Widget realtimeUserName(
    String userId, {
    String guildId,
    TextStyle style,
    int maxLines = 1,
    bool isGuest = false,
    String guestName,
  }) {
    if (userId == null) return const SizedBox();

    if (isGuest) {
      /// 返回游客名
      return Text(
        guestName ?? "",
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    /// 返回用户名
    return RealtimeNickname(
      userId: userId,
      guildId: guildId,
      showNameRule: ShowNameRule.remarkAndGuild,
      maxLines: maxLines,
      maxLength: 100,
      style: style,
    );
  }

  /// 返回展示用户头像的组件，当用户修改头像时会实时同步
  @override
  Widget realtimeAvatar(
    String userId, {
    double size = 30,
    bool isGuest = false,
    bool showNftFlag = true,
  }) {
    if (isGuest) {
      /// 返回游客头像
      // return Image.asset(
      //   "assets/images/icon.png",
      //   width: size,
      //   height: size,
      //   fit: BoxFit.cover,
      // );
      return Container(
        width: size,
        height: size,
        decoration: const ShapeDecoration(
          shape: CircleBorder(),
          color: Color(0xFFE0E2E6),
        ),
        child: Icon(
          IconFont.buffVisitorAvatar,
          color: Colors.white,
          size: size * 0.6,
        ),
      );
    }

    /// 返回用户头像
    return RealtimeAvatar(userId: userId, size: size, showNftFlag: showNftFlag);
  }

  /// 获取指定服务器的频道列表
  @override
  List<FBChatChannel> getGuildChannels(String guildId) {
    final List<FBChatChannel> fbChatChannels = [];

    GuildTarget _guildTargetModel;
    final list = ChatTargetsModel.instance.chatTargets;
    list.forEach((e) {
      if (e is GuildTarget && e.id == guildId) _guildTargetModel = e;
    });

    _guildTargetModel?.channels?.forEach((channel) {
      final isTextChannel = channel.type == ChatChannelType.guildText;
      final GuildPermission gp = PermissionModel.getPermission(channel.guildId);
      final canSendMes = PermissionUtils.oneOf(gp, [Permission.SEND_MESSAGES],
          channelId: channel.id);
      final isVisible = PermissionUtils.isChannelVisible(gp, channel.id);
      if (isTextChannel && canSendMes && isVisible) {
        fbChatChannels.add(FBChatChannel(
          id: channel.id,
          guildId: channel.guildId,
          guildName: _guildTargetModel.name,
          name: channel.name,
          topic: channel.topic,
        ));
      }
    });
    return fbChatChannels;
  }

  /// 获取当前频道信息
  @override
  FBChatChannel getCurrentChannel() {
    final channel = GlobalState.selectedChannel.value;
    final guildName =
        (ChatTargetsModel.instance.selectedChatTarget as GuildTarget).name;
    return FBChatChannel(
      id: channel.id,
      name: channel.name,
      topic: channel.topic,
      guildId: channel.guildId,
      guildName: guildName,
    );
  }

  @override
  FBChatChannel getLiveChannel(String guildId, String channelId) {
    if (guildId.noValue || channelId.noValue) return null;
    final channel = Db.channelBox?.get(channelId);
    final guild = ChatTargetsModel.instance.getGuild(guildId);
    if (channel == null || guild == null) return null;
    return FBChatChannel(
      id: channel.id,
      name: channel.name,
      topic: channel.topic,
      guildId: channel.guildId,
      guildName: guild.name,
    );
  }

  /// 是否在音视频频道
  @override
  bool inAVChannel() {
    return GlobalState.mediaChannel.value != null;
  }

  /// 退出音视频频道
  @override
  Future<bool> exitAVChannel() async {
    return checkAndExitAVChannel(purpose: "进入直播间".tr);
  }

  /// 当前用户是否有开播权限
  @override
  bool canStartLive({String guildId, String channelId}) {
    final gId = (guildId == null || guildId.isEmpty)
        ? ChatTargetsModel.instance.selectedChatTarget?.id
        : guildId;
    final cId = (channelId == null || channelId.isEmpty)
        ? GlobalState.selectedChannel.value?.id
        : channelId;

    final guildPermission = PermissionModel.getPermission(gId);
    final hasCreateLivePermission = PermissionUtils.oneOf(
      guildPermission,
      [Permission.CREATE_LIVE_ROOM],
      channelId: cId,
    );
    return hasCreateLivePermission;
  }

  /// 当前用户是否有查看直播/回放权限
// @override
// bool hasWatchLivePermission(String guildId, String channelId, String userId) {
//   return PermissionUtils.isChannelVisible(
//     PermissionModel.getPermission(guildId),
//     channelId,
//     userId: userId,
//   );
// }

  /// 创建直播间前，审核敏感信息
  /// @param desc: 直播间描述
  /// @return 如果审核通过则返回true，没通过则返回false
  @override
  Future<bool> inspectLiveRoom({String desc, List<String> tags}) async {
    String msg;
    if (desc != null) {
      msg = "$desc ";
    }
    if (tags != null) {
      msg ??= "";
      msg += tags.where((str) => str != null).join(' ');
    }
    if (msg == null) return true;

    return CheckUtil.startCheck(
      TextCheckItem(msg, TextChannelType.FB_LIVE_DESC),
    );
  }

  /// 直播聊天消息敏感信息审核，在发送消息前调用
  /// @param msg: 聊天消息
  /// @return 如果审核通过返回true，如果失败则返回false
  @override
  Future<bool> inspectChatMsg(String msg) async {
    return CheckUtil.startCheck(
      TextCheckItem(msg, TextChannelType.FB_LIVE_TEXT_MSG),
    );
  }

  /// 发送socket消息
  Future _sendWsMessage({
    @required String guildId,
    @required String channelId,
    @required String roomId,
    @required String action,
    Map<String, dynamic> extra,
  }) {
    // final channel = GlobalState.selectedChannel.value;
    final Map<String, dynamic> data = {
      "channel_id": roomId,
      "guild_id": guildId,
      "guild_channel_id": channelId,
      "action": action,
    };
    if (extra != null) {
      data.addAll(extra);
    }
    return Ws.instance.send(data);
  }

  /// 检测当前是否选中直播间所属的服务器，如果不是，则切换到此服务器
  Future _checkAndSwitchToLiveGuild() async {
    if (_currentLiveRoom == null ||
        _currentLiveRoom.guildId == GlobalState.selectedChannel.value.guildId)
      return;

    /// 当前选中的服务器并非直播间所在的服务器，切换回直播间所属的服务器
    return ChatTargetsModel.instance
        .selectChatTargetById(_currentLiveRoom.guildId);
  }

  /// 发送的socket消息告知服务器用户进入直播间
  @override
  Future enterLiveRoom(
    String channelId,
    String roomId,
    bool isAnchor,
    String guildId,
    bool isSmallWindow,
  ) async {
    if (_currentLiveRoom?.roomId == roomId) {
      // 如果已经上报过则不重复上报
      return;
    }
    if (isSmallWindow) {
      /// 如果是小窗模式，检测当前选中的服务器是否为直播间服务器，且不会上报进入直播间的socket事件
      unawaited(_checkAndSwitchToLiveGuild());
      return;
    }
    _currentLiveRoom = LiveRoomInfo(
      roomId: roomId,
      isStreamer: isAnchor,
      guildId: guildId,
    );
    await _sendWsMessage(
        guildId: guildId,
        channelId: channelId,
        roomId: roomId,
        action: "liveJoin");
    final user = await getUserInfo(getUserId(), guildId: guildId);
    _handler?.onUserEnter(user);
  }

  /// 发送socket消息告知服务器用户退出直播间
  @override
  Future exitLiveRoom(String guildId, String channelId, String roomId) async {
    final res = await _sendWsMessage(
        guildId: guildId,
        channelId: channelId,
        roomId: roomId,
        action: "liveQuit");
    _currentLiveRoom = null;
    return res;
  }

  /// 发送socket消息告知服务器主播已停止直播
  @override
  Future stopLive(String guildId, String channelId, String roomId) async {
    await _sendWsMessage(
        guildId: guildId,
        channelId: channelId,
        roomId: roomId,
        action: "liveDisband");
    _handler?.onLiveStop();
    _currentLiveRoom = null;
  }

  /// 直播网络异常重连时需发此消息告诉服务端重建会话，否则无法收到livePush
  @override
  Future sendLiveConnect(
      String guildId, String channelId, String roomId) async {
    await _sendWsMessage(
      guildId: guildId,
      channelId: channelId,
      roomId: roomId,
      action: 'liveConnect',
    );
  }

  /// 获取直播间历史消息列表
  ///
  /// 查询[roomId]的历史消息列表，[lastMessageId]为上一页最后一条消息的messagageId,如果
  /// 不传或者传空的话则为第一页
  @override
  Future<List<Map<String, dynamic>>> getLiveHistoryMessages(
    String userId,
    String roomId, {
    String lastMessageId,
  }) async {
    try {
      final List<dynamic> result = await TextChatApi.pullMessages(
        userId,
        roomId,
        lastMessageId,
      );
      return result?.map((e) => e as Map<String, dynamic>)?.toList();
    } catch (e) {
      if (e is RequestArgumentError && e.code == 1012) {
        logger.warning('获取历史消息列表无权限 code 1012');
      } else {
        logger.warning('获取历史消息列表出错 ${e.toString()}');
      }
      return null;
    }
  }

  /// 发送弹幕消息
  /// @param roomId: 直播间房间id
  /// @param msg: 弹幕消息
  /// @param json: 自定义消息，json字符串
  @override
  Future sendLiveMsg(
      String guildId, String channelId, String roomId, String json) async {
    if (!MuteListenerController.to.isMuted) {
      await _sendWsMessage(
        guildId: guildId,
        channelId: channelId,
        roomId: roomId,
        action: "liveSend",
        extra: {
          "type": 4,
          "content": json,
        },
      );
    }
    final user = await getUserInfo(getUserId(), guildId: guildId);
    _handler?.onReceiveChatMsg(user, json);
  }

  /// 发送礼物
  /// @param roomId: 直播间房间id
  /// @param giftId: 礼物id
  /// @param json: 自定义消息，json字符串
  @override
  Future sendLiveGift(
      String guildId, String channelId, String roomId, String json) async {
    await _sendWsMessage(
      guildId: guildId,
      channelId: channelId,
      roomId: roomId,
      action: "liveSend",
      extra: {
        "type": 5,
        "content": json,
      },
    );
    final user = await getUserInfo(getUserId(), guildId: guildId);
    _handler?.onSendGift(user, json);
  }

  /// 发送商品通知
  @override
  Future sendGoodsNotice(String guildId, String channelId, String roomId,
      String type, String json) async {
    await _sendWsMessage(
      guildId: guildId,
      channelId: channelId,
      roomId: roomId,
      action: 'liveNote',
      extra: {
        'type': type,
        'content': json,
      },
    );
    final user = await getUserInfo(getUserId());
    _handler?.onGoodsNotice(user, type, json);
  }

  /// 注册消息接收回调
  @override
  void registerLiveMsgHandler(FBLiveMsgHandler handler) {
    _handler = handler;

    /// 开始监听socket消息
    _wsSubscription ??= Ws.instance.on<WsMessage>().listen(_processWsEvent);
  }

  /// 移除消息接收回调
  @override
  void removeLiveMsgHandler(FBLiveMsgHandler handler) {
    _handler = null;
    if (_wsSubscription != null) {
      /// 取消监听socket消息
      _wsSubscription.cancel();
      _wsSubscription = null;
    }
  }

  /// fanbook内部与直播模块ws连接状态的转换
  FBWsConnectionStatus _toFBWsStatus(WsConnectionStatus status) {
    FBWsConnectionStatus _status;
    switch (status) {
      case WsConnectionStatus.connected:
        _status = FBWsConnectionStatus.connected;
        break;
      case WsConnectionStatus.connecting:
        _status = FBWsConnectionStatus.connecting;
        break;
      case WsConnectionStatus.disconnected:
        _status = FBWsConnectionStatus.disconnected;
        break;
      default:
        _status = FBWsConnectionStatus.connected;
    }
    return _status;
  }

  /// 获取当前连接状态
  FBWsConnectionStatus get wsConnectionStatus =>
      _toFBWsStatus(Ws.instance.connectionStatus.value);

  /// ws连接状态监听器
  void _connectStatusListener() => _callback?.call(wsConnectionStatus);

  /// 注册ws连接状态监听
  @override
  void registerWsConnectStatusCallback(FBWsConnectionStatusCallback callback) {
    // 多做层检测，注册前先移除一下
    if (_callback != null) {
      removeWsConnectStatusCallback();
    }
    _callback = callback;
    Ws.instance.connectionStatus.addListener(_connectStatusListener);
  }

  /// 移除ws连接状态监听
  @override
  void removeWsConnectStatusCallback() {
    _callback = null;
    Ws.instance.connectionStatus.removeListener(_connectStatusListener);
  }

  Future<FBUserInfo> _getUser(String userId, {String guildId}) async {
    final _user = await UserInfo.get(userId);
    final u = userInfo2FB(_user, guildId: guildId);
    return u;
  }

  /// 处理socket消息
  Future _processWsEvent(WsMessage event) async {
    if (_handler == null) return;

    final data = event.data;
    switch (event.action) {

      /// 送礼或弹幕聊天消息
      case "livePush":
        final int type = data["type"];
        final String json = data["content"];
        final String userId = data["user_id"];
        final String guildId = data["guild_id"];

        /// livePush直接将用户昵称和直播间所属服务器昵称一起传过来
        FBUserInfo user = _fbUserFromJson((data ?? {}) as Map<String, dynamic>);
        // TODO 服务端发布前做个兼容(即服务端更新livePush方式，将nickname等信息带过来)
        if (!user.nickname.hasValue) {
          user = await _getUser(userId, guildId: guildId);
        }
        if (type == 4) {
          // 弹幕消息
          _handler.onReceiveChatMsg(user, json);
        }
        if (type == 5) {
          // 送礼消息
          _handler.onSendGift(user, json);
        }
        break;

      /// 商品消息通知
      case "liveNote":
        final String type = data["type"];
        final String json = data["content"];
        final String userId = data["user_id"];
        final user = await _getUser(userId);
        //productPush ,productRemove, couponPush , couponRemove
        if (type == 'productPush' ||
            type == 'productRemove' ||
            type == 'couponPush' ||
            type == 'couponRemove') {
          _handler.onGoodsNotice(user, type, json);
        }
        break;

      /// 用户进入直播间
      case "liveJoin":
        final userId = data["user_id"];
        // final user = await _getUser(userId);
        FBUserInfo user = _fbUserFromJson((data ?? {}) as Map<String, dynamic>);
        // TODO 同livePush
        if (!user.nickname.hasValue) {
          user = await _getUser(userId);
        }
        _handler.onUserEnter(user);
        break;

      /// 用户离开直播间
      case "liveQuit":
        final userId = data["user_id"];
        final user = await _getUser(userId);
        _handler.onUserQuit(user);
        break;

      /// 主播停播
      case "liveDisband":
        _handler.onLiveStop();
        break;

      case kickOutOfGuild:
        _handler.onKickOutOfGuild();
        break;
    }
  }

  /// 支付
  /// @param orderId: 旺旺的订单id
  /// @param productId: 第三方的商品ID
  /// @param productName: 第三方的商品名称
  /// @param price: 商品单价
  /// @param quantity: 购买商品数量
  /// @param totalPrice: 支付总金额（单位：元）
  /// @param productType:  商品种类，默认为虚拟商品
  /// @param extra: 透传字段:第三方可以自订义透传字段，服务端会回调给第三方的服务端
  @override
  Future<PaymentResult> charge({
    @required BuildContext context,
    @required String orderId,
    @required String productId,
    @required String productName,
    @required double price,
    @required String appId,
    int quantity = 1,
    double totalPrice,
    ProductType productType = ProductType.VP,
    String extra,
  }) {
    assert(orderId != null);
    assert(productId != null);
    assert(productName != null);
    assert(price != null);
    assert(appId != null);
    if (quantity == 1) {
      // 当商品数量为1（默认值）时，商品总价为商品单价
      totalPrice = price;
    }
    assert(totalPrice != null);

    const String payServiceOrder = '';

    // 商品类型
    String productTypeStr;
    if (productType == ProductType.VP) {
      productTypeStr = '1';
    } else if (productType == ProductType.RP) {
      productTypeStr = '2';
    }

    /// 支付类型
    PayType payType = PayType.SanDe;
    if (UniversalPlatform.isIOS) {
      payType = PayType.Apple;
    }

    /// 弹出等待弹窗
    Loading.hide();
    Loading.show(context, label: "连接中".tr);

    /// 处理返回值
    final _payCompleter = Completer<PaymentResult>();
    PayManager.pay(
        thirdOrderNo: orderId,
        payServiceOrder: payServiceOrder,
        appId: appId,
        price: price.toString(),
        productType: productTypeStr,
        payType: payType,
        extraInfo: extra,
        productId: productId,
        productName: productName,
        onSuccess: (productId) {
          Loading.hide();
          if (Platform.isIOS) {
            Loading.showDelayTip(context, "支付成功".tr,
                state: LoadingActivityState.success);
          }
          logger.info('支付成功 $productId');
          _payCompleter.complete(PaymentResult(
            orderId: orderId,
            status: PaymentStatus.completed,
          ));
          // ..orderId = orderId
          // ..status = PaymentStatus.completed);
        },
        onError: (code, message) {
          PaymentStatus status;
          Loading.hide();
          if (code == PayErrorCode.cancel.index.toString()) {
            if (Platform.isIOS) {
              Loading.showDelayTip(context, "支付取消".tr,
                  state: LoadingActivityState.fail);
            }
            status = PaymentStatus.cancel;
          } else if (code == PayErrorCode.timeOut.index.toString()) {
            if (Platform.isIOS) {
              Loading.showDelayTip(context, "系统繁忙".tr,
                  state: LoadingActivityState.fail);
            }
            status = PaymentStatus.cancel;
          } else {
            if (Platform.isIOS) {
              Loading.showDelayTip(context, "支付失败".tr,
                  state: LoadingActivityState.fail);
            }
            status = PaymentStatus.failed;
          }

          logger.severe('支付失败 code :$code message $message');
          _payCompleter.complete(
            PaymentResult(orderId: orderId, status: status),
          );
        });
    return _payCompleter.future;
  }

  /// 用户头部信息组件
  @override
  Widget userInfoComponent(BuildContext context, String userId,
      {String guildId, String channelId}) {
    if (userId == null || userId.isEmpty) return const SizedBox();
    return user_popup.userInfoComponent(
      context,
      userId,
      guildId: guildId ?? ChatTargetsModel.instance.selectedChatTarget.id,
    );
  }

  /// 唤起用户个人信息弹窗
  @override
  void showUserInfoPopUp(
    BuildContext context,
    String userId, {
    String guildId,
    bool showRemoveFromGuild = true,
    bool hideGuildName = false,
  }) {
    user_popup.showUserInfoPopUp(
      context,
      guildId: guildId ?? ChatTargetsModel.instance.selectedChatTarget?.id,
      userId: userId,
      showRemoveFromGuild: showRemoveFromGuild,
      hideGuildName: hideGuildName,
      enterType: user_popup.EnterType.fromServer,
    );
  }

  /// 唤起分享弹窗
  @override
  Future showShareLinkPopUp(
    BuildContext context,
    FBShareContent content,
  ) async {
    // TODO 这里暂时不区分分享类型
    // if (content.type == ShareType.webLive) {
    try {
      Loading.show(context);
      final url = await _getLiveRoomShareUrl(
        guildId: content.guildId,
        channelId: content.channelId,
        roomId: content.roomId,
        canWatchOutside: content.canWatchOutside,
      );
      final shareTitle = content.anchorName != null
          ? "%s的直播间".trArgs([content.anchorName])
          : "Fanbook直播间".tr;
      share.showShareLinkPopUp(context,
          link: url,
          title: "邀请好友加入直播间".tr,
          description: "分享此链接，朋友点击即可观看".tr,
          shareTitle: shareTitle,
          shareDesc: "来我的直播间，跟我一起互动吧".tr,
          shareCover: content.coverUrl,
          isGenQrCode: false,
          copyPrefix: '',
          guildId: _currentLiveRoom?.guildId,
          linkType: content.type == ShareType.webLive
              ? ShareLinkType.live
              : ShareLinkType.livePlayback);
    } finally {
      Loading.hide();
    }
    // }
  }

  /// 获取直播间分享链接
  Future<String> _getLiveRoomShareUrl({
    @required String guildId,
    @required String channelId,
    @required String roomId,
    bool canWatchOutside = false,
  }) async {
    final res = await InviteApi.getLiveInviteUrl(channelId: channelId);
    final url = Uri.parse(res["url"]);
    final Map<String, String> params = {};
    params["roomid"] = roomId;
    params["guildId"] = guildId;
    params["channelId"] = channelId;
    return url.addParams(params).toString();
  }

  /// 选择图片弹窗，弹起action sheet，让用户选择相机拍照或从相册选择
  /// @param crop: 选择图片后是否进行裁剪
  /// @param cropRatio: 控制裁剪图片的固定宽高比
  /// @param compressQuality: 图片裁剪后的压缩质量，取值区间：[0, 100]
  /// @param maxWidth: 图片最大裁剪宽度
  /// @param maxHeight: 图片最大裁剪高度
  /// @return 如果选择图片成功则返回图片的File对象，如果选择图片失败（如没有权限，或图片包含敏感信息）则返回null
  @override
  Future<File> pickImage(
    BuildContext context, {
    bool crop = true,
    CropAspectRatio cropRatio,
    int compressQuality = 100,
    int maxWidth,
    int maxHeight,
  }) {
    return getImageFromCameraOrFile(
      context,
      crop: crop,
      cropRatio: cropRatio,
      compressQuality: compressQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      channel: ImageChannelType.FB_LIVE_COVER,
    );
  }

  /// web端选择图片
  @override
  Future<Map> webPickImage() async {
    final image = await web_img_picker.ImagePicker.pickFile(accept: 'image/*');
    try {
      final compressedImgBytes =
          await webUtil.compressImageFromElement(image.pickedFile.path);

      final checkResult = await CheckUtil.startCheck(
        ImageCheckItem.fromBytes([
          U8ListWithPath(compressedImgBytes, image.pickedFile.path)
        ], ImageChannelType.headImage, needCompress: true),
      );
      if (!checkResult) {
        return null;
      }
      final bytes = await image.pickedFile.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      return {"fileName": image.fileName ?? timestamp, 'fileStream': bytes};
    } catch (e) {
      showToast('该图片已损坏，请重新选择'.tr);
      return null;
    }
  }

  /// 获取shared preference中key对应的数据
  @override
  dynamic getSharePref(String key) {
    return SpService.to.rawSp.get(key);
  }

  /// 保存value到SharedPreference
  /// @param key: 保存数据对应的键
  /// @param value: 要保存的数据，其类型只能为int，bool，double，String，List<String>中的一种
  /// @return 保存成功则返回true，否则返回false
  @override
// ignore: avoid_annotating_with_dynamic
  Future<bool> setSharePref(String key, dynamic value) async {
    if (value is int) {
      return SpService.to.rawSp.setInt(key, value);
    } else if (value is bool) {
      return SpService.to.rawSp.setBool(key, value);
    } else if (value is double) {
      return SpService.to.rawSp.setDouble(key, value);
    } else if (value is String) {
      return SpService.to.rawSp.setString(key, value);
    } else if (value is List<String>) {
      return SpService.to.rawSp.setStringList(key, value);
    }
    return false;
  }

  /// 移除shared preference中key对应的数据
// @override
// Future<bool> removeSharePref(String key) {
//   return SpService.to.rawSp.remove(key);
// }

  /// 唤起底部modal弹窗
  /// @param body: 弹窗内容组件
  /// @param header: 小横线下方，内容组件上方
  /// @param backgroundColor: 弹窗背景颜色
  /// @param showTopCache: 是否显示顶部小横线
  /// @param maxHeight: 其值为：弹窗展开的高度/屏幕高度，取值区间：(0, 1]
  @override
  void showBottomModal(
    BuildContext context, {
    @required Widget body,
    Widget header,
    Color backgroundColor,
    bool showTopCache = true,
    double maxHeight = 0.9,
  }) {
    modal.showBottomModal(
      context,
      builder: (c, s) => body,
      headerBuilder: (c, s) => header,
      backgroundColor: backgroundColor,
      showTopCache: showTopCache,
      maxHeight: maxHeight,
    );
  }

  /// 唤起底部ActionSheet
  /// @param actions: ActionSheet的item列表
  /// @param title: 标题文字，位于ActionSheet上方
  @override
  Future<int> showActionSheet(
    BuildContext context,
    List<Widget> actions, {
    String title,
  }) {
    return showCustomActionSheet(actions, title: title);
  }

  /// 向服务器发起请求
  /// @param path: url的path部分，如: /api/xxx/xxx
  /// @param data: 请求参数
  /// @param options: dio库的请求配置，详情见：https://github.com/flutterchina/dio/blob/master/README-ZH.md#%E8%AF%B7%E6%B1%82%E9%85%8D%E7%BD%AE
  /// @param autoRetryIfNetworkUnavailable: 如果为true，请求失败后根据配置策略重新尝试请求
  /// @param showDefaultErrorToast: 如果为true，请求失败后自动弹出错误信息
  /// @param cancelToken: dio用此参数来取消请求，详情见：https://github.com/flutterchina/dio/blob/master/README-ZH.md#%E8%AF%B7%E6%B1%82%E5%8F%96%E6%B6%88
  /// @param isOriginDataReturn: 如果为true则原样返回请求结果，如果为false，请求成功时返回请求结果里的data字段，请求失败时抛出RequestArgumentError异常
  /// @param isReturnString: 如果为true则返回json字符串，false则解析json后返回dynamic对象
// @override
// Future request(
//   String path, {
//   Map data,
//   Options options,
//   bool autoRetryIfNetworkUnavailable = false,
//   bool showDefaultErrorToast = false,
//   CancelToken cancelToken,
//   bool isOriginDataReturn = false,
//   bool isReturnString = false,
// }) {
//   return Http.request(
//     path,
//     data: data,
//     options: options,
//     autoRetryIfNetworkUnavailable: autoRetryIfNetworkUnavailable,
//     showDefaultErrorToast: showDefaultErrorToast,
//     cancelToken: cancelToken,
//     isOriginDataReturn: isOriginDataReturn,
//     isReturnString: isReturnString,
//   );
// }

  /// 上传直播相关文件
  /// @param file: 要上传的文件
  @override
  Future<String> uploadFile(File file) {
    return CosFileUploadQueue.instance
        .onceForPath(file.path, CosUploadFileType.live);
    // return uploadFileIfNotExist(
    //   bytes: file.readAsBytesSync().buffer.asUint8List(),
    //   filename: file.path,
    //   fileType: "live",
    // );
  }

  /// 弹出输入框，整合了自定义emoji表情键盘和发送按钮
  /// @param onSendText: 点击"发送".tr按钮的回调，会传入输入的文字
  /// @param maxLength: 输入最大字数
  @override
  void showEmojiKeyboard(
    BuildContext context, {
    OnSendText onSendText,
    int maxLength,
    TextEditingController inputController,
    double offset = 250,
  }) {
    Widget keyboard;
    if (kIsWeb) {
      assert(inputController != null);
      keyboard = WebEmojiKeyboard(
        // controller: inputController,
        // TODO web键盘，将直播模块代码抽成插件时，此处不好处理，先创建一个新的
        controller: UniversalRichInputController(),
        offset: 250,
      );
    } else {
      keyboard = EmojiKeyboard(
        onSendText: onSendText,
        maxLength: maxLength,
      );
    }
    Navigator.push(
      context,
      PopRoute(child: keyboard),
    );
  }

  /// 用于展示包含自定义emoji的聊天消息
  /// @param content: 可能包含自定义emoji的聊天消息文本
  /// @param textStyle: 文字样式
  /// @return 返回InlineSpan组件，结合RichText使用
  @override
  InlineSpan buildEmojiText(
    BuildContext context,
    String content, {
    TextStyle textStyle,
  }) {
    final context = Global.navigatorKey.currentContext;
    textStyle ??= Theme.of(context).textTheme.bodyText2;
    final richText = ParsedText(
      text: content ?? "",
      overflow: TextOverflow.ellipsis,
      style: textStyle,
      parse: [ParsedTextExtension.matchCusEmoText(context, textStyle.fontSize)],
    ).build(context) as ExtraRichText;
    return richText.text;
  }

  /// 展示支付弹窗
  void showPayBottomSheet(BuildContext context,
      {PaymentResultCallBack callback}) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return BalanceChooseSheet(paymentResultCallBack: callback);
      },
    );
  }

  /// 跳转到网页
  /// @param url: 网页地址
  /// @param title: 网页标题
  @override
  Future pushHTML(BuildContext context, String url, {String title}) {
    return Routes.pushHtmlPage(context, url, title: title);
  }

  /// 跳转到链接页面
  @override
  Future pushLinkPage(BuildContext context, String url, {String title}) {
    final bool isMiniProgramLink = MiniProgramLinkHandler().match(url);
    if (isMiniProgramLink) {
      // return pushMiniProgram(url);
      return Routes.pushMiniProgram(url);
    } else {
      return pushHTML(context, url, title: title);
    }
  }

// /// 跳转到小程序
// @override
// Future pushMiniProgram(String url) {
//   return Routes.pushMiniProgram(url);
// }

  /// 跳转到添加小助手页面
  @override
  Future pushAddAssistantsPage(
      String guildId, List<FBUserInfo> defaultSelectedUsers) {
    return Routes.pushAddAssistantsPage(guildId, defaultSelectedUsers);
  }

  /// 网页组件
  @override
  Widget htmlPage(String url, {String title}) {
    return HtmlPage(
      initialUrl: url,
      title: title,
    );
  }

  /// 是否是测试环境
  @override
  bool liveIsTestEnv() {
    return Config.env != Env.pro &&
        Config.env != Env.pre &&
        Config.env != Env.sandbox;
    // if (Config.env == Env.pro || Config.env == Env.pre) {
    //   return false;
    // }
    // return true;
  }

  /// 回到直播间列表页面
  void backToLiveRoomList({BuildContext context}) {
    Routes.backHome();
  }

  /// 路由跳转方法
  /// @param page: 要跳转的页面
  /// @param name: 页面名称，不可跟其他页面重复
  /// @param isReplace: 是否使用pushReplace跳转
  @override
  Future push(
    BuildContext context,
    Widget page,
    String name, {
    bool isReplace = false,
    bool fadeIn = false,
  }) {
    return Routes.push(context, page, name, replace: isReplace, fadeIn: fadeIn);
  }

  /// 推送消息通知
  /// [title] - 通知标题
  /// [content] - 通知内容
  /// [subtitle] - 子标题
  /// [fireTime] - 通知触发时间（毫秒）默认当前时间延迟100ms
  /// [addBadge] - 是否需要显示角标值
  /// [extra] - extra 字段
  @override
  Future pushNotification({
    String title,
    String content,
    String subtitle,
    DateTime fireTime,
    bool addBadge = false,
    Map<String, String> extra,
  }) {
    return JPushUtil.pushNotification(
      title: title,
      content: content,
      extra: extra,
      sound: UniversalPlatform.isIOS ? "ring2.caf" : "ring2.mp3",
      fireTime: fireTime,
      addBadge: addBadge,
      subtitle: subtitle,
    );
  }

  /// 自定义事件
  /// 此事件内部封装的 logType 为 [dlog_app_action_event_fb]
  /// [actionEventId] 行为事件主id
  /// [actionEventSubId] 行为事件子id
  /// [actionEventSubParam] 行为事件参数
  /// [pageId] 所在页面id
  /// [extJson] 扩展信息
  @override
  void customEvent(
      {String actionEventId = '',
      String actionEventSubId = '',
      String actionEventSubParam = '',
      String pageId = '',
      Map extJson}) {
    try {
      DLogManager.getInstance().customEvent(
          actionEventId: actionEventId,
          actionEventSubId: actionEventSubId,
          actionEventSubParam: actionEventSubParam,
          pageId: pageId,
          extJson: extJson);
    } catch (e) {
      logger.warning(e);
    }
  }

  /// 客户端自定义扩展事件
  /// 此事件是用来处理不同日志类型的,
  /// 日志类型为 [dlog_app_action_event_fb] 时,请使用 [customEvent]方法进行上报
  /// 日志类型非 [dlog_app_action_event_fb] 时,使用该接口进行上报
  /// [logType] 日志类型
  /// [extJson] 扩展信息
  @override
  void extensionEvent({@required String logType, Map extJson}) {
    try {
      DLogManager.getInstance()
          .extensionEvent(logType: logType, extJson: extJson);
    } catch (e) {
      logger.warning(e);
    }
  }

  /// 获取Fanbook图标
  @override
  AssetImage getFanbookIcon() {
    return const AssetImage('assets/images/icon.png');
  }

  @override
  Widget checkboxIcon(
    bool selected, {
    double size = 18.33,
    bool disabled = false,
  }) {
    return CheckButton(
      value: selected,
      size: size ?? 18.33,
      disabled: disabled ?? false,
    );
  }

  @override
  Widget circularProgressIcon(
    double size, {
    Color primaryColor = Colors.white,
    Color secondaryColor,
    int lapDuration = 1000,
    double strokeWidth = 1.67,
  }) {
    final _strokeWidth = strokeWidth ?? 1.67;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: CircularProgress(
          size: size - (_strokeWidth * 2),
          primaryColor: primaryColor ?? Colors.white,
          secondaryColor: secondaryColor ?? Colors.white.withOpacity(0),
          lapDuration: lapDuration ?? 1000,
          strokeWidth: _strokeWidth,
        ),
      ),
    );
  }

  /// 获取是否弹出过确认送礼弹窗，在点击外露在直播间输入框旁边的礼物时，需要调用此接口判断是否要弹出确认送礼弹窗
  @override
  bool isShowGiftConfirmDialog() {
    if (SpService.to.rawSp.containsKey(showGiftConfirmDialog)) {
      return SpService.to.rawSp.getBool(showGiftConfirmDialog);
    }
    return false;
  }

  /// 设置是否弹出过确认送礼弹窗
  @override
  void setShowGiftConfirmDialog(bool isShow) {
    SpService.to.rawSp.setBool(showGiftConfirmDialog, isShow);
  }

// /// 展示小窗
// @override
// void showSmallWindow(Widget content) {
//   Dock.show(content, customControl: true);
// }

  /// 隐藏小窗
// @override
// void hideSmallWindow() {
//   Dock.hide();
// }

// @override
// Future pushToLiveRoom(String roomId) async {
//   final res = await Api.getRoomInfo(roomId);
//   final String anchorId = res["anchorId"];
//   final String roomLogo = res["roomLogo"];
//   final isAnchor = Global.user.id == anchorId;
//   if (!kIsWeb && isAnchor) {
//     if (!await live_permission.PermissionManager.requestPermission(
//       type: live_permission.PermissionType.createRoom,
//     )) {
//       // "获取权限失败";
//       showToast(
//         '切换APP直播需要相机/录音权限，当前权限被禁用'.tr,
//         textPadding: EdgeInsets.fromLTRB(
//           FrameSize.px(40),
//           FrameSize.px(30),
//           FrameSize.px(40),
//           FrameSize.px(30),
//         ),
//       );
//       return;
//     }
//   }
//
//   if (kIsWeb) {
//     await push(
//       Global.navigatorKey.currentContext,
//       LiveRoomWebContainer(
//         isAnchor: isAnchor,
//         roomId: roomId,
//         roomLogo: roomLogo,
//       ),
//       "liveRoomWebContainer",
//     );
//   } else {
//     await push(
//       Global.navigatorKey.currentContext,
//       LiveRoom(
//         isAnchor: isAnchor,
//         roomId: roomId,
//         roomLogo: roomLogo,
//       ),
//       "liveRoom",
//     );
//   }
// }

  /// 添加直播事件监听
  @override
  void addFBLiveEventListener(FBLiveEventListener listener) {
    _fbEventListeners ??= HashSet();
    _fbEventListeners.add(listener);
  }

  /// 移除直播事件监听
  @override
  void removeFBLiveEventListener(FBLiveEventListener listener) {
    if (_fbEventListeners == null) return;
    _fbEventListeners.remove(listener);
    if (_fbEventListeners.isEmpty) {
      _fbEventListeners = null;
    }
  }

// ignore: use_setters_to_change_properties
  /// 注册关闭直播间事件回调接口（包括小窗模式）
  @override
  void registerLiveCloseListener(OnLiveClose onClose) {
    _onLiveCloseListeners ??= HashSet();
    _onLiveCloseListeners.add(onClose);
  }

  /// 注销关闭直播间回调接口
  @override
  void unregisterLiveCloseListener(OnLiveClose onClose) {
    if (_onLiveCloseListeners == null) return;
    _onLiveCloseListeners.remove(onClose);
    if (_onLiveCloseListeners.isEmpty) {
      _onLiveCloseListeners = null;
    }
  }

  void _eventHandler(FBLiveEvent event) {
    _fbEventListeners?.forEach(
      (listener) {
        if (listener != null) {
          listener(event);
        }
      },
    );
  }

  /// 发送通知告知直播间跳转到聊天页面
// @override
// void gotoChat() {
//   _eventHandler(FBLiveEvent.gotoChat);
// }

  /// 关闭小窗，返回是否关闭成功
  Future closeLive() async {
    final List<Future> closeTasks = [];
    _onLiveCloseListeners?.forEach((onCloseListener) {
      if (onCloseListener != null) {
        closeTasks.add(onCloseListener());
      }
    });
    return Future.wait(closeTasks);
  }

  /// 从小窗模式进入全屏模式
  void enterFullScreen() {
    _eventHandler(FBLiveEvent.fullscreen);
  }

  /// 直播列表刷新的时候接口成功返回时更新一下统计
  @override
  void liveStatisticsNotice(
    String guildId,
    String channelId,
    int count,
  ) {
    if (guildId == null || channelId == null || count < 0) {
      return;
    }
    final notice = <String, dynamic>{};
    notice.putIfAbsent('guild_id', () => guildId);
    notice.putIfAbsent('channel_id', () => channelId);
    notice.putIfAbsent('live_number', () => count);
    liveStatusHandler(notice);
  }
}
