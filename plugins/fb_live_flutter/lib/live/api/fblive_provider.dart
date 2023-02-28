import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:logging/logging.dart';

late LiveApiProvider fbApi;
late LiveConfigProvider configProvider;

class LiveProvider {
  static void init(
      {required LiveApiProvider api, required LiveConfigProvider config}) {
    fbApi = api;
    configProvider = config;
  }
}

/// 配置接口
abstract class LiveConfigProvider {
  /// 直播模块使用的appId
  int get liveAppId;

  /// 直播模块使用的app签名
  String get liveAppSign;

  /// 直播模块的api请求地址
  String get liveHost;

  /// 直播web socket地址
  String get liveWssUrl;

  /// 直播obs查看详情地址
  String get obsExplainUrl;

  /// 直播屏幕共享配置-iOS
  String get appGroupID;

  String get extensionName;

  String get broadcastNotificationName;

  String get protocolHost;

  bool get openAuthorization;
}

/// 功能接口
abstract class LiveApiProvider
    with
        ApiAuxiliary,
        ApiLoggable,
        ApiWidget,
        ApiRoutable,
        ApiMessage,
        ChangeNotifier {}

/// 提供日志相关接口
abstract class ApiLoggable {
  /// fanbook重要日志输出
  Logger get fbLogger => Logger.root;

  /// fanbook网络日志拦截器
  Interceptor get loggingInterceptor;

  /// 自定义事件
  /// 此事件内部封装的 logType 为 [dlog_app_action_event_fb]
  /// [actionEventId] 行为事件主id
  /// [actionEventSubId] 行为事件子id
  /// [actionEventSubParam] 行为事件参数
  /// [pageId] 所在页面id
  /// [extJson] 扩展信息
  void customEvent({
    String actionEventId = '',
    String actionEventSubId = '',
    String actionEventSubParam = '',
    String pageId = '',
    required Map extJson,
  });

  /// 客户端自定义扩展事件
  /// 此事件是用来处理不同日志类型的,
  /// 日志类型为 [dlog_app_action_event_fb] 时,请使用 [customEvent]方法进行上报
  /// 日志类型非 [dlog_app_action_event_fb] 时,使用该接口进行上报
  /// [logType] 日志类型
  /// [extJson] 扩展信息
  void extensionEvent({required String logType, Map? extJson});
}

/// 提供组件接口
abstract class ApiWidget {
  /// 返回展示用户名的组件，当修改备注或昵称时会实时同步
  Widget realtimeUserName(
    String userId, {
    required String guildId,
    required TextStyle style,
    int maxLines = 1,
    bool isGuest = false,
    String? guestName,
  });

  /// 返回展示用户头像的组件，当用户修改头像时会实时同步
  Widget realtimeAvatar(
    String userId, {
    double size = 30,
    bool isGuest = false,
    bool showNftFlag = true,
  });

  /// 用户头部信息组件
  Widget userInfoComponent(
    BuildContext context,
    String userId, {
    required String guildId,
  });

  /// 用于展示包含自定义emoji的聊天消息
  /// @param content: 可能包含自定义emoji的聊天消息文本
  /// @param textStyle: 文字样式
  /// @return 返回InlineSpan组件，结合RichText使用
  InlineSpan buildEmojiText(
    BuildContext context,
    String content, {
    TextStyle? textStyle,
  });

  /// web组件
  Widget htmlPage(String url, {String? title});

  /// Fanbook图标组件
  AssetImage getFanbookIcon();

  /// 复选框组件
  Widget checkboxIcon(bool selected,
      {double size = 18.33, bool disabled = false});

  /// 加载态组件
  Widget circularProgressIcon(
    double size, {
    Color primaryColor = Colors.white,
    Color? secondaryColor,
    int lapDuration = 1000,
    double strokeWidth = 1.67,
  });

  /// 唤起用户个人信息弹窗
  void showUserInfoPopUp(
    BuildContext context,
    String userId, {
    required String guildId,
    bool showRemoveFromGuild = true,
    bool hideGuildName = false,
  });

  /// 唤起分享弹窗
  Future showShareLinkPopUp(
    BuildContext context,
    FBShareContent content,
  );

  /// 选择图片弹窗，弹起action sheet，让用户选择相机拍照或从相册选择
  /// @param crop: 选择图片后是否进行裁剪
  /// @param cropRatio: 控制裁剪图片的固定宽高比
  /// @param compressQuality: 图片裁剪后的压缩质量，取值区间：[0, 100]
  /// @param maxWidth: 图片最大裁剪宽度
  /// @param maxHeight: 图片最大裁剪高度
  /// @return 如果选择图片成功则返回图片的File对象，如果选择图片失败（如没有权限，或图片包含敏感信息）则返回null
  Future<File?> pickImage(
    BuildContext context, {
    bool crop = true,
    CropAspectRatio? cropRatio,
    int compressQuality = 100,
    int? maxWidth,
    int? maxHeight,
  });

