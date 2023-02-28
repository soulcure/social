import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/channel_api.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/app/modules/friend_apply_page/controllers/friend_apply_page_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/db/bean/dm_last_message_desc.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/search/model/search_model.dart';
import 'package:im/routes.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/utils/string_filter_utils.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:pedantic/pedantic.dart';

class LastMessage {
  final String msg;
  final String time;

  const LastMessage({this.msg, this.time});
}

class Unread {
  int normalUnread;
  int muteUnread;

  Unread(this.normalUnread, this.muteUnread);
}

///消息列表包含的频道类型
Set<ChatChannelType> dmTypeSet = {
  ChatChannelType.dm,
  ChatChannelType.group_dm,
  ChatChannelType.circlePostNews
};

class DirectMessageController extends GetxController {
  static DirectMessageController get to => Get.find();
  static ValueNotifier<int> numUnread = ValueNotifier(0);
  static ValueNotifier<Unread> numUnreadMute = ValueNotifier(Unread(0, 0));

  static bool get directChatPageVisible =>
      Get.currentRoute == directChatViewRoute;

  final List<ChatChannel> _channels = [];
  List<String> _ids = [];

  ///dmList接口返回的有更新的频道列表：离线消息接口notPull的参数，不是全量
  List<ChatChannel> updatedChannels = [];

  String _cacheSearchInput = '';

  ///是否为搜索进入dm channel
  bool _isSearchEntry = false;

  set channels(List<ChatChannel> val) {
    _channels
      ..clear()
      ..addAll(val);
    _channels.sort(sortCompare);
    _ids = _channels.map((e) => e.id).toList();
    _syncFilterChannels();
    update();
  }

  StreamSubscription unreadSubscription;

  final TextEditingController textEditingController = TextEditingController();
  final SearchInputModel searchInputModel = SearchInputModel();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  UnmodifiableListView<ChatChannel> get channels =>
      UnmodifiableListView(_channels);

  /// 私信列表真正显示的是此列表，[_channels]有变更，需调用[_syncFilterChannels]同步更新
  List<ChatChannel> filterChannels = [];

  UnmodifiableListView<ChatChannel> get channelsDm {
    final List<ChatChannel> channels = [];
    for (final ChatChannel item in _channels) {
      if (item.type == ChatChannelType.dm) {
        channels.add(item);
      }
    }
    return UnmodifiableListView(channels);
  }

  UnmodifiableListView<ChatChannel> get channelsGroup {
    final List<ChatChannel> channels = [];
    for (final ChatChannel item in _channels) {
      if (item.type == ChatChannelType.group_dm) {
        channels.add(item);
      }
    }
    return UnmodifiableListView(channels);
  }

  ///单独排序
  void sortList() {
    _channels.sort(sortCompare);
    _ids = _channels.map((e) => e.id).toList();
    _syncFilterChannels(needUpdate: true);
  }

  ///排序规则
  int sortCompare(ChatChannel a, ChatChannel b) {
    if (b.lastMessageId == null || a.lastMessageId == null) return 0;
    if (b.lastMessageId.toInt() == 0 && a.lastMessageId.toInt() == 0) {
      if (b.id != null && a.id != null)
        return BigInt.parse(b.id).compareTo(BigInt.parse(a.id));
    }
    return b.lastMessageId.compareTo(a.lastMessageId);
  }

  ///加载本地消息频道列表
  Future loadLocalData() async {
    final List<ChatChannel> dmList = [];
    Db.channelBox.values.where((e) => dmTypeSet.contains(e.type)).forEach((c) {
      final DmLastMessageDesc lastDesc = Db.dmLastDesc.get(c.id);
      if (lastDesc != null) c.lastMessageId = lastDesc.messageId;
      dmList.add(c);
    });
    channels = dmList;
    debugPrint('getChat dm - local.length: ${dmList.length}');
    updateUnread();
  }

