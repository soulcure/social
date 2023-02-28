import 'dart:async';
import 'dart:collection';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/guild_folder.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/api/remark_api.dart';
import 'package:im/api/user_api.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/modules/document_online/info/controllers/doc_link_preview_controller.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/app/modules/mute/controllers/mute_listener_controller.dart';
import 'package:im/app/modules/task/task_util.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/db/db.dart';
import 'package:im/db/guild_table.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/live_status_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/routes.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/segment_list/segment_member_list_service.dart';
import 'package:pedantic/pedantic.dart';
import 'package:tuple/tuple.dart';

import '../../../global.dart';
import 'live_status_model.dart';
import 'stick_message_controller.dart';

class ChatTargetsModel extends ChangeNotifier {
  static final ChatTargetsModel instance = ChatTargetsModel();

  BaseChatTarget selectedChatTarget;

  // DirectMessageListTarget directMessageListTarget = DirectMessageListTarget();

  // DirectMessageController dmController = DirectMessageController.to;

  List<BaseChatTarget> _chatTargets;

  UnmodifiableListView<BaseChatTarget> get chatTargets =>
      _chatTargets == null ? null : UnmodifiableListView(_chatTargets);

  BaseChatTarget get firstTarget =>
      chatTargets != null && chatTargets.isNotEmpty ? chatTargets[0] : null;

  ChatTargetsModel() {
    /// TODO: Web后面这里得思考下
    // selectedChatTarget = directMessageListTarget;
  }

  /// 获取服务台索引起点，即私信列表＋私信数量
  int get guildStartIndex => 0;

  Future loadLocalData() async {
    // 先取缓存
    final cacheList = GuildTable.getAll();
    for (final ct in cacheList) {
      ct.sortChannels();
      // 将禁言时间缓存到内存
      MuteListenerController.myMuteTimeMap[ct.id] = ct.noSay;
    }
    //启动时不再读取全部的本地未读消息
    _chatTargets = filterDissolveList(cacheList);
    for (final ct in cacheList) ct.traverseChannelsTask();

    notifyListeners();
  }

  /// 多端同步服务器列表数据
  /// 如果ws同步更新数据中有新创建的guildId，则需要从服务器摘取数据生成新Target
  /// TODO 目前newGuildsData相当于一个二维数组(为了后续兼容目录形式)，这里先当一维处理
  Future<void> syncGuildsDataMaybeFromServer(
      List<dynamic> newGuildsData) async {
    if (newGuildsData == null) return;

    final List<String> _newGuildsIds = [];
    newGuildsData.forEach((newData) {
      final guildIds = (newData['guild_ids'] ?? []) as List<dynamic>;
      if (guildIds.length == 1) {
        final guildId = (guildIds[0] ?? '') as String;
        if (guildId.isNotEmpty) {
          _newGuildsIds.add(guildId);
        }
      }
    });

    try {
      // TODO 这里强转GuildTarget, 先只考虑移动端
      final _oldGuildList = _chatTargets.cast<GuildTarget>();
      final _oldGuildMap = <String, GuildTarget>{};
      _oldGuildList.forEach((guildTarget) =>
          _oldGuildMap.putIfAbsent(guildTarget.id, () => guildTarget));

      final _newGuildsList = [];

      for (int i = 0; i < _newGuildsIds.length; i++) {
        final String _guildId = _newGuildsIds[i];
        if (_oldGuildMap.containsKey(_guildId)) {
          _newGuildsList.add(_oldGuildMap[_guildId]);
        } else {
          final _newGuildFromServer = await _fetchGuildTarget(_guildId);
          if (_newGuildFromServer != null) {
            //  需要重新排序，否则顺序会有问题
            if (_newGuildFromServer.channels != null &&
                _newGuildFromServer.channels.isNotEmpty)
              _newGuildFromServer.sortChannels();
            //  1、WS推送过来的消息：不主动调addChatTarget，需要手动保存
            //  2、避免addCharTarget函数不执行问题：通过抛chatTargets的异常添加内容，若chatTargets已经含有新增对象，则不更新
            GuildTable.add(_newGuildFromServer);
            _newGuildsList.add(_newGuildFromServer);
          }
        }
      }

      _chatTargets = [..._newGuildsList];
      notifyListeners();
    } catch (e) {
      logger.warning('sync guilds data failed: ${e.toString()}');
    }
  }

  Future<GuildTarget> _fetchGuildTarget(String guildId) async {
    try {
      final guildInfo = await GuildApi.getFullGuildInfo(
          guildId: guildId, userId: Global.user.id);
      return guildInfo;
    } catch (e, s) {
      logger.warning("fetch guild target error: $e\n$s");
      return null;
    }
  }