  /// web端选择图片
  Future<Map?> webPickImage();

  /// 唤起底部modal弹窗
  /// @param body: 弹窗内容组件
  /// @param header: 小横线下方，内容组件上方
  /// @param backgroundColor: 弹窗背景颜色
  /// @param showTopCache: 是否显示顶部小横线
  /// @param maxHeight: 其值为：弹窗展开的高度/屏幕高度，取值区间：(0, 1]
  void showBottomModal(
    BuildContext context, {
    required Widget body,
    Widget? header,
    Color? backgroundColor,
    bool showTopCache = true,
    double maxHeight = 0.9,
  });

  /// 唤起底部ActionSheet
  /// @param actions: ActionSheet的item列表
  /// @param title: 标题文字，位于ActionSheet上方
  Future<int?> showActionSheet(
    BuildContext context,
    List<Widget> actions, {
    String? title,
  });

  /// 弹出输入框，整合了自定义emoji表情键盘和发送按钮
  /// @param onSendText: 点击"发送".tr按钮的回调，会传入输入的文字
  /// @param maxLength: 输入最大字数
  void showEmojiKeyboard(
    BuildContext context, {
    OnSendText? onSendText,
    int? maxLength,
    TextEditingController? inputController,
    double offset = 250,
  });
}

/// 提供路由相关接口
abstract class ApiRoutable {
  GlobalKey<NavigatorState> get globalNavigatorKey;

  /// 路由跳转方法
  /// @param page: 要跳转的页面
  /// @param name: 页面名称，不可跟其他页面重复
  /// @param isReplace: 是否使用pushReplace跳转
  Future push(
    BuildContext context,
    Widget page,
    String name, {
    bool isReplace = false,
    bool fadeIn = false,
  });

  /// 跳转到网页
  /// @param url: 网页地址
  /// @param title: 网页标题
  Future pushHTML(BuildContext context, String url, {String? title});

  /// 跳转到链接页面
  Future pushLinkPage(BuildContext context, String url, {String? title});

  /// 跳转到添加小助手页面
  Future pushAddAssistantsPage(
      String guildId, List<FBUserInfo>? defaultSelectedUsers);
}

/// 提供消息相关接口
abstract class ApiMessage {
  /// 发送的socket消息告知服务器用户进入直播间
  Future enterLiveRoom(String channelId, String roomId, bool isAnchor,
      String guildId, bool isSmallWindow);

  /// 发送socket消息告知服务器用户退出直播间
  Future exitLiveRoom(String guildId, String channelId, String roomId);

  /// 发送socket消息告知服务器主播已停止直播
  Future stopLive(String guildId, String channelId, String roomId);

  /// 直播网络异常重连时需发此消息告诉服务端重建会话，否则无法收到livePush
  Future sendLiveConnect(String guildId, String channelId, String roomId);

  /// 获取直播间历史消息列表
  ///
  /// 查询[roomId]的历史消息列表，[lastMessageId]为上一页最后一条消息的messagageId,如果
  /// 不传或者传空的话则为第一页
  Future<List<Map<String, dynamic>>> getLiveHistoryMessages(
    String userId,
    String roomId, {
    String? lastMessageId,
  });

  /// 发送弹幕消息
  /// @param roomId: 直播间房间id
  /// @param msg: 弹幕消息
  /// @param json: 自定义消息，json字符串
  Future sendLiveMsg(
      String guildId, String channelId, String roomId, String json);

  /// 发送礼物
  /// @param roomId: 直播间房间id
  /// @param giftId: 礼物id
  /// @param json: 自定义消息，json字符串
  Future sendLiveGift(
      String guildId, String channelId, String roomId, String json);

  /// 发送商品通知
  Future sendGoodsNotice(String guildId, String channelId, String roomId,
      String type, String json);

  /// 注册消息接收回调
  void registerLiveMsgHandler(FBLiveMsgHandler handler);

  /// 移除消息接收回调
  void removeLiveMsgHandler(FBLiveMsgHandler handler);

  /// 注册ws连接状态监听
  void registerWsConnectStatusCallback(FBWsConnectionStatusCallback callback);

  /// 移除ws连接状态监听
  void removeWsConnectStatusCallback();

  /// 直播列表刷新的时候接口成功返回时更新一下统计
  void liveStatisticsNotice(String guildId, String channelId, int count);

  /// 推送消息通知
  /// [title] - 通知标题
  /// [content] - 通知内容
  /// [subtitle] - 子标题
  /// [fireTime] - 通知触发时间（毫秒）默认当前时间延迟100ms
  /// [addBadge] - 是否需要显示角标值
  /// [extra] - extra 字段
  Future pushNotification({
    required String title,
    required String content,
    required String subtitle,
    DateTime? fireTime,
    bool addBadge = false,
    Map<String, String>? extra,
  });
}

