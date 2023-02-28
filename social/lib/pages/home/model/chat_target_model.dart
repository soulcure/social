import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluwx/fluwx.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/api/channel_api.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/app.dart';
import 'package:im/app/controllers/audio_room_controller.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/modules/friend_apply_page/controllers/friend_apply_page_controller.dart';
import 'package:im/app/modules/friend_list_page/controllers/friend_list_page_controller.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/app/modules/manage_guild/models/ban_type.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/config.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/db/db.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/hybrid/jpush_util.dart';
import 'package:im/pages/home/home_page.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/live_status_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/dock.dart';
import 'package:im/pages/home/view/tab_bar.dart';
import 'package:im/pages/home/view/text_chat/items/topic_share_item.dart';
import 'package:im/pages/tool/url_handler/link_handler_preset.dart';
import 'package:im/pages/video/model/video_room_controller.dart';
import 'package:im/pages/video/view/video_room_home_page.dart';
import 'package:im/pay/pay_manager.dart';
import 'package:im/routes.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/check_media_conflict_util.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/random_string.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/text_field/link_input.dart';
import 'package:im/ws/ws.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:tuple/tuple.dart';

import '../../../global.dart';
import '../../../loggers.dart';

part 'chat_target_model.g.dart';

ChatChannelType chatChannelTypeFromJson(int index) {
  if (index == null) return null;

  /// 未定义的枚举值暂时用服务器文字频道代替
  if (index < 0 || index >= ChatChannelType.values.length)
    return ChatChannelType.unsupported;
  return ChatChannelType.values[index];
}

int chatChannelTypeToJson(ChatChannelType e) =>
    ChatChannelType.values.indexOf(e);

@HiveType(typeId: 2)
enum ChatChannelType {
  @HiveField(0)
  guildText,
  @HiveField(1)
  guildVoice,
  @HiveField(2)
  guildVideo,
// 私信
  @HiveField(3)
  dm,
  @HiveField(4)
  guildCategory,
  @HiveField(5)
  guildCircle,
  @HiveField(6)
  guildLive,
  @HiveField(7)
  guildLink,
  @HiveField(8)
  liveRoom,
  @HiveField(9)
  task,
// 群聊
  @HiveField(10)
  group_dm,
  @HiveField(11)
  guildCircleTopic,

// dm频道的一种，用户服务器的通知频道
  @HiveField(12)
  circleNews,

// dm频道的一种，动态中产生的消息频道
  @HiveField(13)
  circlePostNews,
  @HiveField(256)
  unsupported,
}

