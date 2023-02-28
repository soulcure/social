import 'dart:async';

import 'package:get/get.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/video_call/video_control.dart';
import 'package:im/ws/ws.dart';

class AVCall {
  static Completer _callCompleter;

  /// 呼叫对方
  static Future call(String userId, bool video) {
    final obj = {
      'action': 'call',
      'objectId': userId,
      'video': video ? 1 : 0,
      'desc': '[呼叫]'.tr,
    };
    _callCompleter = Completer();
    Ws.instance.send(obj).catchError((e, s) {
      _callCompleter?.completeError(e, s);
      _callCompleter = null;
    });
    return _callCompleter.future;
  }

  /// type: ；2=（没用到）；3= ；4 5=主动呼叫中；6=通话结束
  static void changeVideoCall(
      String channelId, int type, String callId, String messageId) {
    final obj = {
      'action': 'callNoticeUp',
      'objectId': callId,
      'channelId': channelId,
      'type': type,
      'message_id': messageId,
      'desc': '[呼叫]'.tr,
    };

    // ignore: argument_type_not_assignable_to_error_handler
    Ws.instance.send(obj).catchError(logger.info);
  }

  // ignore: avoid_annotating_with_dynamic
  static void process(dynamic data) {
    final type = data["type"];
    switch (type) {
      case 0: // 被呼叫
        VideoControl.handleCall(data);
        break;
      case 4: // 主叫方停止呼叫
      case 3: // 被叫方拒绝
      case 6:
        VideoControl.handleCancel("对方已取消".tr, data["channelId"]);
        break;
      case 5: // 呼叫成功的响应数据
        _callCompleter?.complete(data);
        _callCompleter = null;
        break;
      default:
        break;
    }
  }
}