/// 提供功能性接口
abstract class ApiAuxiliary {
  /// 是否是测试环境
  bool liveIsTestEnv();

  /// 获取当前用户token
  String? getToken();

  /// 获取当前用户id
  String? getUserId();

  /// 根据id获取用户信息
  Future<FBUserInfo> getUserInfo(String userId, {required String guildId});

  /// 获取指定用户id列表各自应显示的名称，其规则为：备注 > 服务器昵称 > 原昵称
  /// 如果[guildId]不为空时，会分别为[userIds]获取[guildId]的服务器昵称(提前是没有备注）
  Future<Map<String, String>> getShowNames(List<String> userIds,
      {required String guildId});

  /// 获取指定用户显示名，批量获取见[getShowNames]
  Future<String> getShowName(String userId, {required String guildId});

  /// 获取传入所有用户的备注名
  /// @param userIds: 想要获取备注的用户id集合
  /// @return: 返回一个Map，键为用户id，值为用户的备注名
  Map<String, String> getMarkNames(List<String> userIds);

  String? getMarkName(String userId);

  /// 获取指定服务器的频道列表
  List<FBChatChannel> getGuildChannels(String guildId);

  /// 获取当前频道信息
  FBChatChannel? getCurrentChannel();

  /// 获取指定服务台下指定频道
  FBChatChannel? getLiveChannel(String? guildId, String? channelId);

  /// 是否在音视频频道
  bool inAVChannel();

  /// 退出音视频频道
  Future<bool> exitAVChannel();

  /// 当前用户是否有开播权限
  bool canStartLive({String? guildId, String? channelId});

  /// 创建直播间前，审核敏感信息
  /// @param desc: 直播间描述
  /// @return 如果审核通过则返回true，没通过则返回false
  Future<bool> inspectLiveRoom({String? desc, List<String>? tags});

  /// 直播聊天消息敏感信息审核，在发送消息前调用
  /// @param msg: 聊天消息
  /// @return 如果审核通过返回true，如果失败则返回false
  Future<bool> inspectChatMsg(String msg);

  /// 支付
  /// @param orderId: 旺旺的订单id
  /// @param productId: 第三方的商品ID
  /// @param productName: 第三方的商品名称
  /// @param price: 商品单价
  /// @param quantity: 购买商品数量
  /// @param totalPrice: 支付总金额（单位：元）
  /// @param productType:  商品种类，默认为虚拟商品
  /// @param extra: 透传字段:第三方可以自订义透传字段，服务端会回调给第三方的服务端
  Future<PaymentResult> charge({
    required BuildContext context,
    required String orderId,
    required String productId,
    required double price,
    required String productName,
    required String appId,
    int? quantity,
    double? totalPrice,
    ProductType? productType,
    String? extra,
  });

  /// 获取shared preference中key对应的数据
  dynamic getSharePref(String key);

  /// 保存value到SharedPreference
  /// @param key: 保存数据对应的键
  /// @param value: 要保存的数据，其类型只能为int，bool，double，String，List<String>中的一种
  /// @return 保存成功则返回true，否则返回false
  // ignore: avoid_annotating_with_dynamic
  Future<bool> setSharePref(String key, dynamic value);

  /// 上传直播相关文件
  /// @param file: 要上传的文件
  Future<String> uploadFile(File file);

  /// 获取是否弹出过确认送礼弹窗，在点击外露在直播间输入框旁边的礼物时，需要调用此接口判断是否要弹出确认送礼弹窗
  bool? isShowGiftConfirmDialog();

  /// 设置是否弹出过确认送礼弹窗
  void setShowGiftConfirmDialog(bool isShow);

  /// 添加直播事件监听
  void addFBLiveEventListener(FBLiveEventListener listener);

  /// 移除直播事件监听
  void removeFBLiveEventListener(FBLiveEventListener listener);

  // ignore: use_setters_to_change_properties
  /// 注册关闭直播间事件回调接口（包括小窗模式）
  void registerLiveCloseListener(OnLiveClose onClose);

  /// 注销关闭直播间回调接口
  void unregisterLiveCloseListener(OnLiveClose onClose);

  List<EmojiKeyboardChangeListener> get emojiKeyboardChangeListeners =>
      EmojiKeyboardManager.listeners;
}

/// 直播键盘监听事件管理
class EmojiKeyboardManager {
  static List<EmojiKeyboardChangeListener> listeners = [];

  static void addOnChangeListener(EmojiKeyboardChangeListener listener) {
    listeners.add(listener);
  }

  static void removeOnChangeListener(EmojiKeyboardChangeListener listener) {
    listeners.remove(listener);
  }
}
