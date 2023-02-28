import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/text_chat_api.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/json/message_card_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/model/text_channel_event.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/routes.dart';
import 'package:im/utils/message_util.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/web/widgets/popup/web_popup.dart';
import 'package:im/widgets/refresh/list_model.dart';
import 'package:im/ws/pin_handler.dart';
import 'package:pedantic/pedantic.dart';

import '../../../global.dart';

class PinListModel extends ListModel<PinListEntity> {
  StreamSubscription _pinSubscription;
  final List<String> unFoldMessageList = [];
  List<String> _unreadList = [];

  List<String> get unreadList => _unreadList;
  Timer _loadingTimer;
  final ChatChannel channel;

  String get tagId => channel?.id ?? GlobalState.selectedChannel?.value?.id;

  PinListModel({this.channel}) {
    fetchData = () async {
      final res = await TextChatApi.getPinList(
              tagId,
              pageSize,
              internalList.isEmpty
                  ? 0
                  : internalList.last.pinTime.millisecondsSinceEpoch)
          .then((value) {
        for (final e in value) {
          // 关联 IM 的数据
          final existing =
              InMemoryDb.getMessage(channel.id, e.message.messageIdBigInt);
          if (existing != null) {
            if (existing.content.type == MessageType.messageCard) {
              // 消息卡片的 key 使用 pin 列表拉取下来的，因为这里拉取下来的 key 肯定是完整的
              (existing.content as MessageCardEntity)
                  .resetKeys((e.message.content as MessageCardEntity).keys);
            }
            e.message = existing;
          }
        }
        return value;
      });

      _unreadList = Db.pinMessageUnreadBox.get(tagId) ?? [];
      return res;
    };

    _pinSubscription = TextChannelUtil.instance.stream.listen((e) async {
      if (e is RecallMessageEvent) {
        /// - 收到撤回消息通知，删除列表中被撤回的消息
        internalList
            .removeWhere((element) => element.message.messageId == e.id);
        notifyListeners();
      } else if (e.runtimeType == PinEvent) {
        final entity = (e as PinEvent).message.content as PinEntity;
        final oriMessageId = entity.id;
        final action = entity.action;
        final pinTime = (e as PinEvent).message.time;
        final channelId = (e as PinEvent).message.channelId;
        if (channelId != tagId) return;
        if (action == 'unpin') {
          internalList.removeWhere(
              (element) => element.message.messageId == oriMessageId);
          notifyListeners();
        } else {
          final messageIdx = internalList.indexWhere(
              (element) => element.message.messageId == oriMessageId);
          if (messageIdx >= 0) return;
          final message = await MessageUtil.getMessage(
              oriMessageId,
              (e as PinEvent)
                  .message
                  .channelId); //ChatTable.getMessage(oriMessageId);
          internalList.insert(0, PinListEntity(pinTime, message));
          notifyListeners();
        }
      }
    });
  }

  @override
  void dispose() {
    _pinSubscription?.cancel();
    _loadingTimer?.cancel();
    clearUnreadBox();
    Loading.hide();
    super.dispose();
  }

  void clearUnreadBox() {
    unawaited(Db.pinMessageUnreadBox.put(tagId, []));
  }

  Future<void> showActions(BuildContext context, MessageEntity message) async {
    final channel = this.channel ?? GlobalState.selectedChannel?.value;
    final String guildId = channel?.guildId;
    final String channelId = tagId;
    final GuildPermission gp = PermissionModel.getPermission(guildId);
    final bool hasPermissionPin = PermissionUtils.oneOf(
        gp, [Permission.MANAGE_MESSAGES],
        channelId: channelId);
    final bool isDM = channel?.type == ChatChannelType.dm;
    final bool canPinUnPinAction = isDM || hasPermissionPin;
    final List<String> actionNames = [
      if (canPinUnPinAction) 'pin',
      'location',
    ];

    final res = OrientationUtil.portrait
        ? await showCustomActionSheet([
            if (canPinUnPinAction) const Text('Un-Pin'),
            Text('定位到聊天位置'.tr),
          ])
        : await showWebSelectionPopup(context,
            items: [if (canPinUnPinAction) 'Un-Pin', '定位到聊天位置'.tr],
            offsetY: 12);
    if (res == null || res == -1) return;
    if (actionNames[res] == 'pin') {
      final res = await showConfirmDialog(
        barrierDismissible: true,
        title: '取消Pin'.tr,
        content: '确定取消这条Pin？'.tr,
      );
      if (res == true)
        try {
          _loadingTimer = Timer(const Duration(milliseconds: 1000), () {
            Loading.show(context);
          });
          await TextChatApi.pinMessage(
              Global.user.id, message.channelId, message.messageId, false);
        } finally {
          _loadingTimer.cancel();
          Loading.hide();
        }
    } else if (actionNames[res] == 'location') {
      Routes.pop(context);
      if (channel == null) unawaited(HomeScaffoldController.to.gotoWindow(1));
      final tcController = TextChannelController.to(channelId: channelId);
      await tcController.gotoMessage(message.messageId);
    }
  }
}

class PinListEntity {
  final DateTime pinTime;
  MessageEntity message;

  PinListEntity(this.pinTime, this.message);

  factory PinListEntity.fromJson(Map json) {
    final message = MessageEntity.fromJson(json);
    // VoiceEntity toJson在服务端保存了isRead字段，pin列表不需要消失红点，故将isRead设置为true
    if (message.content.runtimeType == VoiceEntity) {
      (message.content as VoiceEntity).isRead = true;
    }
    return PinListEntity(
      DateTime.fromMillisecondsSinceEpoch(json['pin_time'] ?? 0),
      message,
    );
  }
}