  ///同步服务端的消息频道列表
  Future<void> useRemoteDirectMessageData(Set<String> localChannelIds) async {
    debugPrint('getChat dm - useRemote');

    ///本地缓存的消息列表的频道id List
    final List<String> localDmIdList = Db.channelBox.values
        .where((e) => dmTypeSet.contains(e.type))
        .map((e) => e.id)
        .toList();

    ///上次dmList2接口时间
    final int lastDmList2Time =
        Db.userConfigBox.get(UserConfig.dmList2Time, defaultValue: 0);

    ///服务端返回的有更新的频道(增量)：包括增加、删除、有新消息
    final returnTuple2 = await GuildApi.getDmList(userId: Global.user.id);
    final structList = returnTuple2.item1;
    updatedChannels.clear();

    if (structList.isEmpty) {
      addLastUpdateChannels(dmList2Time: returnTuple2.item2);
      localChannelIds.removeAll(localDmIdList);
      return;
    }

    final List<ChatChannel> channels = [];
    List<ChatChannel> updateChannelList = [];
    final Map<String, BigInt> lastIdMap = {};

    final len = structList.length;
    for (int i = len - 1; i >= 0; i--) {
      final s = structList[i];
      // print(
      //     'getChat dm - item i:$i - name:${s.name}, cId:${s.channelId}, gId:${s.guildId}, recipientId:${s.recipientId},'
      //     ' status:${s.status}, top:${s.top}, type:${s.type}');
      localDmIdList.remove(s.channelId);
      if (s.status == 1 || s.channelId == null) {
        ///status为1，表示该频道已被关闭
        final DirectMessageStruct removeChannel = structList.removeAt(i);
        unawaited(Db.channelBox.delete(removeChannel.channelId));
        unawaited(Db.dmLastDesc.delete(removeChannel.channelId));
      } else {
        ///status为0，频道打开，更新或新增的
        localChannelIds.remove(s.channelId);
        final ChatChannelType type = chatChannelTypeFromJson(s.type);
        ChatChannel channel;
        final name = s.name?.replaceAll('\n', '');
        if (type == ChatChannelType.group_dm) {
          channel = ChatChannel(
            id: s.channelId,
            guildId: s.guildId,
            type: type,
            name: name,
            icon: s.icon,
            icons: s.userIcons,
          );
        } else if (type == ChatChannelType.dm) {
          channel = ChatChannel(
            id: s.channelId,
            guildId: s.guildId,
            type: type,
            name: name,
            icon: s.icon,
            recipientId: s.recipientId,
          );
        } else if (type == ChatChannelType.circlePostNews) {
          channel = ChatChannel(
            id: s.channelId,
            type: type,
            name: name,
            icon: s.icon,
            recipientId: s.recipientId,
            recipientGuildId: s.guildId,
          );
        }

        ///这里是兼容代码：不识别的频道，不能加入和保存
        if (channel == null) {
          structList.removeAt(i);
          continue;
        }
        unawaited(Db.channelBox.put(channel.id, channel));
        final last = Db.dmLastDesc.get(channel.id);
        if (last != null) channel.lastMessageId = last.messageId;

        ///频道的lastMessageId,可以解析出消息时间
        final lastMessageId = Db.lastMessageIdBox.get(channel.id);
        if (lastMessageId != null)
          lastIdMap[channel.id] = BigInt.parse(lastMessageId);

        channels.add(channel);
      }
    }

    ///本地私信频道最大lastId的解析出的时间
    int maxMessageIdTime;
    if (lastDmList2Time > 0 && lastIdMap.isNotEmpty) {
      final lastIdList = lastIdMap.values.toList();
      lastIdList.sort((a, b) => b.compareTo(a));
      maxMessageIdTime = ChatTable.getTimeByMessageId(lastIdList.first) ~/ 1000;

      ///300秒是容错时间
      maxMessageIdTime -= 300;
    }

    ///得到 updateChannelList
    structList.forEach((struct) {
      final channel = Db.channelBox.get(struct.channelId);
      if (lastDmList2Time == 0 ||
          lastIdMap.isEmpty ||
          !lastIdMap.containsKey(struct.channelId)) {
        updateChannelList.add(channel);
        return;
      }

      ///比较服务端返回的 top 和 maxMessageIdTime
      ///如果：top >= maxMessageIdTime，就加入updatedChannels
      if (maxMessageIdTime != null && struct.top != null) {
        if (struct.top >= maxMessageIdTime) {
          updateChannelList.add(channel);
        }
      } else {
        updateChannelList.add(channel);
      }
    });
    print('getChat dm - update.length:${updateChannelList.length}');
    if (updateChannelList.isNotEmpty)
      updateChannelList = updateChannelList.reversed.toList();
    updatedChannels = updateChannelList;

    ///剩下的是: 没有更新的频道
    localDmIdList.forEach((channelId) {
      localChannelIds.remove(channelId);
      final channel = Db.channelBox.get(channelId);
      if (channel == null) return;
      channels.add(channel);
      final last = Db.dmLastDesc.get(channel.id);
      if (last != null) channel.lastMessageId = last.messageId;
    });

    print('getChat dm - channels.length:${channels.length}');
    this.channels = channels;
    //这里需要刷新私信列表
    update();

    addLastUpdateChannels(dmList2Time: returnTuple2.item2);
  }