@HiveType(typeId: 1)
class ChatChannel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1, defaultValue: '0')
  String guildId;
  @HiveField(2)
  String name;
  @HiveField(3)
  ChatChannelType type;
  @HiveField(4)
  String topic;
  @HiveField(5)
  String parentId;
  @HiveField(6)
  int position;

  // 由于格式变动，1.6.60 以上版本改成 botSettingList
  // @HiveField(7)
  // Map<String, List<String>> botSetting;
  @HiveField(8)
  String link;
  @HiveField(9)
  bool pendingUserAccess;
  @HiveField(10, defaultValue: 10)
  int userLimit;
  @HiveField(11, defaultValue: false)
  bool active;
  @HiveField(12, defaultValue: '')
  String icon;
  @HiveField(13)
  String description;
  @HiveField(14)
  List<DmGroupRecipientIcon> icons;

  bool expanded = true;

  //最后的消息ID，用于排序
  BigInt lastMessageId;

  ///关联的ID: 比如圈子动态ID,私信频道对方的userId
  @HiveField(15)
  String recipientId;

  ///关联的服务器ID：比如圈子频道的的服务器ID
  @HiveField(16)
  String recipientGuildId;

  // 频道快捷指令
  @HiveField(17)
  List<Map<String, String>> botSettingList;

  ChatChannel({
    this.id,
    this.guildId = '0',
    this.name,
    this.type,
    this.topic = "",
    this.parentId,
    this.position,
    this.botSettingList,
    this.link,
    this.pendingUserAccess,
    this.userLimit = 10,
    this.active = false,
    this.icon,
    this.icons,
    this.recipientId,
    this.recipientGuildId,
  }) {
    pendingUserAccess ??= false;
    // todo 想办法去掉这个
    expanded = (Db.channelCollapseBox?.get(id ?? "") ?? "") != "true";
    lastMessageId = BigInt.from(0);
  }

  ChatChannel clone() {
    return ChatChannel(
      id: id,
      guildId: guildId,
      name: name,
      type: type,
      topic: topic,
      parentId: parentId,
      position: position,
      botSettingList: botSettingList,
      link: link,
      pendingUserAccess: pendingUserAccess,
      userLimit: userLimit,
      active: active,
      icon: icon,
      icons: icons,
      recipientId: recipientId,
      recipientGuildId: recipientGuildId,
    );
  }

  ChatChannel.directMessage(String recipient)
      // ignore: prefer_initializing_formals
      : guildId = recipient;

  factory ChatChannel.fromJson(Map<String, dynamic> json) => ChatChannel(
        id: json['channel_id'] as String,
        guildId: json['guild_id'] as String,
        name: json['name'] as String,
        type: chatChannelTypeFromJson(json['type']),
        topic: json['topic'] as String ?? "",
        parentId: json["parent_id"] ?? '',
        position: json["position"] ?? 0,
        botSettingList: parseBotSetting(json["bot_setting_list"]),
        link: json['link'] ?? '',
        pendingUserAccess: json['pending_user_access'] as bool ?? false,
        userLimit: json['user_limit'] ?? 10,
        // 默认10人
        active: json['active'] == "1",
        icon: json['icon'] as String ?? '',
        icons: json['user_icon'] != null
            ? (json['user_icon'] as List)
                .map<DmGroupRecipientIcon>(
                    (e) => DmGroupRecipientIcon.fromJson(e))
                .toList()
            : null,
      );

  bool get canShowRedDot =>
      type == ChatChannelType.guildText ||
      type == ChatChannelType.dm ||
      type == ChatChannelType.guildCircleTopic;

  bool get canShowLiveIcon =>
      type == ChatChannelType.guildText || type == ChatChannelType.guildLive;

  bool get isPrivate => PermissionUtils.isPrivateChannel(
      PermissionModel.getPermission(guildId), id);

  // 是否服务器相关频道类型，不包括私聊、部落
  bool get isInGuild =>
      [ChatChannelType.dm, ChatChannelType.group_dm].contains(type);

  static List<Map<String, String>> parseBotSetting(List _json) {
    if (_json == null) return [];
    return _json.map((e) => Map<String, String>.from(e)).toList();
  }
}

class GlobalState {
  /// 未读消息数量
  static ValueNotifier<int> totalNumUnread = ValueNotifier(-9999);
  static ValueNotifier<int> totalRedDotNum = ValueNotifier(-9999);

  static ValueNotifier<bool> isHomePageInited = ValueNotifier(false);

  static bool isFirstOpenApp = false;

  static void updateBadge({bool force = false}) {
    if (totalRedDotNum.value == DirectMessageController.numUnread.value &&
        !force) return;
    totalRedDotNum.value = DirectMessageController.numUnread.value;
    // iOS只有在前台时才会去更新角标，因为在后台时本地通知已经就更新了角标，防止重复更新
    // Android在后台时的本地通知不会更新角标，所以Android不管在前后台都需要更新角标
    if ((UniversalPlatform.isIOS &&
            App.appLifecycleState == AppLifecycleState.resumed) ||
        UniversalPlatform.isAndroid) JPush().setBadge(totalRedDotNum.value);
  }

  /// 不包含任何 UI 操作，逻辑上的退出登录
  static void logout() {
    Config.permission = null;

    /// 停止苹果票据监听
    PayManager.removeObservingPaymentQueue();

    /// 用户登出事件
    DLogManager.getInstance().guildLogout();
    DLogManager.getInstance().userLogout();

    /// deleteAlias 有可能不生效，所以用这种方式
    if (UniversalPlatform.isMobileDevice)
      JPushUtil.setAlias(RandomString.length(12));
    Ws.instance.close();

    Future.delayed(const Duration(milliseconds: 300), () {
      Global.user = LocalUser()..cache();
      SpService.to.remove(SP.defaultChatTarget);
      if (kIsWeb) {
//        ChatTargetsModel.instance.directMessageListTarget = DirectMessageListTarget();
        // 暂时清理这4个，全部清除会出问题，暂时没时间找
        Db.remarkBox.clear();
        Db.remarkListBox.clear();
        Db.dmListBox.clear();
        Db.channelBox.clear();
        Db.guildBox.clear();
        Db.friendListBox.clear();
      }

      if (UniversalPlatform.isMobileDevice) {
        JPushUtil.clearAllNotification();
        JPush().setBadge(0);
      }
      JPushUtil.clearAllNotification();
    });
  }

  static int userIdLength = 17;
  static ValueNotifier<Tuple2<BaseChatTarget, ChatChannel>> mediaChannel =
      ValueNotifier(null);
  static ValueNotifier<ChatChannel> selectedChannel = ValueNotifier(null);