  /// 官方服务器
  /// 此方法仅在ws收到userSetting时需要更新服务台列表时，请求一下最新的服务台列表数据
  Future<void> loadRemoteGuildsData() async {
    // 获取服务器列表
    final returnTuple2 = await GuildApi.getGuildList(userId: Global.user.id);
    final guildList = returnTuple2?.item1;
    if (guildList == null) return;
    _chatTargets.removeWhere((v) {
      if (v is GuildTarget) {
        // v.tryDispose();
        v.disposeSubscriptions();
        return true;
      }
      return false;
    });
    _chatTargets = [..._chatTargets, ...guildList];
    notifyListeners();
    unawaited(
        GuildTable.appendAll(guildList, myGuild2Hash: returnTuple2?.item2));
  }

  /// 官方服务器
  Future<void> loadRemoteData() async {
    ///本地是否有频道数据
    final hasChannel =
        (Db.channelBox?.isOpen ?? false) && Db.channelBox.isNotEmpty;

    unawaited(RemarkApi.getRemarkList(Global.user.id));

    /// 本地数据库的频道缓存列表，网络数据中有的 id，会从这个列表中剔除
    /// 剩下的就是网络数据中没有的，本地有的，即删掉的
    final localChannelIds = Db.channelBox.values.map((e) => e.id).toSet();
    await DirectMessageController.to
        .useRemoteDirectMessageData(localChannelIds);
    final returnTuple2 = await GuildApi.getGuildList(userId: Global.user.id);

    final returnList = filterDissolveList(returnTuple2?.item1);
    List<GuildTarget> guildList;
    if (returnList != null) {
      guildList = returnList;
      print('getChat myGuild2 length: ${guildList?.length}');
      // 把本地的未读消息数量赋给网络数据
      for (final guild in guildList) {
        final oldGuild = _chatTargets.firstWhere((e) => e.id == guild.id,
            orElse: () => null) as GuildTarget;
        if (oldGuild == null) continue;

        for (final channel in guild.channels) {
          localChannelIds.remove(channel.id);
        }
      }
    } else {
      ///如果 myGuild2 接口返回空，localChannelIds 需要排除本地的服务器频道
      _chatTargets
          .whereType<GuildTarget>()
          ?.expand((e) => e.channels)
          ?.forEach((c) {
        localChannelIds.remove(c.id);
      });
    }

    ///同步服务端后,清理频道相关数据. 如果本地没有频道(新用户或者卸载重装),无需清理
    debugPrint('getChat myGuild2 del-length: ${localChannelIds.length}');
    if (hasChannel && localChannelIds.isNotEmpty) {
      unawaited(Db.channelBox.deleteAll(localChannelIds));
      Db.batchDeleteChannelImBox(localChannelIds);
      unawaited(ChatTable.batchClearChatHistory(null, localChannelIds));
    }

    if (guildList != null) {
      ///如果服务端返回的 guildList 不为空，更新本地_chatTargets
      _chatTargets.removeWhere((v) {
        if (v is GuildTarget) {
          v.tryDispose();
          return true;
        }
        return false;
      });
      _chatTargets = [..._chatTargets, ...guildList];
    }

    /// 由于服务器的服务器数据会覆盖本地的
    /// 导致服务器引用变化，需要重新设置选中的服务器引用和选中的频道的引用
    if (_chatTargets != null && _chatTargets.isNotEmpty) {
      if (selectedChatTarget == null) {
        if (OrientationUtil.portrait) selectedChatTarget = firstTarget;
      } else {
        selectedChatTarget = _chatTargets.firstWhere(
            (element) => element.id == selectedChatTarget?.id,
            orElse: () => null);
        selectedChatTarget ??= firstTarget;
      }
    } else {
      selectedChatTarget = null;
      GlobalState.selectedChannel.value = null;
    }

    /// 更新服务器内正在直播的统计数据
    unawaited(getGuildLivingStatus(selectedChatTarget));

    ///清除所有tag,排除当前选中服务台
    DocLinkPreviewController.removeAllExcludeSelectGuild();

    ///切换服务台，获取当前频道任务
    await TaskUtil.instance.reqTaskByGuildId(selectedChatTarget?.id);

    /// 注意，如果未设置选中频道，不要去更新引用
    if (GlobalState.selectedChannel.value != null) {
      final defaultChannel = selectedChatTarget?.defaultChannel;
      final defaultChannelId = defaultChannel?.id;
      if (defaultChannelId == null ||
          GlobalState.selectedChannel.value.id != defaultChannelId) {
        ///如果选中频道有变动(权限变动导致)，需要走 selectDefaultTextChannel
        selectedChatTarget?.selectDefaultTextChannel();
      } else {
        GlobalState.selectedChannel.value = defaultChannel;
        TextChannelController.to(channelId: defaultChannel.id)?.channel =
            defaultChannel;
      }

      final channelId = defaultChannel?.id;
      if (channelId != null)
        Get.put(StickMessageController(channelId), tag: channelId);
    }

    //根据频道列表中active的值，来决定是否去拉成员列表，从而外露用户
    if (selectedChatTarget?.runtimeType == GuildTarget) {
      final target = selectedChatTarget as GuildTarget;
      final channels = target.channels
          .where(
              (t) => t.active == true && t.type == ChatChannelType.guildVoice)
          .toList();
      channels.forEach((c) {
        //拉取成员列表
        SegmentMemberListService.to.getDataModel(c.guildId, c.id, c.type);
      });
    }

    notifyListeners();

    if (_chatTargets == null || _chatTargets.isEmpty) {
      ///最终，如果服务器列表为空，删除myGuild2接口的hash值，这样有异常的账号能恢复列表
      unawaited(Db.userConfigBox.delete(UserConfig.myGuild2Hash));
      logger.info('myGuild2 delete myGuild2Hash');
    } else if (guildList != null) {
      ///如果myGuild2返回的服务器列表不为空，保存服务器列表成功后,再保存hash值
      unawaited(
          GuildTable.appendAll(guildList, myGuild2Hash: returnTuple2?.item2));
    }

    /// 用来处理首次安装登录默认频道选中
    final chatTargetId = SpService.to.getString(SP.defaultChatTarget);
    if (chatTargetId == null && selectedChatTarget != null) {
      final defaultChannel = selectedChatTarget?.defaultChannel;
      await SpService.to
          .setString(SP.defaultChatTarget, selectedChatTarget?.id);
      await selectChatTarget(selectedChatTarget, channel: defaultChannel);

      /// 解决首次加载服务台数据没有上报服务器上线问题
      /// 放在这里的原因是因为
      /// 1. [selectChatTarget] 方法中, 会走 selectedChatTarget == target逻辑,导致没有上报
      /// 2. 如果放在[selectChatTarget] 方法中,会导致点击同一个服务台会多次上报
      await DLogManager.getInstance().guildLogin();
    }

    /// 获取自己在当前服务器是否被禁言
    if (selectedChatTarget != null) {
      unawaited(MuteListenerController.to
          .getMyMutedTimerInCurrentGuild(selectedChatTarget.id));
    }
  }