  ///加入上次的待更新频道ID并保存，保存成功后再保存 dmList2Time
  void addLastUpdateChannels({int dmList2Time}) {
    final idsList =
        Db.userConfigBox.get(UserConfig.dmList2ChannelIds) as List<String>;
    final Set<String> idsSet = idsList?.toSet() ?? <String>{};
    print('getChat dm - idsList.length: ${idsList?.length}');
    if (idsSet.isNotEmpty) {
      ///如果上次的待更新频道ID有值，一起加到这次，且去掉重复的ID
      final difIds = updatedChannels.isNotEmpty
          ? idsSet.difference(updatedChannels.map((e) => e.id).toSet())
          : idsSet;
      if (difIds.isNotEmpty) {
        difIds.forEach((e) {
          final c = Db.channelBox.get(e);
          if (c == null) return;
          updatedChannels.insert(0, c);
        });
      }
    }

    List<String> saveList;
    if (updatedChannels.isNotEmpty)
      saveList = updatedChannels.map((e) => e.id).toList();
    saveList ??= <String>[];

    ///本次的待更新频道ID，需要保存
    ///如果某个频道的离线消息处理成功，则清除掉；如果没成功，累积到下次
    Db.userConfigBox.put(UserConfig.dmList2ChannelIds, saveList).then((_) {
      Db.userConfigBox.put(UserConfig.dmList2Time, dmList2Time);
      logger.info(
          'dmList2 dmList2Time: $dmList2Time, update: ${saveList.length}');
    });
  }

  void bringChannelToTop(ChatChannel channel) {
    final index = _channels.indexWhere((element) => element.id == channel.id);
    if (index > -1) {
      _channels.insert(0, _channels.removeAt(index));
    } else {
      _channels.insert(0, channel);
    }
    _ids = _channels.map((e) => e.id).toList();

    _syncFilterChannels();

    update();
  }

  Future<void> joinGroup(String guildId, String channelId, int type,
      String name, String icon) async {
    ChatChannel c = await GuildApi.getGroupInfo(channelId);
    c ??= ChatChannel(
      id: channelId,
      guildId: guildId,
      type: ChatChannelType.values[type],
      name: name,
      icon: icon,
    );
    await Db.channelBox.put(c.id, c);
    bringChannelToTop(c);
  }

  Future<void> notifyDirectMessage(MessageEntity message,
      {bool addUnread = true}) async {
    //if (message.userId == Global.user.id) return;
    //新账号首次被拉入私聊，生成一个空入口
    if (message.content is StartEntity) return;

    ChatChannel channel = channels.firstWhere((e) => e.id == message.channelId,
        orElse: () => null);
    if (channel == null) {
      if (message.channelType == ChatChannelType.dm) {
        channel ??= Db.channelBox.get(message.channelId);
        channel = ChatChannel(
          id: message.channelId,
          recipientId: message.userId,
          type: message.channelType,
        );
        if (addUnread) ChannelUtil.instance.setUnread(channel.id, 1);
      } else if (message.channelType == ChatChannelType.group_dm) {
        channel = await GuildApi.getGroupInfo(message.channelId);
        if (addUnread) ChannelUtil.instance.setUnread(channel.id, 1);
      } else if (message.channelType == ChatChannelType.circlePostNews) {
        final content = message.content as CirclePostNewsEntity;
        channel = ChatChannel(
          id: message.channelId,
          recipientId: content.postId,
          recipientGuildId: message.guildId,
          type: message.channelType,
          icon: content.icon,
          name: content.name?.replaceAll('\n', ''),
        );
        if (addUnread) ChannelUtil.instance.setUnread(channel.id, 1);
      }
      if (channel == null) return;

      await Db.channelBox.put(channel.id, channel);
      bringChannelToTop(channel);
      updateUnread();
    } else {
      if (message.channelType == ChatChannelType.circlePostNews) {
        final content = message.content as CirclePostNewsEntity;
        ChannelUtil.instance
            .updateChannel(channel, name: content?.name, icon: content?.icon);
      }
      bringChannelToTop(channel);
    }
  }