  static Future init() async {
    unawaited(FriendListPageController.to.init());
    unawaited(FriendApplyPageController.to.init());
  }

  static void updateDefaultSelectedChannel(String guildId, String channelId) {
    Db.guildSelectedChannelBox.put(guildId, channelId);
  }

  static void hangUp({bool notify = false}) {
    /// 为了防止挂断时切回旧文字频道和当前选中频道一致，导致 UI 不会刷新，此处需要交换一下临时选中频道
    /// 否则，将会导致音视频的 UI 不会被销毁，导致重新进入音视频报错
    selectedChannel.value = null;
    ChatTargetsModel.instance.selectedChatTarget?.selectDefaultTextChannel();

    Dock.hide();

    mediaChannel.value = null;
  }

  static bool get isDmChannel =>
      TextChannelController.dmChannel?.id != null ||
      (OrientationUtil.landscape &&
          ChatTargetsModel.instance.selectedChatTarget == null &&
          GlobalState.selectedChannel.value != null);
}

abstract class BaseChatTarget extends ChangeNotifier {
  ValueNotifier<int> get numUnread;

  ValueNotifier<String> _nameNotifier;

  ValueNotifier<String> get nameNotifier => _nameNotifier;
  String name;
  String id;

  BaseChatTarget(this.id, this.name) {
    _nameNotifier = ValueNotifier(name ?? '');
  }

  Future<void> setSelectedChannel(ChatChannel channel,
      {bool notify = false,
      bool gotoChatView = true,
      BuildContext context,
      String messageId}) async {
    /// 临时代码
    // channel.type = ChatChannelType.guildCircleTopic;

    Future<void> result = Future.value();
    if (channel == null) {
      GlobalState.selectedChannel.value = null;
      unawaited(HomeScaffoldController.to.gotoWindow(0));
      return result;
    }
    if (channel.type == ChatChannelType.unsupported) {
      showToast("当前版本不支持此频道".tr);
      return result;
    }

    // bool isVisible = true;
    final isLinkChannel = channel?.type == ChatChannelType.guildLink;
    final isAVChannel = channel?.type == ChatChannelType.guildVideo;
    final isCircleChannel = channel?.type == ChatChannelType.guildCircleTopic;
    // ||channel?.type == ChatChannelType.guildVoice;
    final isAudioChannel = channel?.type == ChatChannelType.guildVoice;
    final gotoChat =
        !isCircleChannel && !isLinkChannel && !isAudioChannel && gotoChatView;
    if (channel != null && channel.guildId != null) {
      // final gp = PermissionModel.getPermission(channel?.guildId);
      // isVisible = PermissionUtils.isChannelVisible(gp, channel.id);
    }

    if (isAVChannel) {
      final canGotoAVChannel = await checkAndExitLiveRoom();
      if (!canGotoAVChannel) {
        /// 有未关闭的直播，无法进入音视频频道
        return result;
      }
    }

    HomeTabBar.gotoIndex(0);
    if (GlobalState.selectedChannel.value == channel) {
      if (gotoChat) unawaited(HomeScaffoldController.to.gotoWindow(1));
      if (messageId != null) {
        return TextChannelController.to(channelId: channel.id)
            .jumpToMessage(messageId);
      } else {
        return result;
      }
    } else {
      if (!isLinkChannel &&
          !isAudioChannel &&
          !isCircleChannel &&
          !isAVChannel) {
        final GuildTarget gt =
            ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
        if (gt.userPending && !channel.pendingUserAccess) {
          GlobalState.selectedChannel.value = null;
          if (notify) notifyListeners();
          return result;
        } else {
          GlobalState.selectedChannel.value = channel;
        }
      }
      if (gotoChat) unawaited(HomeScaffoldController.to.gotoWindow(1));
    }

    final type = channel.type;
    switch (type) {
      case ChatChannelType.dm:
      case ChatChannelType.guildLive:
      case ChatChannelType.guildText:
        result = TextChannelController.to(channelId: channel.id).joinChannel();
        if (messageId != null) {
          await TextChannelController.to(channelId: channel.id)
              .jumpToMessage(messageId);
        }
        GlobalState.updateDefaultSelectedChannel(channel.guildId, channel.id);
        break;
      case ChatChannelType.guildVoice:
        final GuildTarget gt =
            ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
        if (gt.userPending && !channel.pendingUserAccess) {
          GlobalState.selectedChannel.value = null;
          if (notify) notifyListeners();
          return result;
        } else {
          AudioRoomController.to(channel.id);
          HomePage.showAudioRoom(channel.id);
        }

        break;
      case ChatChannelType.guildVideo:
        final GuildTarget gt =
            ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
        if (gt.userPending && !channel.pendingUserAccess) {
          GlobalState.selectedChannel.value = null;
          if (notify) notifyListeners();
          return result;
        } else {
          await HomeScaffoldController.to.gotoWindow(0);
          VideoRoomController c;
          try {
            c = Get.find<VideoRoomController>(tag: channel.id);
          } catch (e, s) {
            logger.severe("VideoRoomController tag ${channel.id} error", e, s);
          }
          if (c != null) {
            if (c.isJoining()) return;
            Dock.hide();
            await Get.to(() => VideoRoomHomePage(channel.id, channel.name));
          } else {
            await VideoRoomController.to(channel.id).joinVideoRoom();
            GlobalState.mediaChannel.value = Tuple2(this, channel);
            Dock.hide();
            await Get.to(() => VideoRoomHomePage(channel.id, channel.name));
          }
          Dock.noUpdateDock = false;
          Dock.updateDock();

          // HomePage.showVideoRoom(channel.id);
        }
        break;
      case ChatChannelType.guildCategory:
        break;
      case ChatChannelType.guildLink:
        unawaited(pushLinkPage(channel));
        break;
      case ChatChannelType.guildCircleTopic:
        final lastMessageId = Db.lastMessageIdBox.get(channel.id);
        if (lastMessageId != null) {
          final msg = MessageEntity<MessageContentEntity>(
              null, channel.id, null, channel.guildId, null, EmptyEntity(),
              messageId: lastMessageId, localStatus: MessageLocalStatus.normal);
          unawaited(ChannelUtil.instance.setUnreadAndSync(msg));
        }
        unawaited(Routes.pushCircleMainPage(context, channel.guildId, '',
            topicId: channel.id));
        break;
      default:
        break;
    }

    // if (type != ChatChannelType.dm) {
    //   /// 选择频道埋点
    //   DLogManager.getInstance().customEvent(
    //       actionEventId: 'click_enter_chatid',
    //       actionEventSubId: channel.id ?? '',
    //       actionEventSubParam: '1',
    //       pageId: 'page_chitchat_chat',
    //       extJson: {"guild_id": channel.guildId});
    // }
    // 修复web上拉起At列表输入框会失去焦点
    // if (kIsWeb) {
    //   FocusScope.of(Get.context).requestFocus(FocusNode());
    // }
    if (notify) notifyListeners();
    return result;
  }

