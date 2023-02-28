import 'package:flutter/material.dart';
import 'package:im/utils/show_bottom_action_sheet.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/widgets/shake_animation_widget/src/shake_animation_controller.dart';

class WebFormDetectorModel extends ChangeNotifier {
  // 滚动控制器
  ScrollController scrollController;
  ValueNotifier<bool> changed = ValueNotifier(false);
  ValueNotifier<int> tabIndex = ValueNotifier(0);
  ValueNotifier<bool> animating = ValueNotifier(false);
  // 抖动控制器
  ShakeAnimationController shakeAnimationController;
  GestureTapCallback _onReset;
  GestureTapCallback get onReset => _onReset;
  VoidFutureCallBack _onConfirm;
  VoidFutureCallBack get onConfirm => _onConfirm;

  //保存更改按钮是否可用
  ValueNotifier<bool> confirmEnable = ValueNotifier(false);

  WebFormDetectorModel() {
    shakeAnimationController = ShakeAnimationController();
    scrollController = ScrollController();
  }
  void animate() {
    shakeAnimationController.start();
    animating.value = true;
    delay(() {
      animating.value = false;
    });
  }

  // ignore: use_setters_to_change_properties
  void toggleChanged(bool val) {
    changed.value = val;
  }

  // ignore: use_setters_to_change_properties
  void confirmEnabled(bool val) {
    confirmEnable.value = val;
  }

  void setCallback({GestureTapCallback onReset, VoidFutureCallBack onConfirm}) {
    _onReset = onReset;
    _onConfirm = onConfirm;
  }

  @override
  void dispose() {
    changed?.dispose();
    animating?.dispose();
    scrollController?.dispose();
    super.dispose();
  }
}
