class FBLiveConfig {}

/// 分享类型
enum ShareType {
  /// web直播类型
  webLive,

  /// 回放类型
  playback,
}

enum FBLiveEvent {
  /// 跳转到聊天页面
  gotoChat,

  /// 从小窗进入全屏
  fullscreen,
}

/// 分享内容
class FBShareContent {
  /// 分享类型
  final ShareType type;
  final String roomId;
  final bool canWatchOutside;
  final String guildId; //直播间所属的服务器id
  final String channelId; //直播间所属的频道id
  final String coverUrl; //直播间封面url
  final String anchorName; //主播的名字

  FBShareContent({
    required this.type,
    required this.roomId,
    required this.canWatchOutside,
    required this.guildId,
    required this.channelId,
    required this.coverUrl,
    required this.anchorName,
  });
}

/// 直播用到的频道信息
class FBChatChannel {
  final String id;
  final String name;
  final String guildId;
  final String guildName;
  String? topic;

  FBChatChannel({
    required this.id,
    required this.name,
    required this.guildId,
    required this.guildName,
    this.topic,
  });
}

/// 直播用到的用户信息
class FBUserInfo {
  final String userId;
  final String shortId;
  final String avatar;
  final String nickname;
  String? guildName;
  String? name; // 展示的用户名

  FBUserInfo({
    required this.userId,
    required this.shortId,
    required this.avatar,
    required this.nickname,
    this.guildName,
    this.name,
  });

  @override
  String toString() {
    return 'FBUserInfo{userId: $userId, shortId: $shortId, name: $name}';
  }
}

typedef FBWsConnectionStatusCallback = Function(FBWsConnectionStatus);

enum FBWsConnectionStatus {
  disconnected,
  connecting,
  connected,
}

/// 直播消息回调接口
abstract class FBLiveMsgHandler {
  /// 用户进入直播间
  /// @param user: 进入直播间的用户
  void onUserEnter(FBUserInfo user);

  /// 用户退出直播间
  /// @param user: 退出直播间的用户
  void onUserQuit(FBUserInfo user);

  /// 主播停播
  void onLiveStop();

  /// 收到聊天弹幕消息
  /// @param user: 发送弹幕消息的用户
  /// @param json: 发送弹幕消息时的自定义消息
  void onReceiveChatMsg(FBUserInfo user, String json);

  /// 收到送礼消息
  /// @param user: 送礼物的用户
  /// @param json: 发送礼物消息时的自定义消息
  void onSendGift(FBUserInfo user, String json);

  /// 收到商品通知(推送/移除)
  /// @param user: 发送商品通知的用户(主播)
  /// @param type: 通知类型　productPush/productRemove/couponPush/couponRemove
  /// @param json: 发送商品通知的自定义消息
  void onGoodsNotice(FBUserInfo user, String type, String json);

  /// 用户被移出服务器
  void onKickOutOfGuild();
}

/// 商品类型
enum ProductType {
  /// 虚拟商品
  VP,

  /// 实物商品
  RP
}

enum PaymentStatus {
  /// 支付完成（不确定成功或失败，需要向服务器查询支付结果）
  completed,

  /// 支付取消
  cancel,

  /// 支付失败
  failed,
}

/// 支付结果
class PaymentResult {
  /// 支付结果
  final PaymentStatus status;

  /// 订单id（用于向服务器查询支付结果）
  final String orderId;

  PaymentResult({required this.status, required this.orderId});
}

/// 关闭直播间通知
typedef OnLiveClose = Future<bool> Function();

/// 直播相关事件监听接口
typedef FBLiveEventListener = Function(FBLiveEvent);

class LiveRoomInfo {
  final String roomId;
  final bool isStreamer;
  final String guildId;

  LiveRoomInfo({
    required this.roomId,
    required this.isStreamer,
    required this.guildId,
  });
}

typedef OnSendText = Function(String text);

abstract class EmojiKeyboardChangeListener {
  void onShow(double height);

  void onDismiss();
}