  static Future pushLinkPage(ChatChannel channel) async {
    final linkBean = LinkBean.fromStringLink(channel.link);
    switch (linkBean.runtimeType) {
      case UrlBean:
        final bean = linkBean as UrlBean;
        unawaited(LinkHandlerPreset.inApp.handle(bean.path));
        break;
      case WxProgramBean:
        final bean = linkBean as WxProgramBean;
        final path = bean.path ?? '';
        final encodePath = Uri.decodeFull(path);
        try {
          return launchWeChatMiniProgram(username: bean.appId, path: encodePath)
              .then((value) {
            if (!value) showToast('小程序打开失败'.tr);
          });
        } catch (e) {
          logger.info('打开小程序失败:$e');
        }
        break;
    }
  }

  void addChannel(ChatChannel channel, {bool notify = false}) {
    throw Exception("<$runtimeType> target does not support [addChannel]");
  }

  Future removeChannel(ChatChannel channel) async {
    final channelIdx = Db.channelBox.values
        .toList()
        .indexWhere((element) => element.id == channel.id);
    if (channelIdx >= 0) await Db.channelBox.deleteAt(channelIdx);
    await ChatTable.clearChatHistory(channel.id);

    ///删除频道时，同步删除Box中相关的消息ID
    Db.deleteChannelImBox(channel.id);
  }

  Future removeChannelById(String id) {
    throw Exception(
        "<$runtimeType> target does not support [removeChannelById]");
  }

  void selectDefaultTextChannel();

  ChatChannel get defaultChannel;

  ChatChannel getChannel(String channelId);
}

class GuildTarget extends BaseChatTarget {
  String id; // ignore: overridden_fields, annotate_overrides
  String ownerId;
  String icon;
  String authenticate;
  String banner;
  num memberCount;
  num guildPushThreshold;
  bool circleAvailable;
  final List<ChatChannel> channels;
  List<String> channelOrder;
  String systemChannelId;
  int systemChannelFlags;
  final ValueNotifier<int> _numUnread = ValueNotifier(0);
  bool hasLiveChannel;
  ValueNotifier<String> _bannerNotifier;
  ValueNotifier<String> _iconNotifier;
  StreamSubscription unreadSubscription;
  Set<String> _channelIds = {};

