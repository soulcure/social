import 'dart:async';

import 'package:get/get.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/db/db.dart';
import 'package:im/db/message_search_table.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:pedantic/pedantic.dart';

///消息公屏 右上角按钮 Controller: 包括未读数、艾特
class TopRightButtonController extends GetxController {
  Worker _onWindowChangeListener;

  static TopRightButtonController to(String channelId) {
    TopRightButtonController c;
    if (channelId == null) {
      logger.severe('TopRightButtonController: channelId is null');
      return null;
    }
    try {
      c = Get.find<TopRightButtonController>(tag: channelId);
    } catch (_) {}
    return c ?? Get.put(TopRightButtonController(channelId), tag: channelId);
  }

  TopRightButtonController(this.channelId) {
    channel = Db.channelBox.get(channelId);
  }

  String channelId;

  ///频道
  ChatChannel channel;

  final RxInt _unreadNum = 0.obs;

  set unreadNum(int value) => _unreadNum.value = value;

  int get unreadNum => _unreadNum.value;

  bool isJoin = false;

  BigInt firstUnreadId;
  bool _searchFinished = false;
  MessageEntity atMessage;
  Worker _numUpdater;
  Worker _numUpdater2;
  Worker _oldestMessageInViewportUpdater;

  /// 未读的第一条消息
  final Rx<MessageEntity> _oldestMessageInViewport = Rx<MessageEntity>(null);

  /// [updateNumUnread] 只用来更新 [unreadNum] 变量，其他操作请放到 [_onNumUnreadChange]，因为它有重复过滤
  Future<void> updateNumUnread() async {
    final m = TextChannelController.to(channelId: channelId);
    if (m == null || m.topIndex == null) return;
    if (m.topIndex >= m.messageList.length) return;

    if (handleNull()) return;

    if (m.messageList[m.topIndex].messageIdBigInt <
        _oldestMessageInViewport.value.messageIdBigInt) {
      _oldestMessageInViewport.value = m.messageList[m.topIndex];
    }
    if (_oldestMessageInViewport.value.messageIdBigInt <= firstUnreadId) {
      _clear();
    }
  }

  void _onWindowChange(_) {
    // debugPrint('getChat topRight windowChange: $channelId');

    ///GlobalState.selectedChannel 的赋值比 widget.model.channel 快
    ///如果不相等，则返回 (修复：切换频道后，清零了旧频道的未读数)
    if (GlobalState.selectedChannel.value == null) return;
    if (GlobalState.selectedChannel.value?.id != channel.id) return;
    if (HomeScaffoldController.to.canChatWindowVisible) {
      // joinChannel(Db.firstMessageIdBox.get(channelId));
      // updateNumUnread();
    } else {
      _clear();
    }
  }

  Future<void> _checkAt(int numUnread) async {
    if (_searchFinished) return;
    if (_oldestMessageInViewport.value == null) return;
    final m = TextChannelController.to(channelId: channelId);

    /// 刚进入频道没有 @ 消息，则从视口最上方一条消息开始搜索
    final before = atMessage?.messageIdBigInt ??
        _oldestMessageInViewport.value.messageIdBigInt;

    /// 刚进入频道，atMessage 为空，所以 beforeMessageId 传 null，所以搜索的起始位置是最后一条消息
    /// 而不是视窗内最后一条消息，此时 _unreadNum 也是没减去为视窗内的消息条数，所以是对的
    final atMessageId = await MessageSearchTable.searchAtMessage(
      beginId: firstUnreadId,
      endId: before,
      channelId: channelId,
      atUser: Global.user.id,
      atRoles: PermissionModel.getPermission(m.guildId).userRoles,
    );
    if (atMessageId != null) {
      atMessage = await ChatTable.getMessage(atMessageId.toString());
    } else {
      atMessage = null;
    }
    update();
    if (atMessage == null) {
      _searchFinished = true;
    }
  }

