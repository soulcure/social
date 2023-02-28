import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/api/entity/at_me_bean.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/db/cicle_news_table.dart';
import 'package:im/db/db.dart';
import 'package:im/db/message_search_table.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/ws/ws.dart';
import 'package:pedantic/pedantic.dart';

///频道工具类：未读数 和 未读艾特消息
class ChannelUtil {
  static final ChannelUtil instance = ChannelUtil._internal();

  Map<String, Map> _syncReadMap;

  bool isMultiLogin;

  /// * 圈子频道集合(type = guildCircle)
  final Map<String, ChatChannel> _circleChannels = {};

  factory ChannelUtil() {
    return instance;
  }

  ChannelUtil._internal() {
    _syncReadMap = {};
    isMultiLogin = false;
    Ws.instance.on().listen((event) async {
      if (event is UnreadMessage) {
        ///延时刷新未读同步，防止快于接收消息的刷新
        Timer(const Duration(milliseconds: 150), () {
          updateByServer(event);
        });
      } else if (event is OnlineMessage) {
        if (event.online > 1) {
          isMultiLogin = true;
        } else {
          isMultiLogin = false;
        }
        upLastReadSend();
      } else if (event is Connected) {
        _upLastReadSend();
      }
    });
  }

  int getUnread(String channelId) {
    return Db.numUnrealOfChannelBox.get(channelId, defaultValue: 0);
  }

  void setUnread(String channelId, int value) {
    if (value <= 0) {
      Db.firstMessageIdBox.delete(channelId);
      clearAtNum(channelId);
      clearHotChatFriend(channelId);
    }
    if (getUnread(channelId) == value) return;
    Db.numUnrealOfChannelBox.put(channelId, value);
  }

  ///递增：频道未读数
  bool increaseUnread(MessageEntity messageEntity, {int value = 1}) {
    if (messageEntity == null) return false;
    final String channelId = messageEntity.channelId;
    final String messageId = messageEntity.messageId;
    if (channelId == null) return false;

    final String readId = Db.readMessageIdBox.get(channelId);

    if (readId != null &&
        readId.isNotEmpty &&
        readId.compareTo(messageId) >= 0) {
      return false;
    }

    final unread = getUnread(channelId) + value;
    setUnread(channelId, unread);
    return true;
  }

  ///设置频道未读数,以及多端同步已读ID
  Future<void> setUnreadAndSync(MessageEntity messageEntity,
      {bool sync = false, bool upNow = false, int unread = 0}) async {
    if (messageEntity == null) return;
    final String channelId = messageEntity.channelId;
    if (channelId == null) return;
    debugPrint('getChat setUnread: $unread - $sync - $isMultiLogin');
    setUnread(channelId, unread);

    if (sync) {
      if (upNow) {
        await _upLastReadImmediately(messageEntity); //立即上报
      } else {
        if (isMultiLogin) {
          ///多端登录情况
          await _multiLoginSync(messageEntity, unread: unread);
        } else {
          ///一端登录情况
          _upLastReadCache(messageEntity); //缓存延时上报
        }
      }
    }
  }

  void upLastReadSend({bool delay = false}) {
    if (delay) {
      Timer(const Duration(seconds: 1), _upLastReadSend);
    } else {
      _upLastReadSend();
    }
  }

  ///向服务器同步readId
  void _upLastReadSend() {
    if (_syncReadMap.isNotEmpty) {
      _syncReadMap.forEach((key, value) async {
        final String channelId = value["channel_id"];
        final readId = value["read_id"];

        final saveReadId = Db.readMessageIdBox.get(channelId);
        if (readId != null &&
            saveReadId != null &&
            readId.compareTo(saveReadId) <= 0) return;

        try {
          await Ws.instance.send(value);
          await Db.readMessageIdBox.put(channelId, readId);
        } catch (e, s) {
          logger.info(e.toString(), s);
        }
      });
    }

    _syncReadMap.clear();
  }

  void _saveDataToMap(String channelId, Map map) {
    _syncReadMap[channelId] = map;
  }

  void _upLastReadCache(MessageEntity messageEntity) {
    final String channelId = messageEntity.channelId;
    final readId = messageEntity.messageId;
    final guildId = messageEntity.guildId;
    if (channelId == null) return;

    final Map data = {
      "action": MessageAction.upLastRead,
      "channel_id": channelId,
      "read_id": readId,
    };

    if (messageEntity.channelType != null &&
        messageEntity.channelType != ChatChannelType.dm) {
      data["guild_id"] = guildId;
    }

    _saveDataToMap(channelId, data);
  }