  List<String> receiveBots;
  List<String> featureList;
  bool userPending;
  bool isWelcomeOn;
  List<String> welcome; //欢迎页面相关的频道

  ///圈子设置，包括：名称、icon，描述，channelId 等
  Map<String, dynamic> circleData;

  /// - 用户在本服务器的禁言截止时间戳
  int noSay;

  /// 封禁状态
  Rx<BanType> bannedLevel;

  /// 服务器是否被封禁
  bool get isBan => bannedLevel.value == BanType.frozen;

  /// 服务器是否被解散
  bool get isDissolve => bannedLevel.value == BanType.dissolve;

  /// - 虚拟社区开关: false 关闭-默认值; true 打开
  bool virtualDisplay = false;

  /// - 虚拟社区启动参数: [virtualDisplay]为true时有值
  /// 内容为key1=value1&key2=value2格式数据
  String virtualParameters;

  /// 初始化 GuildTarget，把它作为服务器使用，会进行一些复杂的初始化操作
  GuildTarget.init({
    this.id,
    this.ownerId,
    String name,
    this.icon,
    this.authenticate,
    this.banner,
    this.memberCount = 0,
    this.guildPushThreshold = 0,
    this.circleAvailable = false,
    this.channels = const [],
    this.systemChannelFlags = 0,
    this.systemChannelId,
    this.channelOrder,
    this.receiveBots = const [],
    this.featureList = const [],
    this.userPending = false,
    this.isWelcomeOn = false,
    this.hasLiveChannel = false,
    this.welcome = const [],
    this.circleData,
    this.noSay,
    this.bannedLevel,
    this.virtualDisplay = false,
    this.virtualParameters,
  }) : super(id, name) {
    userPending ??= false;
    _channelIds = channelOrder?.toSet() ?? {};
    unreadSubscription = Db.numUnrealOfChannelBox.watch().listen((event) {
      final String channelId = event.key;
      if (!_channelIds.contains(channelId)) return;
      traverseChannelsTask();
    });
    _bannerNotifier = ValueNotifier(banner ?? '');
    _iconNotifier = ValueNotifier(icon ?? '');
    // 创建新服务器对象时需要映射一个直播状态监听对象
    LiveStatusManager.instance.addNotifier(id);
    traverseChannelsTask();
  }

  /// 初始化 GuildTarget，但是只是把它作为结构体使用，不会进行一些复杂的初始化操作
  GuildTarget.tmp({
    this.id,
    String name,
    this.icon,
  })  : channels = null,
        receiveBots = null,
        super(id, name);

  void disposeSubscriptions() {
    unreadSubscription?.cancel();
  }

  @override
  void dispose() {
    unreadSubscription.cancel();
    bannedLevel.close();
    super.dispose();
  }

  @override
  void addChannel(
    ChatChannel channel, {
    bool notify = false,
    List<PermissionOverwrite> initPermissions,
  }) {
    if (channels == null) return;

    if (channel.type == ChatChannelType.guildLive) {
      hasLiveChannel = true;
    }
    _channelIds.add(channel.id);

    Db.numUnrealOfChannelBox
        .listenable(keys: [channel.id]).addListener(traverseChannelsTask);

    if (channels.indexWhere((element) => element.id == channel.id) != -1)
      return;
    channels.add(channel);
    PermissionModel.initChannelPermission(
        channel.guildId, channel.id, initPermissions);
    sortChannels();
    if (notify) notifyListeners();
  }

  //
  void addReceiveBot(String botId) {
    final set = receiveBots?.toSet() ?? <dynamic>{};
    set.add(botId);
    receiveBots = set.toList();
  }

  void removeReceiveBot(String botId) {
    final set = receiveBots.toSet();
    set.remove(botId);
    receiveBots = set.toList();
  }

