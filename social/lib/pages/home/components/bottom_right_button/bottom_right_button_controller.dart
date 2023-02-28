import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/db/db.dart';
import 'package:im/db/message_search_table.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/utils/message_util.dart';
import 'package:im/widgets/load_more.dart';

///消息公屏 右下角按钮 Controller: 包括向下箭头、未读数、艾特
class BottomRightButtonController extends GetxController {
  Worker _onWindowChangeListener;

  static BottomRightButtonController to(String channelId) {
    BottomRightButtonController c;
    if (channelId == null) {
      logger.severe('BottomRightButtonController: channelId is null');
      return null;
    }
    try {
      c = Get.find<BottomRightButtonController>(tag: channelId);
    } catch (_) {}
    return c ?? Get.put(BottomRightButtonController(channelId), tag: channelId);
  }

  BottomRightButtonController(this.channelId) {
    channel = Db.channelBox.get(channelId);
  }

  String channelId;

  ///频道
  ChatChannel channel;

  ///未读数
  int unreadNum = 0;
  final RxInt _unreadNumTemp = 0.obs;

  ///是否显示向下的箭头
  bool isShowToBottom = false;

  ///不在可视范围内最近的艾特消息
  String atMessageId;

  ///监听lastMessage的变化
  Worker _lastUpdaterWorker;
  Worker _lastUpdater2Worker;

  ///监听_unreadNumTemp的变化
  Worker _numUpdaterWorker;
  Worker _numUpdater2Worker;

  ///监听频道未读数
  ValueListenable<Box<int>> _numUnreadListenable;

  ///可视范围内最后一条消息
  final Rx<MessageEntity> lastMessageInViewport = Rx<MessageEntity>(null);

  MessageEntity get lastMessage => lastMessageInViewport.value;

  ///是否正在计算中
  bool isCounting = false;

  ///是否自动跳转到底部
  bool _isSelfJumpBottom = false;

  ///向下加载状态
  Rx<LoadMoreStatus> loadMoreState = Rx<LoadMoreStatus>(LoadMoreStatus.noMore);

  // ignore: avoid_setters_without_getters
  set isSelfJumpBottom(bool value) {
    if (HomeScaffoldController.to.canChatWindowVisible) {
      _isSelfJumpBottom = value;

      ///web版: 提前清零未读数
      if (kIsWeb) {
        ChannelUtil.instance.setUnreadAndSync(
            InMemoryDb.getMessageList(channelId).lastMessage,
            sync: true);
      }
    }
  }

  void clear() {
    // debugPrint('getChat bottomRight clear:$channelId');
    _unreadNumTemp.value = 0;
    unreadNum = 0;
    atMessageId = null;
    isShowToBottom = false;
    lastMessageInViewport.value = null;
    if (channel.type == ChatChannelType.guildText)
      _onWindowChangeListener?.dispose();

    _numUnreadListenable?.removeListener(_onListenUnreadNum);
    _lastUpdaterWorker?.dispose();
    _lastUpdater2Worker?.dispose();
    _numUpdaterWorker?.dispose();
    _numUpdater2Worker?.dispose();
    _lastUpdaterWorker = null;
    _lastUpdater2Worker = null;
    _numUpdaterWorker = null;
    _numUpdater2Worker = null;
    _numUnreadListenable = null;
  }

  ///监听主界面变动
  void _onWindowChange(_) {
    // debugPrint('getChat bottomRight windowChange: $channelId');
    if (GlobalState.selectedChannel.value?.id != channelId) return;
    if (HomeScaffoldController.to.canChatWindowVisible) {
      updateByScroll();
      _countUnreadNum(null);
    }
  }

  ///进入频道消息公屏
  void joinChannel({bool isClearUnread = true}) {
    clear();
    loadMoreState.value = LoadMoreStatus.noMore;

    ///消息列表Controller
    final m = TextChannelController.to(channelId: channelId);
    if (m.messageList.isNotEmpty)
      lastMessageInViewport.value ??= m.messageList.last;
    // debugPrint('getChat bottomRight joinChannel:$channelId - $isClearUnread');
    if (HomeScaffoldController.to.canChatWindowVisible && isClearUnread)
      ChannelUtil.instance
          .setUnreadAndSync(lastMessage, sync: true, upNow: true);

    ///服务器频道才需要监听 windowIndex
    if (channel.type == ChatChannelType.guildText) {
      _onWindowChangeListener?.dispose();
      _onWindowChangeListener =
          ever(HomeScaffoldController.to.windowIndex, _onWindowChange);
    }

    _numUnreadListenable =
        Db.numUnrealOfChannelBox.listenable(keys: [channelId]);
    _numUnreadListenable.addListener(_onListenUnreadNum);
    _lastUpdaterWorker = interval<void>(lastMessageInViewport, _countUnreadNum,
        time: const Duration(milliseconds: 200));
    _lastUpdater2Worker = debounce<void>(lastMessageInViewport, _countUnreadNum,
        time: const Duration(milliseconds: 200));
    _numUpdaterWorker = interval<void>(_unreadNumTemp, _countUnreadNum,
        time: const Duration(milliseconds: 200));
    _numUpdater2Worker = debounce<void>(_unreadNumTemp, _countUnreadNum,
        time: const Duration(milliseconds: 200));
    _countUnreadNum(null);
  }

