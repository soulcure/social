import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/stick_message_bean.dart';
import 'package:im/api/text_chat_api.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/services/connectivity_service.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/widgets/popup/web_popup.dart';
import 'package:im/ws/ws.dart';
import 'package:pedantic/pedantic.dart';

import '../../../global.dart';
import '../../../routes.dart';
import 'chat_target_model.dart';

class StickMessageController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final String channelId;
  StickMessageBean stickMessageBean;
  Timer _loadingTimer;
  bool hasRemoteData = false;

  StickMessageController(this.channelId);

  AnimationController animationController;
  Future<String> toStringStrFuture;

  static StickMessageController to({String channelId}) {
    if (channelId == null) {
      return null;
    }
    StickMessageController c;
    try {
      c = Get.find<StickMessageController>(tag: channelId);
    } catch (_) {}
    return c ??= Get.put(StickMessageController(channelId), tag: channelId);
  }

  @override
  void onInit() {
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    Get.find<ConnectivityService>().onConnectivityChanged.listen((res) {
      if (res == ConnectivityResult.none) {
        hasRemoteData = false;
      } else {
        if (GlobalState.selectedChannel.value?.id == channelId) {
          updateStickMessage();
        }
      }
    });
    updateStickMessage();

    super.onInit();
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }

  void onWsMessage(WsMessage message) {
    if (message.action == MessageAction.stick) {
      onStickMessage(message.data);
      TextChannelUtil.instance.stream.add("stick");
    } else if (message.action == MessageAction.unStick) {
      onUnStickMessage(message.data);
      TextChannelUtil.instance.stream.add("unStick");
    }
    hasRemoteData = true;
  }

  void onStickMessage(Map data) {
    // 收到置顶消息后，更新置顶列表。更新未读标志
    final String channelId = data['channel_id'].toString();
    if (channelId != null) {
      final MessageEntity message = MessageEntity.fromJson(data);

      if (message != null) {
        final StickMessageBean stick = StickMessageBean(
          data['top_id'] as String ?? "",
          (data['top_time'] as int ?? 0).toString(),
          message,
          data['is_stick_read'].toString() == "1",
          data['top_user_id'] as String ?? "0",
        );
        stickMessageBean = stick;
        resetToStringFuture();
        _toggleBanner(true);
        update();
        TextChannelController.to(channelId: channelId).update();
        Db.stickMessageBox.put(channelId, stick.toJson());
      }
    }
  }

  void onUnStickMessage(Map data) {
    final String channelId = data['channel_id'].toString();
    if (channelId == null) return;
    final MessageEntity message = MessageEntity.fromJson(data);
    if (message != null &&
        message.messageId == stickMessageBean?.message?.messageId) {
      stickMessageBean = null;
      _toggleBanner(false);
      update();
      TextChannelController.to(channelId: channelId).update();
      Db.stickMessageBox.delete(channelId);
    }
  }

  Future<void> showActions(BuildContext context, MessageEntity message) async {
    final String guildId = GlobalState.selectedChannel?.value?.guildId;
    final GuildPermission gp = PermissionModel.getPermission(guildId);
    final bool hasPermissionPin = PermissionUtils.oneOf(
        gp, [Permission.MANAGE_MESSAGES],
        channelId: channelId);
    final bool isDM =
        GlobalState.selectedChannel.value?.type == ChatChannelType.dm;
    final bool canUnStick = isDM || hasPermissionPin;
    final res = OrientationUtil.portrait
        ? await showCustomActionSheet([
            if (canUnStick) Text('取消置顶'.tr),
            Text('定位到聊天位置'.tr),
          ])
        : await showWebSelectionPopup(context,
            items: [
              if (canUnStick) '取消置顶'.tr,
              '定位到聊天位置'.tr,
            ],
            offsetY: 12);
    if (res == 0 && canUnStick) {
      final res = await showConfirmDialog(
        barrierDismissible: true,
        confirmStyle: OrientationUtil.portrait
            ? Theme.of(context)
                .textTheme
                .bodyText2
                .copyWith(fontSize: 17, color: const Color(0xFF1B4EBF))
            : null,
        title: '取消置顶'.tr,
        content: '确定取消这条置顶吗？取消后，会话成员不会再看到这条置顶'.tr,
      );
      if (res == true)
        try {
          _loadingTimer = Timer(const Duration(milliseconds: 1000), () {
            Loading.show(context);
          });
          await TextChatApi.stickMessage(
              Global.user.id, message.channelId, message.messageId, false);
        } finally {
          _loadingTimer.cancel();
          Loading.hide();
        }
    } else if ((res == 0 && !canUnStick) || (res == 1 && canUnStick)) {
      Routes.pop(context);
      unawaited(HomeScaffoldController.to.gotoWindow(1));
      await TextChannelController.to(channelId: channelId)
          .gotoMessage(message.messageId);
    }
  }

  bool isMessageSticky(String messageId) {
    return messageId != null &&
        messageId == stickMessageBean?.message?.messageId;
  }

  Future<void> updateStickMessage() async {
    if (channelId == null) return [];
    if (hasRemoteData) {
      _toggleBanner(
          stickMessageBean != null && stickMessageBean.isStickRead == false);
      return;
    }
    final resp = await TextChatApi.getStickMessageList(channelId);
    if (resp != null) {
      hasRemoteData = true;
      final List<StickMessageBean> sticksNet = resp.map((e) {
        return StickMessageBean(
          e.item1["stickId"],
          e.item1["stickTime"],
          e.item2,
          e.item1["isStickRead"].toString() == "1",
          e.item1["stickUserId"],
        );
      }).toList();
      stickMessageBean = sticksNet.isEmpty ? null : sticksNet.last;
      if (stickMessageBean != null) {
        _toggleBanner(true);
        resetToStringFuture();
        if (GlobalState.isFirstOpenApp) {
          stickMessageBean.isStickRead = true;
        } else {
          final cache = Db.stickMessageBox.get(channelId);
          if (cache == null) {
            stickMessageBean.isStickRead = false;
          } else {
            final map = jsonDecode(cache);
            stickMessageBean.isStickRead = map['isStickRead'] == true;
          }
        }
        unawaited(Db.stickMessageBox.put(channelId, stickMessageBean.toJson()));
      } else {
        _toggleBanner(false);
        unawaited(Db.stickMessageBox.delete(channelId));
      }
      update();
      TextChannelController.to(channelId: channelId)?.update();
    }
  }

  void readAllStickMessage() {
    stickMessageBean.isStickRead = true;
    unawaited(Db.stickMessageBox.put(channelId, stickMessageBean.toJson()));
    update();
  }

  void resetToStringFuture() {
    toStringStrFuture = () async {
      final messageStr = await stickMessageBean.message.toNotificationString();
      if (isNotNullAndEmpty(messageStr)) {
        return messageStr.replaceAll("\n", '').breakWord;
      }
      return null;
    }();
  }

  void _toggleBanner(bool val) {
    if (animationController.isAnimating) animationController.stop();
    animationController.animateTo(val ? 1 : 0, curve: Curves.fastOutSlowIn);
  }
}