  // 删除频道
  @override
  Future removeChannel(ChatChannel channel,
      {String operateId, bool fromWs = false}) async {
    if (channel.type == ChatChannelType.guildLive) hasLiveChannel = false;
    _channelIds.remove(channel.id);

    final gt =
        ChatTargetsModel.instance.getChatTarget(channel.guildId) as GuildTarget;
    final newChannelOrder = [...gt.channelOrder]..remove(channel.id);
    if (!fromWs)
      await ChannelApi.removeChannel(
          channel.guildId, Global.user.id, channel.id, newChannelOrder);
    channels.remove(channel);
    welcome?.removeWhere((element) => element == channel.id);

    if (channel.type != ChatChannelType.guildCategory) traverseChannelsTask();

    channelOrder = newChannelOrder;
    updateWhenRemoveChannel(channel);
    notifyListeners();
    await super.removeChannel(channel);
    // 当前被选中则切换默认频道
    if (GlobalState.selectedChannel.value == null) return;
    if (GlobalState.selectedChannel.value?.id == channel.id) {
      if (operateId != null && Global.user.id != operateId) {
        final UserInfo user = await UserInfo.get(operateId);
        final String content = '%s 已被 %s 删除!'
            .trArgs([GlobalState.selectedChannel.value?.name, user.nickname]);
        await showConfirmDialog(
          showCancelButton: false,
          confirmText: '我知道了'.tr,
          title: '通知'.tr,
          content: content,
        );
      }
      GlobalState.updateDefaultSelectedChannel(channel.guildId, null);
      if ([1, 2].contains(HomeScaffoldController.to.windowIndex.value)) {
        unawaited(HomeScaffoldController.to.gotoWindow(1));
      }
      if (![ChatChannelType.guildVoice, ChatChannelType.guildVideo]
          .contains(GlobalState.selectedChannel.value?.type)) {
        selectDefaultTextChannel();
      } else {
        GlobalState.hangUp();
      }
    }
  }

  @override
  Future removeChannelById(String id,
      {String operateId, bool fromWs = false}) async {
    for (final channel in channels) {
      if (channel.id == id) {
        if (channel.type == ChatChannelType.guildLive) {
          hasLiveChannel = false;
        }
        if (channel.type == ChatChannelType.guildCategory) {
          removeChannelCate(channel);
        } else {
          await removeChannel(channel, operateId: operateId, fromWs: fromWs);
        }
        return;
      }
    }
  }

  @override
  ChatChannel get defaultChannel {
    final channelId = Db.guildSelectedChannelBox.get(id);
    final gp = PermissionModel.getPermission(id);
    final gt = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    if (channelId != null) {
      for (final channel in channels) {
        if (channel.id == channelId &&
            PermissionUtils.isChannelVisible(gp, channel.id)) {
          return channel;
        }
      }
    }

    /// 第一次进入服务器时,没有缓存进行默认服务器筛选
    /// pendingUserAccess标记该频道用户是否可见
    for (final channel in channels) {
      if (channel.type == ChatChannelType.guildText &&
          PermissionUtils.isChannelVisible(gp, channel.id)) {
        /// 如果是游客状态,并且不可访问,那么就继续找下一个频道继续筛选
        if (gt != null && gt.userPending && !channel.pendingUserAccess) {
          continue;
        }
        return channel;
      }
    }
    return null;
  }

  ///获取有权限的频道列表
  List<String> getHasPermissionChannels() {
    final List<String> list = [];
    final gp = PermissionModel.getPermission(id);
    for (final channel in channelOrder) {
      if (PermissionUtils.isChannelVisible(gp, channel)) list.add(channel);
    }

    return list;
  }

  /// 遍历频道列表处理相关业务逻辑
  /// 1.updateUnread
  /// 2.判断是否有直播频道
  void traverseChannelsTask() {
    int val = 0;
    for (final c in channels) {
      if (c.type == ChatChannelType.guildLive) {
        hasLiveChannel = true;
      }
      // 该频道是否显示参与红点计算逻辑
      final bool isShowChannelMessage = PermissionUtils.isChannelVisible(
          PermissionModel.getPermission(c.guildId), c.id);

      bool isShowGuestMessage = true;

      /// 游客模式,不可访问的频道不参与红点计算逻辑
      if ((userPending ?? false) && !c.pendingUserAccess) {
        isShowGuestMessage = false;
      }

      if (isShowChannelMessage && isShowGuestMessage) {
        val += ChannelUtil.instance.getUnread(c.id);
      }
    }

    numUnread.value = val;
    GlobalState.updateBadge();
  }

  @override
  void selectDefaultTextChannel() {
    setSelectedChannel(defaultChannel, notify: true, gotoChatView: false);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'guild_id': id,
        'owner_id': ownerId,
        'icon': icon,
        'authenticate': authenticate,
        'member_count': memberCount,
        'guild_push_threshold': guildPushThreshold,
        'banner': banner,
        'circle_display': circleAvailable,
        'channel_lists': channelOrder?.join(","),
        'system_channel_id': systemChannelId,
        'system_channel_flags': systemChannelFlags,
        'bot_receive': receiveBots,
        'feature_list': featureList,
        'user_pending': userPending,
        'welcome_switch': isWelcomeOn,
        'welcome': welcome,
        'circle': circleData,
        'no_say': noSay,
        'banned_level': bannedLevel.value.index,
        'virtual_display': virtualDisplay ? 1 : 0,
        'virtual_parameters': virtualParameters,
      };