  Future<void> _upLastReadImmediately(MessageEntity messageEntity) async {
    final String channelId = messageEntity.channelId;
    final readId = messageEntity.messageId;
    final guildId = messageEntity.guildId;

    final saveReadId = Db.readMessageIdBox.get(channelId);
    if (readId != null &&
        saveReadId != null &&
        readId.compareTo(saveReadId) <= 0) return;

    await Db.readMessageIdBox.put(channelId, readId); //syncRead upLastRead互斥

    final Map data = {
      "action": MessageAction.upLastRead,
      "channel_id": channelId,
      "read_id": readId,
    };

    if (messageEntity.channelType != null &&
        messageEntity.channelType != ChatChannelType.dm &&
        messageEntity.channelType != ChatChannelType.group_dm) {
      data["guild_id"] = guildId;
    }

    try {
      await Ws.instance.send(data);
    } on WsUnestablishedException {
      unawaited(Db.readMessageIdBox.delete(channelId));
    } catch (e, s) {
      logger.info(e.toString(), s);
    }

    data["action"] = MessageAction.upLastRead;
    _saveDataToMap(channelId, data);
  }

  Future<void> _multiLoginSync(MessageEntity messageEntity,
      {int unread = 0}) async {
    final String channelId = messageEntity.channelId;
    final readId = messageEntity.messageId;
    final guildId = messageEntity.guildId;

    if (channelId == null) return;

    final saveReadId = Db.readMessageIdBox.get(channelId);
    if (readId != null &&
        saveReadId != null &&
        readId.compareTo(saveReadId) <= 0) return;

    await Db.readMessageIdBox.put(channelId, readId); //syncRead upLastRead互斥

    final Map data = {
      "action": MessageAction.syncRead,
      "channel_id": channelId,
      "read_id": readId,
      "un_read": unread,
    };

    if (messageEntity.channelType != null &&
        messageEntity.channelType != ChatChannelType.dm &&
        messageEntity.channelType != ChatChannelType.group_dm) {
      data["guild_id"] = guildId;
    }

    try {
      await Ws.instance.send(data);
    } on WsUnestablishedException {
      unawaited(Db.readMessageIdBox.delete(channelId));
    } catch (e, s) {
      logger.info(e.toString(), s);
    }

    data["action"] = MessageAction.upLastRead;
    _saveDataToMap(channelId, data);
  }

  ///清除指定messageId 之前的未读数
  void removeUnreadBeforeMessageId(String channelId, String messageId) {
    int unreadNum = getUnread(channelId);
    if (unreadNum > 0) {
      final saveReadId = Db.readMessageIdBox.get(channelId);
      if (saveReadId != null && saveReadId.compareTo(messageId) < 0) {
        unreadNum--;
        setUnread(channelId, unreadNum);
      }
    }
  }

  Widget listen2(List<String> channels, Widget Function() builder) {
    return ValueListenableBuilder(
        valueListenable: Db.numUnrealOfChannelBox.listenable(keys: channels),
        builder: (_, __, ___) => builder());
  }

  static void increaseHotChatFriend(
      String channelId, String userId, int deadLine) {
    final list = Db.hotChatFriendOfChannelBox.get(channelId) ?? [];
    list.removeWhere((element) =>
        element['deadLine'] < DateTime.now().millisecondsSinceEpoch);
    final existUser = list.firstWhere((element) => element['userId'] == userId,
        orElse: () => null);
    if (existUser != null) {
      existUser['deadLine'] = deadLine;
      Db.hotChatFriendOfChannelBox.put(channelId, list);
    } else {
      final hotChatInfo = {"userId": userId, "deadLine": deadLine};
      list.insert(0, hotChatInfo);
      if (list.length > 3) list.removeRange(3, list.length);
      Db.hotChatFriendOfChannelBox.put(channelId, list);
    }
  }

  static Widget listen2HotChat(
      List<String> channels, Widget Function() builder) {
    return ValueListenableBuilder(
        valueListenable:
            Db.hotChatFriendOfChannelBox.listenable(keys: channels),
        builder: (_, __, ___) => builder());
  }

  static void clearHotChatFriend(String channelId) {
    Db.hotChatFriendOfChannelBox.put(channelId, []);
  }

  ///更新：未读艾特数量
  void setAtMessageBean(String channelId, AtMeBean bean) {
    final oldBean = getAtMessageBean(channelId);
    if (oldBean.num == 0 && oldBean.num == bean.num) return;
    Db.numAtOfChannelBox.put(channelId, bean);
  }

  ///获取：未读艾特数量
  AtMeBean getAtMessageBean(String channelId) {
    return Db.numAtOfChannelBox.get(channelId) ??
        AtMeBean(channelId: channelId, messageIdMap: {});
  }

  static List<String> getHotChatFriendList(String channelId) {
    final list = Db.hotChatFriendOfChannelBox.get(channelId) ?? [];
    list.removeWhere((element) =>
        element['deadLine'] < DateTime.now().millisecondsSinceEpoch);
    final List<String> userList = [];
    for (final userInfo in list) {
      userList.add(userInfo['userId']);
    }
    return userList;
  }