  ///未读数更新时调用
  Future<void> _onListenUnreadNum() async {
    final tempNum = ChannelUtil.instance.getUnread(channelId);
    //debugPrint('getChat bottomRight onListen: $tempNum');

    ///未读数有变化时，才更新
    if (tempNum != _unreadNumTemp.value) {
      _unreadNumTemp.value = tempNum;
    }
  }

  /// 计算并更新未读数、艾特
  Future<void> _countUnreadNum(_) async {
    //该处会被延时调用所以HomeScaffoldController是有可能被delete的
    if (!Get.isRegistered<HomeScaffoldController>() ||
        !HomeScaffoldController.to.canChatWindowVisible) return;

    if (isCounting) return;
    isCounting = true;
    // final start = DateTime.now();

    if (checkIsReturn()) return;
    final boxUnreadNum = ChannelUtil.instance.getUnread(channelId);
    if (boxUnreadNum <= 0) {
      isCounting = false;
      unreadNum = 0;
      atMessageId = null;
      final m = TextChannelController.to(channelId: channelId);
      isShowToBottom = m.numBottomInvisible > 1;
      update();
      return;
    }
    final firstId = Db.firstMessageIdBox.get(channelId);
    if (firstId == null || lastMessage == null) {
      isCounting = false;
      return;
    }
    // debugPrint(
    //     'getChat bottomRight count: $channelId, lastMessage: ${lastMessage.messageId}, $lastMessage');
    final beginId = lastMessage.messageIdBigInt;
    if (lastMessage.messageIdBigInt > firstId) {
      // beginId = firstId;
      ///强制更新 firstId
      ChannelUtil.instance
          .updateFirstMessageIdBox(lastMessage, forceUpdate: true);
    }

    ///结束计算,更新未读数
    void countEnd() {
      if (boxUnreadNum != unreadNum) {
        //更新未读数
        ChannelUtil.instance
            .setUnreadAndSync(lastMessage, sync: true, unread: unreadNum);
      }
      print('unreadNum: $unreadNum');
      _unreadNumTemp.value = unreadNum;
      update();
      isCounting = false;
    }

    ///web版的处理
    if (kIsWeb) {
      _countForWeb();
      countEnd();
      return;
    }

    ///获取最后的可见消息ID
    final lastId = Db.lastVisibleMessageIdBox.get(channelId);
    if (lastId == null || lastMessage.messageIdBigInt >= lastId) {
      ///滚动到最后一条消息了
      unreadNum = 0;
      atMessageId = null;
    } else {
      if (checkIsReturn()) return;

      ///计算未读数
      unreadNum = await MessageSearchTable.countBetween(
        channel: channelId,
        userId: Global.user.id,
        begin: beginId,
        end: lastId,
      );
      if (checkIsReturn()) return;
      if (unreadNum > 0) await _checkAt(beginId, lastId);
    }
    if (checkIsReturn()) return;
    // debugPrint('getChat bottomRight count: $channelId -> $unreadNum');

    resetLoadMoreState();
    countEnd();
    // debugPrint(
    //     "getChat bottomRight count - 耗时:${DateTime.now().difference(start).inMilliseconds} ms");
  }

  ///更新：向下加载状态loadMoreState
  void resetLoadMoreState() {
    if (kIsWeb) {
      setWebLoadMoreState();
    } else {
      final m = TextChannelController.to(channelId: channelId);
      final BigInt lastId = Db.lastVisibleMessageIdBox.get(channelId);
      // debugPrint('getChat reset lastId:$lastId');
      if (m.internalList == null || m.internalList.isEmpty) {
        loadMoreState.value = LoadMoreStatus.noMore;
        return;
      }

      ///更新状态,避免底部菊花显示出错
      ///比较：显示的最后一条消息 和 数据库最后一条消息
      if (lastId == null || m.internalList.lastMessageId >= lastId) {
        if (loadMoreState.value != LoadMoreStatus.noMore) {
          loadMoreState.value = LoadMoreStatus.noMore;
          // debugPrint('getChat reset - noMore');
        }
      } else {
        if (loadMoreState.value != LoadMoreStatus.ready) {
          loadMoreState.value = LoadMoreStatus.ready;
          // debugPrint('getChat reset - ready');
        }
      }
    }
  }