  // ignore: prefer_constructors_over_static_methods
  static GuildTarget fromJson(Map json) => GuildTarget.init(
        id: json['guild_id'].toString(),
        ownerId: json['owner_id'].toString(),
        name: json['name'].toString(),
        authenticate: json['authenticate']?.toString(),
        banner: json['banner'].toString(),
        memberCount: num.tryParse(json['member_count'].toString()) ?? 0,
        guildPushThreshold:
            num.tryParse(json['guild_push_threshold'].toString()) ?? 0,
        icon: json['icon'].toString(),
        circleAvailable: json['circle_display']?.toString() == 'true',
        channels: (json['channels'] != null && json['channels'] is List)
            ? (json['channels'] as List)
                ?.map((e) => e == null
                    ? null
                    : ChatChannel.fromJson(e as Map<String, dynamic>))
                ?.toList()
            : <ChatChannel>[],
        systemChannelFlags:
            num.tryParse(json['system_channel_flags'].toString())?.toInt() ?? 0,
        systemChannelId: json['system_channel_id'].toString(),
        channelOrder:
            (json['channel_lists'] != null && json['channel_lists'] is List)
                ? ((json['channel_lists'] as List)
                        .map((e) => e.toString())
                        ?.toList() ??
                    [])
                : [],
        receiveBots:
            (json['bot_receive'] != null && json['bot_receive'] is List)
                ? ((json['bot_receive'] as List)
                        .map((e) => e.toString())
                        ?.toList() ??
                    [])
                : [],
        featureList:
            (json['feature_list'] as List)?.map((e) => e as String)?.toList() ??
                [],
        userPending: json['user_pending'] as bool,
        isWelcomeOn: safeBoolFromJson(json['welcome_switch'], false),
        welcome: safeStringListFromJson(json['welcome'], <String>[]),
        circleData: (json['circle'] != null && json['circle'] is Map)
            ? Map<String, dynamic>.from(json['circle'])
            : null,
        noSay: json['no_say'] ?? 0,
        bannedLevel:
            Rx<BanType>(BanTypeExtension.fromInt(json['banned_level'] ?? 0)),
        virtualDisplay: json['virtual_display'] == 1,
        virtualParameters: json['virtual_parameters']?.toString(),
      );

  @override
  ChatChannel getChannel(String channelId) {
    final channel = channels.firstWhere((element) => element.id == channelId,
        orElse: () => null);
    if (channel != null) return channel;
    return null;
  }

  void removeChannelCate(ChatChannel channel) {
    // 删除频道分类需要把分类下的频道移除到无分类的频道的最后面
    final GuildTarget gt =
        ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    final newChannels = List<ChatChannel>.from(gt.channels); //拷贝
    final changedChannels =
        newChannels.where((element) => element.parentId == channel.id).toList();
    newChannels.removeWhere((element) =>
        changedChannels.contains(element) || element.id == channel.id);
    // 寻找最后一个无分类频道的index
    final index = gt.channels.lastIndexWhere((element) =>
        (element.parentId == '' || element.parentId == null) &&
        element.type != ChatChannelType.guildCategory);
    newChannels.insertAll(index == -1 ? 0 : (index + 1), changedChannels);
    final channelOrder = newChannels.map((e) => e.id).toList();
    gt.channels
      ..clear()
      ..addAll(newChannels);
    gt.channelOrder = channelOrder;
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    gt.notifyListeners();
  }

  void sortChannels() {
    final channelMap = <String, ChatChannel>{};
    for (final c in channels) {
      channelMap[c.id] = c;
      if (!channelOrder.contains(c.id)) {
        channelOrder.insert(0, c.id);
      }
    }
    final List<ChatChannel> orderedChannels = [];
    for (final c in channelOrder) {
      if (channelMap.containsKey(c) &&
          orderedChannels.indexWhere((element) => element.id == c) < 0) {
        orderedChannels.add(channelMap[c]);
      }
    }
    final List<ChatChannel> orderedChannels2 = [];
    // todo： parentId 存在几种情况 0 '' null ，需统一下
    orderedChannels2.addAll(orderedChannels.where((element) =>
        ['0', '', null].contains(element.parentId) &&
        element.type != ChatChannelType.guildCategory));
    final List<ChatChannel> orderedCategories = orderedChannels
        .where((element) => element.type == ChatChannelType.guildCategory)
        .toList();

    for (final c in orderedCategories) {
      if (!orderedChannels2.contains(c)) orderedChannels2.add(c);
      orderedChannels2.addAll(orderedChannels
          .where((element) =>
              element.parentId == c.id &&
              element.type != ChatChannelType.guildCategory)
          .toList());
    }
    channelOrder = orderedChannels2.map((e) => e.id).toList();
    channels
      ..clear()
      ..addAll(orderedChannels2);
  }