  ///递增+1：未读艾特数量
  void increaseAtMessageNum(String channelId, String messageId) {
    final AtMeBean bean = getAtMessageBean(channelId);
    bean.add(messageId);
    Db.numAtOfChannelBox.put(channelId, bean);
  }

  ///递减-1：未读艾特数量
  void decreaseAtMessageNum(String channelId, String messageId) {
    final AtMeBean bean = getAtMessageBean(channelId);
    if (!bean.messageIdMap.containsKey(messageId)) return;
    bean.remove(messageId);
    Db.numAtOfChannelBox.put(channelId, bean);
  }

  ///监听：未读艾特数量
  Widget listenAtNum(String channelId, Widget Function() builder) {
    return ValueListenableBuilder(
        valueListenable: Db.numAtOfChannelBox.listenable(keys: [channelId]),
        builder: (_, __, ___) => builder());
  }

  ///清空：未读艾特记录
  void clearAtNum(String channelId) {
    final AtMeBean bean = getAtMessageBean(channelId);
    if (bean.num <= 0) return;
    bean.clear();
    Db.numAtOfChannelBox.put(channelId, bean);
  }

  ///更新 firstMessageIdBox
  void updateFirstMessageIdBox(MessageEntity message,
      {bool forceUpdate = false}) {
    if (MessageEntity.messageIsNotVisible(message)) return;
    if (forceUpdate || !Db.firstMessageIdBox.containsKey(message.channelId)) {
      // debugPrint(
      //     'getChat -> updateFirst 1: ${message.channelId} -  ${message.messageId}');
      Db.firstMessageIdBox.put(message.channelId, message.messageIdBigInt);
    } else {
      final BigInt firstId = Db.firstMessageIdBox.get(message.channelId);
      if (message.messageIdBigInt < firstId) {
        // debugPrint(
        //     'getChat -> updateFirst 2: ${message.channelId} -  ${message.messageId}');
        Db.firstMessageIdBox.put(message.channelId, message.messageIdBigInt);
      }
    }
  }

  ///更新 lastMessageIdBox
  void updateLastMessageIdBoxById(String channelId, String messageId,
      {bool forceUpdate = false, bool privateMsg = false}) {
    if (channelId == null || messageId == null) return;

    ///私信消息 不入Db.lastMessageIdBox
    if (privateMsg) {
      if (messageId != null && messageId.isNotEmpty) {
        final String updateId =
            (BigInt.parse(messageId) + BigInt.from(1)).toString();
        Db.lastMessageIdBox.put(channelId, updateId);
      }
      return;
    }

    final messageList = InMemoryDb.getMessageList(channelId);

    /// forceUpdate 为true，或者 remoteSynchronized 为true时，才能更新lastId
    if (forceUpdate || messageList.remoteSynchronized) {
      Db.lastMessageIdBox.put(channelId, messageId);
      // debugPrint('getChat --> updateLastId 1 : $channelId - $messageId');
    } else if (!messageList.remoteSynchronized) {
      ///remoteSynchronized为false时，赋值给 notSyncMessageId
      messageList.notSyncMessageId = messageId;
      // debugPrint('getChat --> updateLastId 2 : $channelId - $messageId');
    }
  }

  ///撤回消息时，更新艾特数
  Future<void> recallAtMessage(String channelId, String messageId) async {
    final MessageEntity message = await ChatTable.getMessage(messageId);
    if (message == null) return;
    decreaseAtMessageNum(channelId, messageId);
  }

  void updateByServer(UnreadMessage unreadMessage) {
    final String channelId = unreadMessage.channelId;
    //final String guildId = unreadMessage.guildId;
    final String readId = unreadMessage.readId;
    final int unRead = unreadMessage.unRead;

    final saveReadId = Db.readMessageIdBox.get(channelId);
    if (readId != null &&
        saveReadId != null &&
        readId.compareTo(saveReadId) <= 0) return;

    if (getUnread(channelId) == unRead) return;

    setUnread(channelId, unRead);
    Db.readMessageIdBox.put(channelId, readId);

    clearAtNum(channelId);
  }

  ///更新最后一条完整消息ID
  void updateLastCompleteMessageIdBox(String channelId, BigInt messageId) {
    if (channelId == null || messageId == null) return;
    final BigInt id = Db.lastCompleteMessageIdBox.get(channelId);
    if (id == null || id < messageId) {
      Db.lastCompleteMessageIdBox.put(channelId, messageId);
    }
  }

