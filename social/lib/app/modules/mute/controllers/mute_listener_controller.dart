import 'dart:async';
import 'dart:collection';

import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:im/pages/home/model/chat_index_model.dart';

/// - 描述: 禁言时长控制器
///
/// - author: seven
/// - data: 2021/12/17 10:46 上午
class MuteListenerController extends GetxController {
  /// - 缓存自己在每个服务台的禁言时长
  static HashMap<String, int> myMuteTimeMap = HashMap();

  /// - 被禁言时长，单位：秒
  int muteTime = 0;

  /// - 定时器，
  Timer mTimer;

  /// - 每60秒更新禁言时长
  int countDownTime = 60;

  Duration duration;

  /// - 是否被禁言，私聊和群聊不受禁言限制
  bool get isMuted => muteTime > 0;

  static MuteListenerController get to {
    MuteListenerController c;
    try {
      c = Get.find<MuteListenerController>();
    } catch (_) {}
    return c ??= Get.put(MuteListenerController());
  }

  @override
  void onInit() {
    super.onInit();
    duration = Duration(seconds: countDownTime);
  }

  @override
  void onClose() {
    super.onClose();
    cancelTimer();
    mTimer = null;
  }

  /// - 开始倒计时
  void startTimer() {
    if (muteTime > 0) {
      mTimer?.cancel();
      // 定时回调
      mTimer = Timer.periodic(duration, (_) {
        muteTime -= countDownTime;
        if (muteTime <= 0) {
          cancelTimer();
        }
        update();
      });
    } else {
      cancelTimer();
    }
  }

  /// - 取消倒计时
  void cancelTimer() {
    muteTime = 0;
    mTimer?.cancel();
  }

  /// - ws接收到的禁言和解禁通知，
  /// - mutedTime:禁言：禁言时长 解禁：0
  void onWsMessage(String guildId, int mutedTime) {
    // 缓存对应的服务台禁言时长
    myMuteTimeMap[guildId] =
        DateTime.now().millisecondsSinceEpoch + mutedTime * 1000;

    // 不是当前服务台，则不处理
    if (guildId != ChatTargetsModel.instance.selectedChatTarget?.id) return;
    muteTime = mutedTime;
    startTimer();
    update();
  }

  /// - 获取自己在当前服务台的禁言时间，切换服务台时调用
  Future<void> getMyMutedTimerInCurrentGuild(String guildId) async {
    // 先取消倒计时
    cancelTimer();

    if (!myMuteTimeMap.keys.contains(guildId)) {
      myMuteTimeMap[guildId] = 0;
      muteTime = 0;
    } else {
      muteTime =
          (myMuteTimeMap[guildId] - DateTime.now().millisecondsSinceEpoch) ~/
              1000;
      if (muteTime < 0) {
        muteTime = 0;
      }
    }
    startTimer();
    update();
  }
}
