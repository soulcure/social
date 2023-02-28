import 'dart:convert';

import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:im/app/modules/mute/data/timer_pick_data.dart';

/// - 描述：
///
/// - author: seven
/// - data: 2021/12/10 11:16 上午
class TimerBean {
  String timer;
  bool isSelected;

  TimerBean(this.timer, {this.isSelected = false});
}

class MuteTimeSettingController extends GetxController {
  String guildId;
  String userId;

  /// - 时长列表选择集合
  List<TimerBean> timers = [];

  /// - 自定义时长选择器
  List<dynamic> timerPickData = [];

  /// - 自定义时长,默认选择1分钟
  List<int> mCustomizeTime;

  MuteTimeSettingController(this.guildId, this.userId);

  @override
  void onInit() {
    super.onInit();

    timers.add(TimerBean('10分钟'.tr));
    timers.add(TimerBean('1小时'.tr));
    timers.add(TimerBean('12小时'.tr));
    timers.add(TimerBean('1天'.tr));
    timers.add(TimerBean('自定义'.tr));
    timerPickData = const JsonDecoder().convert(PickerTimerData);
  }

  /// - 有没有一个被选中
  bool hasSelected() =>
      timers.firstWhere((element) => element.isSelected, orElse: () => null) !=
      null;

  /// - 单选选择逻辑
  void setSelected(TimerBean timer) {
    timers.forEach((element) => element.isSelected = false);
    timer.isSelected = true;
    update();
  }

  /// - 设置自定义时长
  void setCustomizeTime(List<int> customizeTime) {
    if (customizeTime.firstWhere((element) => element != 0,
            orElse: () => null) !=
        null) {
      // 对数组进行深拷贝
      mCustomizeTime = List.from(customizeTime);
    } else {
      mCustomizeTime = [0, 0, 1];
    }
    setSelected(timers.last);
  }

  /// - 自定义时长String
  String customizeTimeStr() {
    String customizeTimeStr = '';
    if (mCustomizeTime == null) {
      return customizeTimeStr;
    }
    for (int i = 0; i < mCustomizeTime.length; i++) {
      if (i == 0 && mCustomizeTime[i] != 0) {
        customizeTimeStr += '%s天'.trArgs([mCustomizeTime[i].toString()]);
      } else if (i == 1 && mCustomizeTime[i] != 0) {
        customizeTimeStr += '%s小时'.trArgs([mCustomizeTime[i].toString()]);
      } else if (i == 2 && mCustomizeTime[i] != 0) {
        customizeTimeStr += '%s分钟'.trArgs([mCustomizeTime[i].toString()]);
      }
    }
    return customizeTimeStr;
  }

  /// - 获取选中的时长String
  String customizeToTimeStr() {
    final selectTimer = timers.indexWhere((element) => element.isSelected);
    if (selectTimer == -1) {
      return '0';
    }

    int customizeTime = 0;
    switch (selectTimer) {
      case 0:
        customizeTime = 10 * 60;
        break;
      case 1:
        customizeTime = 60 * 60;
        break;
      case 2:
        customizeTime = 12 * 60 * 60;
        break;
      case 3:
        customizeTime = 24 * 60 * 60;
        break;
      case 4:
        if (mCustomizeTime != null) {
          for (int i = 0; i < mCustomizeTime.length; i++) {
            if (i == 0 && mCustomizeTime[i] != 0) {
              customizeTime += mCustomizeTime[i] * 24 * 60 * 60;
            } else if (i == 1 && mCustomizeTime[i] != 0) {
              customizeTime += mCustomizeTime[i] * 60 * 60;
            } else if (i == 2 && mCustomizeTime[i] != 0) {
              customizeTime += mCustomizeTime[i] * 60;
            }
          }
        }
        break;
    }
    return customizeTime.toString();
  }
}