  Tuple2<BaseChatTarget, ChatChannel> getChatTargetAndChannelByChannelId(
      String channelId) {
    for (final channel in DirectMessageController.to.channels) {
      if (channel.id == channelId) return Tuple2(null, channel);
    }
    if (_chatTargets != null) {
      for (final ct in _chatTargets.whereType<GuildTarget>()) {
        for (final channel in ct.channels) {
          if (channel.id == channelId) return Tuple2(ct, channel);
        }
      }
    }

    return null;
  }

  void addChatTarget(BaseChatTarget target) {
    try {
      // 防止重复加入服务器
      chatTargets.firstWhere((element) => element.id == target.id);
    } catch (e) {
      _chatTargets.insert(0, target);
      GuildTable.add(target);

      notifyListeners();
    }
  }

  BaseChatTarget getChatTarget(String id) {
    return _chatTargets?.firstWhere((e) => e.id == id, orElse: () => null);
  }

  void removeChatTarget(BaseChatTarget target) {
    if (_chatTargets.remove(target)) {
      notifyListeners();
    }
  }

  /// 交换元素，返回true时代表有变动，有变动才更新一下
  void swapChatTarget(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) {
      return;
    }
    if (fromIndex > _chatTargets.length - 1 ||
        toIndex > _chatTargets.length - 1) {
      return;
    }
    if (fromIndex < 0 || toIndex < 0) {
      return;
    }
    final temp = _chatTargets.removeAt(fromIndex);
    _chatTargets.insert(toIndex, temp);
    notifyListeners();
    //　同步更新服务器与缓存
    updateGuildOrder();
  }

  Future updateGuildOrder() async {
    try {
      final _guildTargets =
          List<GuildTarget>.from(_chatTargets.sublist(guildStartIndex));
      final List<GuildFolder> guildFolders =
          _guildTargets.map((e) => GuildFolder(guildIds: [e.id])).toList();
      // 更新排序数据到服务器
      await UserApi.updateSetting(guildFolders: guildFolders);
      // 更新本地缓存
      unawaited(GuildTable.appendAll(_guildTargets));
    } catch (e) {
      debugPrint('updateGuildOrder failed: $e');
    }
  }

  /// [channelId] 为 null 或者一个不存在的 id，则不会选中任何频道，如果为空字符串，则选中默认文字频道
  Future selectChatTargetById(String id,
      {String channelId, bool gotoChatView = false}) async {
    /// 后端数据的 int 0，所有有些接口是返回 "0"
    if (id == null || id.isEmpty) return Future.value();
    if (channelId == "0") channelId = "";

    for (final ct in _chatTargets) {
      if (ct.id == id) {
        /// TODO 想想
        // if (id == directMessageListTarget.id) {
        //   for (final channel in directMessageListTarget.channels) {
        //     if (channel.id == channelId) {
        //       return selectChatTarget(ct,
        //           channel: channel, gotoChatView: gotoChatView);
        //     }
        //   }
        // }
        return selectChatTarget(
          ct,
          channel: ct.getChannel(channelId),
          gotoChatView: gotoChatView,
        );
      }
    }
    return Future.value();
  }

  /// 如果target为空，并且处于横屏状态下，则选择私信
  Future<void> selectChatTarget(
    BaseChatTarget target, {
    ChatChannel channel,
    bool gotoChatView = false,
    String messageId,
  }) {
    Future<void> result = Future.value();

    /// [target] 参数为空是跳转到私信
    if (target == null) {
      /// 跳转私信
      if (channel != null && OrientationUtil.portrait)
        return Routes.pushDirectChatPage(channel);
      else
        DirectMessageController.to.selectDirectChannel(channel);
      notifyListeners();
      return result;
    }

    ///这段逻辑在判断进入相同服务器 return 前，这是因为服务端数据覆盖本地数据时，这里必然是相等的，为了加载出圈子权限，把这个代码提前。会导致重复点击服务器图标依然会发起请求，如果有更佳方案可以修改
    /// 当前服务台有圈子，则获取圈子权限
    if (target is GuildTarget && target.circleAvailable) {
      // 服务器有圈子时，更新圈子权限
      PermissionModel.fetchGuildTopicPermission(target.id);
    }

    /// 以下代码为正常的服务器跳转

    if (selectedChatTarget == target) {
      if (channel == GlobalState.selectedChannel.value &&
          HomeScaffoldController.to.windowIndex.value == 1) {
        if (messageId != null) {
          return TextChannelController.to(channelId: channel.id)
              .jumpToMessage(messageId);
        } else {
          return result;
        }
      } else {
        return target.setSelectedChannel(channel,
            gotoChatView: gotoChatView, messageId: messageId);
      }
    }

    /// 此处代码如果要移动,请注意,位置不对会影响数据上报分析
    /// 在selectedChatTarget还没当前target赋值前处理guildLogout逻辑
    /// 也就是用来记录上一个选中的对象是否为GuildTarget
    if (selectedChatTarget is GuildTarget) {
      DLogManager.getInstance().guildLogout();
    }

    selectedChatTarget = target;
    Db.clickGuildIdBox.put(target.id, DateTime.now());

    DLogManager.getInstance()
      ..guildLogin()
      ..customEvent(
          actionEventId: 'click_enter_server',
          actionEventSubId: target.id ?? '',
          pageId: 'page_list_chat');

    /// 更新服务器内正在直播的统计数据
    unawaited(getGuildLivingStatus(target));

    ///清除所有tag,排除当前选中服务台
    DocLinkPreviewController.removeAllExcludeSelectGuild();

    /// 切换服务台，获取当前频道任务
    TaskUtil.instance.reqTaskByGuildId(target?.id);

    /// TODO: 私密频道无权限红点改造后需要去掉此逻辑
    (selectedChatTarget as GuildTarget).traverseChannelsTask();

    SpService.to.setString(SP.defaultChatTarget, target.id);

    channel ??= target.defaultChannel;
    result = target.setSelectedChannel(channel, gotoChatView: gotoChatView);

    /// 获取自己在当前服务器是否被禁言
    MuteListenerController.to
        .getMyMutedTimerInCurrentGuild(selectedChatTarget.id);

    try {
      target.notifyListeners();
    } catch (_) {}
    notifyListeners();

    return result;
  }

  Future<void> getGuildLivingStatus(BaseChatTarget target) async {
    if (target == null || target is! GuildTarget) return;
    final GuildTarget guildTarget = target;

    // 判断缓存，防止每次切服务器重新摘取数据
    final cached = LiveStatusManager.instance.hasNetPullCached(guildTarget.id);
    if (cached) return;

    final Map<String, dynamic> result =
        await JiGouLiveAPI.getLivingChannels(guildTarget.id);
    debugPrint('load livingStatus : $result');
    if (result['code'] == 200 && result['data'] != null) {
      final GuildLivingStatus status = GuildLivingStatus.fromMap(
          result['data'] as Map<String, dynamic> ?? {});
      LiveStatusManager.instance.updateNotifier(guildTarget.id, status);
    }
  }

  /// 默认选中上次离开选中的服务器，没有则选中私信服务器 （id：0）
  void selectDefaultChatTarget() {
    // todo 这个值需要跟随账号切换
    String chatTargetId;
    chatTargetId = SpService.to.getString(SP.defaultChatTarget);
    final chatTarget = _chatTargets?.firstWhere((v) => v.id == chatTargetId,
        orElse: () => null);
    selectChatTarget(chatTarget);
  }

  /// 获取上一个选中的服务台id
  String getLastChatTargetId() {
    final String chatTargetId = SpService.to.getString(SP.defaultChatTarget);
    final GuildTarget chatTarget = _chatTargets
        ?.firstWhere((v) => v.id == chatTargetId, orElse: () => null);
    return chatTarget?.id;
  }

  /// 判断是否服务器拥有者
  bool get isGuildOwner =>
      (selectedChatTarget is GuildTarget) &&
      Global.user.id == (selectedChatTarget as GuildTarget).ownerId;

  void notify() {
    notifyListeners();
  }

  /// 修改频道或分类排序
  void updateChannelsPosition(GuildTarget guild, List<String> positions,
      {List<ChatChannel> channels}) {
    guild.channels
      ..clear()
      ..addAll(channels);
    guild.channelOrder = positions;
    guild.sortChannels();
    GuildTable.add(guild);
    guild.notifyListeners();
  }

  /// 收到频道和或分类排序修改通知
  void onUpdateChannelsPosition(String guildId, List<String> positions,
      Map<String, dynamic> groupChangedChannel) {
    final GuildTarget guild = ChatTargetsModel.instance.chatTargets
        .firstWhere((element) => element.id == guildId, orElse: () => null);
    if (guild == null) return;
    guild.channelOrder = positions;
    (groupChangedChannel ?? {}).forEach((channelId, parentId) {
      final channel =
          guild.channels.firstWhere((element) => element.id == channelId);
      if (channel != null) {
        channel.parentId = parentId;
      }
    });
    guild.sortChannels();
    if (selectedChatTarget.id == guildId) {
      guild.notifyListeners();
    }
    GuildTable.add(guild);
  }

  ChatChannel getChannel(String id) {
    for (final g
        in ChatTargetsModel.instance.chatTargets.whereType<GuildTarget>()) {
      for (final c in g.channels) {
        if (c.id == id) {
          return c;
        }
      }
    }
    return null;
  }

  void clear() {
    _chatTargets.clear();
  }

  bool isJoinGuild(String guildId) {
    final guild = _chatTargets.whereType<GuildTarget>().firstWhere(
          (target) => target.id == guildId,
          orElse: () => null,
        );
    return guild != null;
  }

  /// 是否有加入的服务器
  bool hasJoinAnyGuild() {
    return _chatTargets?.whereType<GuildTarget>()?.isNotEmpty ?? false;
  }

  GuildTarget getGuild(String guildId) {
    return _chatTargets?.firstWhere(
      (target) => target is GuildTarget && target.id == guildId,
      orElse: () => null,
    );
  }

  ///获取所有服务器下的文字频道
  List<ChatChannel> get chatTextChannels {
    if (_chatTargets == null) return <ChatChannel>[];
    return _chatTargets
        .whereType<GuildTarget>()
        .expand<ChatChannel>((element) => element.channels)
        .where((c) => c.type == ChatChannelType.guildText)
        .toList();
  }

  ///移除被解散的服务器
  List<GuildTarget> filterDissolveList(List<GuildTarget> list) {
    if (list == null) return null;
    return list.where((e) => e.isDissolve == false)?.toList() ?? [];
  }

  ///实时移除被解散的服务器
  Future removeDissolveGuild(String guildId) async {
    final int index = _chatTargets.indexWhere((e) => e.id == guildId);
    if (index >= 0) {
      _chatTargets.removeAt(index);
      notifyListeners();
    }
  }
}