  Future<ChatChannel> createChannel(String userId) async {
    //  已经存在的聊天就不在创建
    var channel = _channels.firstWhere((v) => v.recipientId == userId,
        orElse: () => null);
    if (channel != null) return channel;
    //  开始创建频道
    final channelId =
        await ChannelApi.createDirectMessageChannel(Global.user.id, userId);
    channel = ChatChannel(
        id: channelId,
        parentId: '',
        type: ChatChannelType.dm,
        recipientId: userId,
        name: '');
    // 不允许重复创建
    if (_channels.isNotEmpty && _channels.first.recipientId == userId) {
      return null;
    }
    _channels.insert(0, channel);
    _syncFilterChannels(needUpdate: true);
    await Db.channelBox.put(channel.id, channel);
    return channel;
  }

  ///关闭删除消息频道（不显示）
  Future<void> closeChannel(ChatChannel item) async {
    if (item.type == ChatChannelType.dm ||
        item.type == ChatChannelType.circlePostNews) {
      try {
        await ChannelApi.removeDirectMessageChannel(Global.user.id, item.id);
      } catch (e) {
        debugPrint('getChat closeChannel error: $e');

        ///如果频道不存在，不返回，删除
        if (!(e is RequestArgumentError && e.code == 1021)) {
          return;
        }
      }
    }
    final message = InMemoryDb.getMessageList(item.id)?.lastMessage;
    if (message != null) {
      unawaited(ChannelUtil.instance
          .setUnreadAndSync(message, sync: true, upNow: true));
    }
    removeChannelById(item.id);
    if (kIsWeb) await selectDirectChannel(null);
  }

  ///删除频道
  void removeChannelById(String channelId) {
    // print('getChat removeChannel: $channelId');
    Db.deleteChannelImBox(channelId);
    ChatTable.clearChatHistory(channelId);
    Db.channelBox.delete(channelId);
    _channels.removeWhere((element) => element.id == channelId);
    _ids = _channels.map((e) => e.id).toList();

    _syncFilterChannels();
    updateUnread();
    update();
  }

  ///web消息列表：选中某个频道
  Future<void> selectDirectChannel(ChatChannel channel) async {
    ChatChannel _channel = channel;
    if (_channel == null) {
      final channelId = Db.guildSelectedChannelBox.get('directMessageId');
      if (channelId != null) {
        _channel = getChannel(channelId);
      }
    }
    if (_channel == null) {
      ChatTargetsModel.instance.selectedChatTarget = null;
      GlobalState.selectedChannel.value = null;
    } else {
      ChatTargetsModel.instance.selectedChatTarget = null;
      GlobalState.selectedChannel.value = _channel;
      unawaited(TextChannelController.to(channelId: _channel.id).joinChannel());
      GlobalState.updateDefaultSelectedChannel('directMessageId', _channel.id);
    }
  }

  ChatChannel getChannel(String channelId) {
    return _channels.firstWhere((element) => element.id == channelId,
        orElse: () => null);
  }

  /// * 查找圈子频道
  ChatChannel getCircleChannel(String postId) {
    return _channels.firstWhere(
        (e) =>
            e.recipientId.hasValue &&
            e.recipientId == postId &&
            e.type == ChatChannelType.circlePostNews,
        orElse: () => null);
  }

  void init() {
    unreadSubscription = Db.numUnrealOfChannelBox.watch().listen((event) {
      final String channelId = event.key;
      if (!_ids.contains(channelId)) return;
      updateUnread();
    });
    FriendApplyPageController.friendApplyNum.addListener(updateUnread);

    searchInputModel.searchStream.listen(
      (input) {
        _cacheSearchInput = input;
        _syncFilterChannels(filter: input, needUpdate: true);
      },
    );
    scrollController.addListener(focusNode.unfocus);
  }