  ///更新最后一条可见消息ID
  void updateLastVisibleMessageIdBox(String channelId, BigInt messageId) {
    if (channelId == null || messageId == null) return;
    final BigInt id = Db.lastVisibleMessageIdBox.get(channelId);
    if (id == null || id < messageId) {
      // debugPrint('getChat lastVisible: $messageId');
      Db.lastVisibleMessageIdBox.put(channelId, messageId);
    }
  }

  ///兼容旧版：保存最后一条可见消息ID
  Future<void> initLastVisibleMessageIdBox(String channelId) async {
    if (channelId == null) return;

    ///先判断是否要初始化：没有lastID，返回
    if (!Db.lastMessageIdBox.containsKey(channelId)) return;
    if (!Db.lastVisibleMessageIdBox.containsKey(channelId)) {
      final lastId = await MessageSearchTable.queryLastId(channelId, null);
      // debugPrint('getChat init lastVisible: $lastId');
      if (lastId == null) return;
      unawaited(Db.lastVisibleMessageIdBox.put(channelId, lastId));
    }
  }

  ///增加最近艾特过的用户id
  void addGuildAtUserId(String guildId, List<String> userIds) {
    if (guildId == null || userIds == null || userIds.isEmpty) return;
    //删除不存在的用户ID
    userIds.removeWhere((e) => Db.userInfoBox.get(e) == null);
    final userIdSet = userIds.toSet();
    final list = getGuildAtUserIdList(guildId);
    //删除重复的userId
    list.removeWhere(userIdSet.contains);
    //最后再新增
    list.insertAll(0, userIds);
    //只保留最新的5个
    if (list.length > 5) list.removeRange(5, list.length);
    // debugPrint('getChat insertGuildAtUser end: $guildId - ${list.join(',')}');
    Db.guildRecentAtBox?.put(guildId, list);
  }

  ///获取最近艾特过的用户id列表
  List<String> getGuildAtUserIdList(String key) {
    if (key == null) return <String>[];
    final List<String> list = Db.guildRecentAtBox?.get(key)?.map((e) {
      return e.toString();
    })?.toList();
    return list ?? <String>[];
  }

  /// * 清零圈子频道的未读数和上报readId
  /// * last: 最后一条圈子消息，用于上报已读ID
  Future<void> clearUnreadById(String postChannelId,
      {MessageEntity last, bool upNow = true}) async {
    if (last != null) {
      await setUnreadAndSync(last, sync: true, upNow: upNow);
    } else {
      // 如果last为空，也清零未读数
      setUnread(postChannelId, 0);
    }
    await CircleNewsTable.batchDelete(postChannelId);
  }

  /// * 重新设置圈子频道的未读数
  /// * last: 最后一条圈子消息，用于上报已读ID
  Future<void> resetUnreadById(String postChannelId,
      {MessageEntity last}) async {
    final obj = await CircleNewsTable.queryCircleNews(postChannelId);
    //设置频道的未读数
    final num = obj.newsMap.length;
    if (last != null)
      unawaited(
          ChannelUtil.instance.setUnreadAndSync(last, sync: true, unread: num));
    else
      ChannelUtil.instance.setUnread(postChannelId, num);

    //设置频道的艾特数
    final atBean = AtMeBean(channelId: postChannelId);
    if (num >= 0 && obj.hasAt) {
      obj.atMap.keys.forEach((e) {
        atBean.add(e.toString());
      });
    }
    ChannelUtil.instance.setAtMessageBean(postChannelId, atBean);
  }

  ///检查用户是否还在服务器
  Future<bool> checkUserExist(
      {String guildId, String userId, bool showErrorToast = false}) async {
    if (guildId == null) return true;
    final res = await GuildApi.checkGuildMembers(
        guildId: guildId, userIds: [userId], showErrorToast: showErrorToast);
    List result;
    if (res != null) result = res['user_ids'];
    if (result != null) {
      return result.toSet().contains(userId);
    } else {
      return true;
    }
  }

  ///更新频道的名称和图标
  bool updateChannel(ChatChannel channel, {String name, String icon}) {
    bool isUpdate = false;
    if (channel == null) return isUpdate;
    if (name.hasValue && name != channel.name) {
      channel.name = name;
      isUpdate = true;
    }
    if (icon.hasValue && icon != channel.icon) {
      channel.icon = icon;
      isUpdate = true;
    }
    if (isUpdate) unawaited(Db.channelBox.put(channel.id, channel));
    return isUpdate;
  }

  /// * 获取Channel频道：优先channelBox,再内存
  /// * 圈子频道没存box
  ChatChannel getChannel(String id) {
    return Db.channelBox.get(id) ?? _circleChannels[id];
  }

  /// * 保存圈子频道到内存
  void putCircleChannelInMemory(ChatChannel channel) {
    if (channel.id.noValue) return;
    _circleChannels[channel.id] = channel;
  }
}