  ///web版：设置loadMoreState
  void setWebLoadMoreState() {
    final m = TextChannelController.to(channelId: channelId);
    final dbMessageList = InMemoryDb.getMessageList(channelId);
    if (dbMessageList.isEmpty ||
        m.internalList == null ||
        m.internalList.isEmpty) return;
    final hasMore = dbMessageList.lastMessageId > m.internalList.lastMessageId;
    loadMoreState.value =
        hasMore ? LoadMoreStatus.ready : LoadMoreStatus.noMore;
  }

  ///搜索艾特消息
  Future<void> _checkAt(BigInt beginId, BigInt endId) async {
    final m = TextChannelController.to(channelId: channelId);
    atMessageId = (await MessageSearchTable.searchAtMessage(
      beginId: beginId,
      endId: endId,
      channelId: channelId,
      atUser: Global.user.id,
      atRoles: PermissionModel.getPermission(m.guildId).userRoles,
      before: false,
    ))
        ?.toString();
  }

  ///web版：直接按照List中的位置来计算和搜索
  void _countForWeb() {
    final dbMessageList = InMemoryDb.getMessageList(channelId);
    final lastIndex = dbMessageList.list.indexWhere((e) {
      return e.messageId == lastMessage.messageId;
    });
    print(
        'dbMessageList: ${dbMessageList.length} lastIndex: $lastIndex  lastMessage.messageId:${lastMessage.messageId}');
    unreadNum = dbMessageList.list.length - lastIndex - 1;
    // debugPrint('getChat bottomRight web --- num: $unreadNum');
    if (unreadNum > 0) {
      final len = dbMessageList.length;
      MessageEntity message;
      atMessageId = null;
      for (var i = len - unreadNum; i < len; i++) {
        if (i < 0 || i > len - 1) return;
        message = dbMessageList.list[i];
        if (MessageUtil.atMe(message) != AtMeType.none) {
          atMessageId = message.messageId;
          break;
        }
      }
    } else {
      unreadNum = 0;
      atMessageId = null;
    }

    ///设置向下加载状态,避免底部菊花显示出错
    resetLoadMoreState();
  }

  /// 消息公屏滚动时调用
  void updateByScroll() {
    final m = TextChannelController.to(channelId: channelId);
    if (m.bottomIndex == null || m.messageList.isEmpty) return;

    final bottomIndex = min(m.bottomIndex + 1, m.messageList.length - 1);
    // debugPrint('getChat bottomRight ------- scroll: $bottomIndex');
    ///滚动时，更新 lastMessageInViewport 的值
    lastMessageInViewport.value ??= m.messageList.last;
    if (m.messageList[bottomIndex].messageIdBigInt >
        lastMessage.messageIdBigInt) {
      lastMessageInViewport.value = m.messageList[bottomIndex];
    }

    ///判断是否显示：向下的箭头
    if (unreadNum <= 0) {
      isShowToBottom = m.numBottomInvisible > 1;
    } else {
      isShowToBottom = false;
    }
    update();
  }

  ///检查是否：不计算直接返回
  bool checkIsReturn() {
    ///判断消息公屏是否自动跳转底部，是则返回true
    if (_isSelfJumpBottom) {
      //debugPrint('getChat bottomRight isSelfJumpBottom: $_isSelfJumpBottom');
      _isSelfJumpBottom = false;
      isCounting = false;
      return true;
    }
    return false;
  }

  ///跳转
  Future<void> jump() async {
    final m = TextChannelController.to(channelId: channelId);
    if (atMessageId == null) {
      m.jumpToBottom();
    } else {
      BigInt lastId;
      if (kIsWeb) {
        lastId = InMemoryDb.getMessageList(channelId).lastMessageId;
      } else {
        lastId = Db.lastVisibleMessageIdBox.get(channelId);
      }
      if (lastId != null && lastId.toString() == atMessageId) {
        m.jumpToBottom();
      } else {
        await m.gotoMessage(atMessageId.toString(), before: false);
      }
    }
    update();
  }
}