  ///清除私信搜索记录
  void clearSearchText() {
    if (textEditingController.text.hasValue) {
      focusNode.unfocus();
      _isSearchEntry = true;
    }
  }

  void resetNoSearchUpdate() {
    if (_isSearchEntry || textEditingController.text.hasValue) {
      _cacheSearchInput = '';
      _syncFilterChannels(needUpdate: true);

      ///ios 使用了原生输入框，修复搜索私信好友进入私信在退出，偶现搜索框内容未被清除
      ///ios EditText.clear()延时50毫秒，保证flutter UI 刷新完成后，在刷新
      if (UniversalPlatform.isIOS) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 50))
              .then((value) => textEditingController.clear());
        });
      } else {
        textEditingController.clear();
      }

      _isSearchEntry = false;
    }
  }

  void _syncFilterChannels({String filter = '', bool needUpdate = false}) {
    filterChannels.clear();
    if (filter.isEmpty && _cacheSearchInput.isEmpty) {
      filterChannels = List<ChatChannel>.from(_channels);
    } else {
      final String toFilter = filter.isNotEmpty ? filter : _cacheSearchInput;
      filterChannels = _channels.where((c) => _isMatch(c, toFilter))?.toList();
    }
    if (needUpdate) update();
  }

  void scrollToRedPoint() {
    if (numUnread.value - FriendApplyPageController.friendApplyNum.value <= 0)
      return;

    final current = (scrollController.offset - 56) / 72;
    final currentIndex = current < 0 ? -1 : current.ceil();

    /// 当前位置 + 1 ->  列表结尾
    for (int i = currentIndex + 1; i < filterChannels.length; i++) {
      final id = filterChannels[i].id;
      final unRead = Db.numUnrealOfChannelBox.get(id) ?? 0;
      if (unRead > 0) {
        scrollController.animateTo((56 + i * 72).toDouble(),
            curve: Curves.easeOut, duration: kThemeAnimationDuration);
        return;
      }
    }

    /// 0 -> 当前位置
    for (int i = 0; i <= currentIndex; i++) {
      final id = filterChannels[i].id;
      final unRead = Db.numUnrealOfChannelBox.get(id) ?? 0;
      if (unRead > 0) {
        scrollController.animateTo((56 + i * 72).toDouble(),
            curve: Curves.easeOut, duration: kThemeAnimationDuration);
        return;
      }
    }
  }

  bool _isMatch(ChatChannel channel, String filter) {
    ///fix 支持匹配群聊名称
    final checkName = StringFilterUtils.checkMatch(channel.name ?? "", filter);
    if (checkName) return true;

    final String userId = channel.recipientId ?? channel.guildId;
    final userInfo = Db.userInfoBox.get(userId);
    final bool nickNameMatched =
        StringFilterUtils.checkMatch(userInfo?.nickname ?? "", filter);
    if (nickNameMatched) return true;
    return StringFilterUtils.checkMatch(userInfo?.markName ?? "", filter);
  }

  void updateUnread() {
    int val = 0;
    int muted = 0;
    List<String> muteList = [];

    final list = Db.userConfigBox.get(UserConfig.mutedChannel);
    if (list != null && list.isNotEmpty && list is List<dynamic>) {
      muteList = list.cast<String>();
    }

    for (final String item in muteList) {
      ///fix 只包含私信的免打扰频道
      final bool isMuted = _ids.contains(item);

      if (isMuted) {
        muted += ChannelUtil.instance.getUnread(item);
      }
    }

    for (final c in channels) {
      final bool isMuted = muteList.contains(c.id);

      ///不计算被设置免打扰频道
      if (!isMuted) {
        ///fix 不计数当前频道红点
        if (c.id != TextChannelController.dmChannel?.id) {
          val += ChannelUtil.instance.getUnread(c.id);
        }
      }
    }
    numUnread.value = val + FriendApplyPageController.friendApplyNum.value;

    final Unread unread =
        Unread(val + FriendApplyPageController.friendApplyNum.value, muted);
    numUnreadMute.value = unread;

    GlobalState.updateBadge();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    unreadSubscription.cancel();
    FriendApplyPageController.friendApplyNum.removeListener(updateUnread);

    searchInputModel.dispose();
    textEditingController.dispose();
    scrollController.dispose();
  }

  void increment() => numUnread.value++;
}
