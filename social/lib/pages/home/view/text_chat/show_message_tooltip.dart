import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/view/text_chat/message_tools.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/message_tooltip/message_tooltip.dart';

bool _opened = false;
MessageTooltip _tooltip;

Worker _onWindowChangeListener;

void showMessageTooltip(
  BuildContext context, {
  @required MessageEntity message,
  @required VoidCallback reply,
  bool onlyEmoji = false,
  VoidCallback onClose,
  bool shouldShowReply = true,
  VoidCallback showTipErrorCallback,
}) {
  if (ChannelUtil.instance.getChannel(message.channelId) == null) return;
  if (message.messageId == null) return;
  if (_opened) return;
  _opened = true;

  // 键盘遮挡弹起临时处理方式
  final int timeout = MediaQuery.of(context).viewInsets.bottom == 0 ? 0 : 300;
  FocusScope.of(context).unfocus();
  delay(() {
    _tooltip = MessageTooltip(
        onClose: () {
          if (onClose != null) onClose();
          _opened = false;
          _onWindowChangeListener.dispose();
          _tooltip = null;
        },
        left: 21,
        right: 21,
        minHeight: 246,
        arrowTipDistance: 0,
        arrowBaseWidth: 0,
        arrowLength: 0,
        borderColor: const Color(0xff3d3f46),
        minimumOutSidePadding: 10,
        outsideBackgroundColor: Colors.transparent,
        backgroundColor: appThemeData.backgroundColor,
        shadowBlurRadius: 5,
        shadowSpreadRadius: 1,
        shadowColor: Colors.black12,
        borderRadius: 8,
        builder: (context, popupDirection) {
          return InheritedTheme.captureAll(
            Global.navigatorKey.currentContext,
            MessageTools(popupDirection, onlyEmoji: onlyEmoji, message: message,
                close: () {
              _tooltip.close();
              _tooltip = null;
            }, shouldShowReply: shouldShowReply, relay: reply),
          );
        });
    try {
      _tooltip.show(context);
    } catch (_) {
      //如果报错，_opened要设置为false
      _opened = false;
      // 圈子详情页整体不够一屏，且键盘打开时，长按回复，键盘回收:
      // 此时页面需要刷新，context会失效, show方法会报错，需要调用showTipErrorCallback
      showTipErrorCallback?.call();
      return;
    }

    /// Android 返回键可以在显示菜单的情况下回到首页，此时需要关闭菜单
    _onWindowChangeListener = ever(
        HomeScaffoldController.to.windowIndex, _closeToolTipWhenLeaveImPage);
  }, timeout);
}

void _closeToolTipWhenLeaveImPage(_) {
  if (HomeScaffoldController.to.windowIndex.value != 1) {
    _tooltip.close();
  }
}

void closeToolTip() {
  _tooltip?.close();
}