  void joinChannel(BigInt firstUnreadId) {
    if (isJoin) {
      return;
    }
    isJoin = true;
    this.firstUnreadId = firstUnreadId;
    _oldestMessageInViewport.value = null;

    // debugPrint('getChat topRight joinChannel:$channelId -- $firstUnreadId');
    if (firstUnreadId == null) {
      _clear();
      return;
    }

    ///服务器频道才需要监听 windowIndex
    if (channel.type == ChatChannelType.guildText) {
      _onWindowChangeListener?.dispose();
      _onWindowChangeListener =
          ever(HomeScaffoldController.to.windowIndex, _onWindowChange);
    }
    _unreadNum.value = 0;
    _searchFinished = false;
    atMessage = null;

    final m = TextChannelController.to(channelId: channelId);
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        // 防止数组越界
        _oldestMessageInViewport.value = m.messageList[m.topIndex];
        _updateNum(null);
      } catch (_) {}
    });

    update();

    _numUpdater?.dispose();
    _numUpdater2?.dispose();
    _oldestMessageInViewportUpdater?.dispose();

    _numUpdater2 = interval<void>(_oldestMessageInViewport, _updateNum,
        time: const Duration(seconds: 1));
    _numUpdater = debounce<void>(_oldestMessageInViewport, _updateNum,
        time: const Duration(seconds: 1));

    _oldestMessageInViewportUpdater =
        interval(_oldestMessageInViewport, (message) {
      if (_oldestMessageInViewportUpdater.disposed) return;

      if (atMessage == null ||
          message.messageIdBigInt < atMessage.messageIdBigInt) {
        _checkAt(_unreadNum.value);
      }
    }, time: 300.milliseconds);
  }

  Future<void> jump() async {
    final model = TextChannelController.to(channelId: channelId);
    if (atMessage == null) {
      if (firstUnreadId != null) {
        try {
          ///fix firstUnreadId有可能是notPull表态消息
          await model.gotoMessage(firstUnreadId.toString());
        } catch (e) {
          print("jump error=$e");
        }
      }
      _clear();
    } else {
      await model.gotoMessage(atMessage.messageId);

      /// 如果 @ 消息刚好是最后一条未读消息，那么不需要继续检查 @
      if (firstUnreadId == atMessage.messageIdBigInt) {
        _clear();
      } else {
        try {
          Future.delayed(const Duration(milliseconds: 100), () async {
            _unreadNum.value = await MessageSearchTable.countBetween(
                    userId: Global.user.id,
                    channel: model.channelId,
                    begin: firstUnreadId,
                    end: atMessage.messageIdBigInt) +
                1;
            unawaited(_checkAt(_unreadNum.value));
          });
        } catch (_) {}
      }
    }
  }

  void _clear() {
    if (_numUpdater != null && !_numUpdater.disposed) {
      _numUpdater.dispose();
      _numUpdater2.dispose();
      _oldestMessageInViewportUpdater.dispose();
    }
    unreadNum = 0;
    update();
  }

  void clear() {
    if (channel.type == ChatChannelType.guildText) {
      _onWindowChangeListener?.dispose();
    }
    _clear();
  }

  Future<void> _updateNum(void _) async {
    if (handleNull()) return;
    if (_numUpdater.disposed) return;
    _unreadNum.value = await MessageSearchTable.countBetween(
        channel: channelId,
        userId: Global.user.id,
        begin: firstUnreadId,
        end: _oldestMessageInViewport.value.messageIdBigInt);
    //因为是异步，所以有可能查出结果时已经被clear掉了，要再次判断一下
    if (handleNull() || _numUpdater.disposed || _unreadNum.value == null)
      return;
    if (_unreadNum.value <= 0) {
      _clear();
    } else {
      update();
    }
  }

  ///容错处理：防止提示框不消失
  bool handleNull() {
    if (firstUnreadId == null || _oldestMessageInViewport.value == null) {
      //容错处理：防止提示框不消失
      if (_unreadNum.value > 0) {
        logger.warning(
            "TopRightButtonController handleNull: $firstUnreadId, ${_oldestMessageInViewport.value}");
        _clear();
      }
      return true;
    }
    return false;
  }
}