  void update({String name, String systemChannelId, int systemChannelFlags}) {
    this.systemChannelId = systemChannelId;
    this.systemChannelFlags = systemChannelFlags;
    notifyListeners();
  }

  ///更新服务器配置
  void updateInfo({
    String name,
    String banner,
    String icon,
    bool isWelcomeOn,
    List<String> welcome,
    List<String> receiveBots,
  }) {
    if (name != null) {
      this.name = name;
      _nameNotifier.value = name;
    }
    if (banner != null) {
      this.banner = banner;
      _bannerNotifier.value = banner;
    }
    if (icon != null) {
      this.icon = icon;
      _iconNotifier.value = icon;
    }

    if (isWelcomeOn != null) {
      this.isWelcomeOn = isWelcomeOn;
    }

    if (welcome != null) {
      this.welcome = welcome;
    }

    if (receiveBots != null) {
      this.receiveBots = receiveBots;
    }

    notifyListeners();
    updateGuildBox();
  }

  void updateChannel(
    String channelId, {
    String name,
    String topic,
    String parentId,
    int userLimit,
    String link,
    bool pendingUserAccess,
    bool active,
  }) {
    final channel = channels.firstWhere((element) => element.id == channelId);
    if (channel != null) {
      channel.name = name ?? channel.name;
      channel.topic = topic ?? channel.topic;
      channel.parentId = parentId ?? channel.parentId;
      channel.userLimit = userLimit ?? channel.userLimit;
      channel.link = link ?? channel.link;
      channel.active = active ?? channel.active;
      channel.parentId = parentId;
      channel.link = link;
      channel.pendingUserAccess =
          pendingUserAccess ?? channel.pendingUserAccess;
    }
    notifyListeners();
  }

  ///ws同步圈子的设置
  void updateCircleData(Map data) {
    if (circleData == null) return;
    if (data.containsKey('name')) circleData['name'] = data['name'];
    if (data.containsKey('icon')) circleData['icon'] = data['icon'];
    if (data.containsKey('description'))
      circleData['description'] = data['description'];
    if (data.containsKey('banner')) circleData['banner'] = data['banner'];
    if (data.containsKey('channel_id'))
      circleData['channel_id'] = data['channel_id'];
    updateGuildBox();
  }

  ///更新服务器本地缓存-guildBox
  Future<void> updateGuildBox() {
    final json = toJson();
    return Db.guildBox.put(id, json);
  }

  //重新刷新方法
  void reload() {
    notifyListeners();
  }

  ///更新圈子开关
  void updateCircleAvailable(bool circleAvailable) {
    if (this.circleAvailable == circleAvailable) {
      return;
    } else {
      this.circleAvailable = circleAvailable;
      updateGuildBox();
    }
  }

  @override
  ValueNotifier<int> get numUnread => _numUnread;

  ValueNotifier<String> get bannerNotifier => _bannerNotifier;

  ValueNotifier<String> get iconNotifier => _iconNotifier;

  // ValueNotifier<GuildLivingStatus> get livingStatus => _livingStatus;

  /// 偶先的 Dispose 后依然使用，因此使用这种方式
  // void tryDispose() {
  //   if (hasListeners) {
  //     Future.delayed(const Duration(milliseconds: 500), tryDispose);
  //   } else {
  //     dispose();
  //   }
  // }
  /// 由于ValueNotifier _listeners无法置空，避免死循环消耗性能，已经在使用的先不dispose
  /// 并且始终延时dispose
  void tryDispose() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!hasListeners) dispose();
    });
  }

  // 获取有查看频道和发言权限的频道
  List<ChatChannel> getViewSendChannels() {
    return (channels ?? []).where((channel) {
      final isTextChannel = channel.type == ChatChannelType.guildText;
      final GuildPermission gp = PermissionModel.getPermission(channel.guildId);
      final hasPermission = PermissionUtils.all(
          gp, [Permission.SEND_MESSAGES, Permission.VIEW_CHANNEL],
          channelId: channel.id);
      return isTextChannel && hasPermission;
    }).toList();
  }
}
