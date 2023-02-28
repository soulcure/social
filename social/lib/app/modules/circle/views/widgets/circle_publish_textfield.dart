import 'package:flutter/material.dart';
import 'package:flutter_text_field/flutter_text_field.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/controllers/circle_publish_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/pages/home/view/bottom_bar/keyboard_container2.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:rich_input/rich_input.dart';

class CirclePublishTextField extends StatefulWidget {
  final void Function(bool) focusChange;
  const CirclePublishTextField({Key key, this.focusChange}) : super(key: key);

  @override
  _CirclePublishTextFieldState createState() => _CirclePublishTextFieldState();
}

class _CirclePublishTextFieldState extends State<CirclePublishTextField> {
  CirclePublishController get controller => GetInstance().find();

  double _scrollStartPosition = -1; // 用于安卓输入框滚动计算

  bool _handleScrollNotification(ScrollNotification notification) {
    switch (notification.runtimeType) {
      // 下面3个case的代码是安卓输入框实现iOS同等功能的逻辑, 顶部在滑上，底部再滑下的滚动处理逻辑 【仿微信、小红书的操作】
      case ScrollStartNotification:
        if (notification.depth == 0) {
          // 外层列表滚动则隐藏输入框
          if (MediaQuery.of(context).viewInsets.bottom != 0) {
            widget.focusChange?.call(false);
            FocusScope.of(context).unfocus();
          }
          if (controller.tabIndex.value == ToolbarIndex.emoji) {
            widget.focusChange?.call(false);
            controller.expand.value = KeyboardStatus.hide;
          }
          return false;
        } else if (notification.depth == 1 && UniversalPlatform.isAndroid) {
          // 记录内部输入框一开始滚动的位置
          _scrollStartPosition = notification.metrics.pixels;
        }
        break;
      case OverscrollNotification: //
        final _notification = notification as OverscrollNotification;
        if (notification.depth == 1 && UniversalPlatform.isAndroid) {
          if (_scrollStartPosition == 0 && _notification.overscroll < 0) {
            // 如果起始位置在顶部，并向顶部继续滚动的话，隐藏键盘
            widget.focusChange?.call(false);
            FocusScope.of(context).unfocus();
          } else if (_scrollStartPosition > 0 &&
              _notification.metrics.pixels == _scrollStartPosition &&
              _notification.overscroll > 0) {
            // 如果起始位置在底部，并向底部继续滚动的话，隐藏键盘
            widget.focusChange?.call(false);
            FocusScope.of(context).unfocus();
          }
        }
        break;
      case ScrollEndNotification: // 清空位置记录
        if (notification.depth == 1 && UniversalPlatform.isAndroid)
          _scrollStartPosition = -1;
        break;
      default:
        break;
    }

    return true;
  }

  Widget _nativeTextField() {
    return RichTextField(
      minHeight: 142,
      controller: controller.inputController.rawIosController,
      focusNode: controller.textFieldFocusNode,
      text: controller.inputController.data,
      textStyle: Theme.of(context)
          .textTheme
          .bodyText2
          .copyWith(fontSize: 16, height: 1.25),
      cursorColor: appThemeData.primaryColor,
      placeHolder: '分享你的精彩时刻…'.tr,
      placeHolderStyle: TextStyle(
          fontSize: 16,
          height: 1.25,
          color: appThemeData.iconTheme.color.withOpacity(0.4)),
      scrollFromBottomTop: () {
        // 从iOS原生，顶部在滑上，底部再滑下的滚动回调事件 【仿微信、小红书的操作】
        widget.focusChange?.call(false);
        controller.textFieldFocusNode.unfocus();
      },
    );
  }

  Widget _flutterTextField() {
    final child = RichInput(
      minLines: 3,
      enableSuggestions: false,
      controller: controller.inputController.rawFlutterController,
      focusNode: controller.textFieldFocusNode,
      keyboardType: TextInputType.multiline,
      maxLines: null,
      scrollPhysics: controller.textFieldFocusNode.hasFocus
          ? null
          : const NeverScrollableScrollPhysics(),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        hintText: '分享你的新鲜事'.tr,
        hintStyle: TextStyle(
            fontSize: 16,
            height: 1.25,
            color: appThemeData.iconTheme.color.withOpacity(0.4)),
        border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(20),
            gapPadding: 0),
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 142,
        minHeight: 142,
      ),
      child: child,
    );
  }

  void _nativeTextFieldFocusChange() {
    // 键盘有焦点 = textFieldFocus + emoji + at
    final bool hasFocus = controller.textFieldFocusNode.hasFocus ||
        controller.tabIndex.value == ToolbarIndex.emoji ||
        controller.tabIndex.value == ToolbarIndex.at ||
        controller.tabIndex.value == ToolbarIndex.channel;

    widget.focusChange?.call(hasFocus);

    /// MediaQuery.of(context).viewInsets.bottom == 0的时候，
    /// 通过键盘弹出的rebuild去构建页面能优化页面更新效果，不要使用setState和ValueListenerBuilder，不然卡顿会特别严重
    if (MediaQuery.of(context).viewInsets.bottom != 0 && mounted)
      setState(() {});
  }

  @override
  void initState() {
    controller.textFieldFocusNode.addListener(_nativeTextFieldFocusChange);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
        onNotification: _handleScrollNotification,
        child: SingleChildScrollView(
          controller: controller.scrollController,
          child: Container(
            color: Get.theme.backgroundColor,
            height: 142,
            child: controller.inputController.useNativeInput
                ? _nativeTextField()
                : _flutterTextField(),
          ),
        ));
  }

  @override
  void dispose() {
    controller.textFieldFocusNode.removeListener(_nativeTextFieldFocusChange);
    super.dispose();
  }
}
