// ignore_for_file: must_be_immutable

/*
 * @FilePath       : /social/lib/widgets/fb_ui_kit/form/form_builder.dart
 * 
 * @Info           : 统一组件：表单
 * 
 * ///   详细说明地址： [待补充]
 * ///   UI设计稿地址： [https://lanhuapp.com/web/#/item/project/detailDetach?pid=5218aaca-eb1f-445b-acc9-84885113b30b&image_id=43088c96-d845-475d-9218-abfbcb1dfaf3&project_id=5218aaca-eb1f-445b-acc9-84885113b30b&fromEditor=true]
 * ///   交互规范：    [https://idreamsky.feishu.cn/wiki/wikcn1JqxPhAlhcDMNbsUVFkxKf]
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2022-02-23 15:55:35
 * @Version        : 1.0.0
 * 
 * Copyright 2022 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2022-03-01 16:18:07
 * 
 */

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_colors.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/fb_ui_kit/form/form_fix_child_model.dart';
import 'package:im/widgets/text_field/native_input.dart';

/// 全局静态参数
//  最小高度
const double kFbFormSizeMin = 52;
//  子组件间边距: 垂直距离
const SizedBox kFbFormChildHMargin = SizedBox(height: 5);
//  子组件间边距：水平距离
const SizedBox kFbFormChildWSideMargin = SizedBox(width: 16);
//  子组件间边距：水平距离
const SizedBox kFbFormChildWMinMargin = SizedBox(width: 5);

///  枚举 - 表单位置
enum FbFormPosition {
  singleLine, // 独立一行
  top, // 顶部
  middle, // 中间
  bottom, // 底部
}

///  枚举 - 操作类型
enum FbFormOperationType {
  none, // 无操作
  check, // 复选框
  radio, // 单选框
  delete, // 删除
}

// 核心类
abstract class _BaseForm extends StatelessWidget {
  // ====== Properties: Constant ====== //
  //  位置：根据位置不同会修改某些样式
  final FbFormPosition position;

  //  操作类型
  final FbFormOperationType operation;

  //  点击事件
  final VoidCallback onTap;

  // ====== Properties: Private ====== //
  //  背景色
  final ValueNotifier _bgColorVN = ValueNotifier(Colors.white);

  //  是否需要分割线
  bool get _isNeedDivideLine =>
      position != FbFormPosition.singleLine &&
      position != FbFormPosition.bottom;

  //  防止重复点击
  bool _isOnTap = false;

  _BaseForm({
    Key key,
    this.position = FbFormPosition.singleLine,
    this.operation = FbFormOperationType.none,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          if (onTap == null || _isOnTap) {
            return;
          }
          _isOnTap = true;
          Future.delayed(
            const Duration(
              milliseconds: 300,
            ),
          ).whenComplete(() {
            _isOnTap = false;
            onTap();
          });
        },
        onTapCancel: () => _bgColorVN.value = Colors.white,
        onTapDown: (details) {
          _bgColorVN.value = Color.alphaBlend(
              appThemeData.scaffoldBackgroundColor.withOpacity(0.5),
              Colors.white);
        },
        onTapUp: (details) => _bgColorVN.value = Colors.white,
        onLongPressUp: () => _bgColorVN.value = Colors.white,
        child: ValueListenableBuilder(
          valueListenable: _bgColorVN,
          builder: (context, value, child) => Container(
              decoration: BoxDecoration(
                color: value,
                borderRadius: _getBorderRadius(),
              ),
              margin: EdgeInsets.symmetric(
                horizontal: sizeWidth12.width,
              ),
              padding: EdgeInsets.only(
                left: kFbFormChildWSideMargin.width,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    flex: 0,
                    child: prefixChild(),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          constraints: const BoxConstraints(
                            minHeight: kFbFormSizeMin,
                          ),
                          padding: EdgeInsets.only(
                            top: 10,
                            bottom: _isNeedDivideLine ? 9.5 : 10,
                          ),
                          child: Row(
                            children: [
                              Flexible(
                                fit: FlexFit.tight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    mainChild(),
                                    subMainChild(),
                                  ],
                                ),
                              ),
                              Flexible(
                                flex: 0,
                                child: suffixChild(),
                              ),
                              Flexible(
                                flex: 0,
                                child: tailChild(),
                              ),
                            ],
                          ),
                        ),
                        if (_isNeedDivideLine) ...[
                          Container(
                            height: 0.5,
                            color: appThemeData.disabledColor.withOpacity(0.1),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              )),
        ),
      );

  // ====== Method: abstract ====== //
  /// 前缀视图
  Widget prefixChild();

  /// 主视图
  Widget mainChild();

  /// 子视图
  Widget subMainChild();

  /// 后缀视图
  Widget suffixChild();

  /// 尾部视图
  Widget tailChild();

  // ====== Method: Private ====== //

  /// 根据位置展示圆角
  BorderRadius _getBorderRadius() {
    const Radius radius = Radius.circular(6);
    switch (position) {
      case FbFormPosition.top:
        return const BorderRadius.vertical(top: radius);
      case FbFormPosition.middle:
        return const BorderRadius.all(Radius.zero);
      case FbFormPosition.bottom:
        return const BorderRadius.vertical(bottom: radius);
      default:
        return const BorderRadius.all(radius);
    }
  }
}

//  统一表单实例
class FbForm extends _BaseForm {
  // ====== Properties: Constant ====== //
  //  主要展示文案
  final String label;

  //  子视图文案
  final String subLabel;

  //  是否展示箭头
  final bool isShowArrow;

  // ====== Properties: Private ====== //
  // 是否需要展示子文本
  bool get isShowSubLabel => subLabel != null && subLabel.isNotEmpty;

  FbForm(
    this.label, {
    Key key,
    FbFormPosition position = FbFormPosition.singleLine,
    this.subLabel,
    this.isShowArrow = true,
    VoidCallback onTap,
  }) : super(key: key, position: position, onTap: onTap);

  // 工厂模式：基础样式
  factory FbForm.common(
    String label, {
    Key key,
    FbFormPosition position,
    FbFormPrefixChildModel prefixChildModel,
    String subLabel,
    FbFormSuffixChildModel suffixChildModel,
    //  是否显示箭头
    bool isShowArrow,
    //  脚视图：图标
    IconData tailIcon,
    //  脚视图：大小
    double tailIconSize,
    //  脚视图：颜色
    Color tailIconColor,
    VoidCallback onTap,
  }) = _FbCommonForm;

  // 工厂模式： 滑动开关 （脚视图）
  factory FbForm.wSwitch(
    String label, {
    Key key,
    FbFormPosition position,
    FbFormPrefixChildModel prefixChildModel,
    FbFormIconSuffixChild iconSuffixChild,
    String subLabel,
    bool isOn,
    Color activeColor,
    @required Function(bool) onChanged,
  }) = _FbSwitchForm;

  // 工厂模式： 输入框
  factory FbForm.input({
    Key key,
    bool isReadOnly,
    FocusNode focusNode,
    FbFormPosition position,
    String text,
    String hintText,
    int limit,
    bool isShowMoreLine,
    @required Function(String) onOutput,
  }) = _FbInputForm;

  // 工厂模式： 类按钮点击表单
  factory FbForm.click(
    String text, {
    Key key,
    Color textColor,
    bool isLoading,
    @required VoidCallback onClick,
  }) = _FbClickForm;

  // ====== Method: _BaseForm Override ====== //

  @override
  Widget prefixChild() => const SizedBox();

  @override
  Widget mainChild() => assembleMainLabel();

  @override
  Widget subMainChild() => isShowSubLabel
      ? Column(
          children: [
            kFbFormChildHMargin,
            assembleSubLabel(),
          ],
        )
      : const SizedBox();

  @override
  Widget suffixChild() => const SizedBox();

  @override
  Widget tailChild() => isShowArrow == true
      ? Row(
          children: [
            Icon(
              IconFont.buffXiayibu,
              size: 16,
              color: appThemeData.iconTheme.color.withOpacity(0.4),
            ),
            kFbFormChildWSideMargin,
          ],
        )
      : const SizedBox();

  // ====== Method: Public ====== //
  /// 组装主文本
  Text assembleMainLabel() => Text(
        label,
        maxLines: 2,
        style: TextStyle(
          color: appThemeData.textTheme.bodyText1.color,
          fontSize: 16,
          height: 1.25,
        ),
      );

  /// 组装子文本
  Text assembleSubLabel() => Text(
        subLabel,
        style: TextStyle(
          color: Get.theme.disabledColor,
          fontSize: 14,
        ),
      );
}

//  统一表单：基础样式
class _FbCommonForm extends FbForm {
  // ====== Properties: Constant ====== //
  //  前缀头视图：
  FbFormPrefixChildModel prefixChildModel;

  //  后缀视图：
  FbFormSuffixChildModel suffixChildModel;

  //  脚视图：图标
  final IconData tailIcon;

  //  脚视图：大小
  final double tailIconSize;

  //  脚视图：颜色
  final Color tailIconColor;

  // ====== Properties: Private ====== //

  _FbCommonForm(
    String label, {
    Key key,
    FbFormPosition position = FbFormPosition.singleLine,
    this.prefixChildModel,
    String subLabel,
    this.suffixChildModel,
    //  是否展示箭头，如果tailIcon不为空，展示tailIcon
    bool isShowArrow = true,
    //  脚视图图标
    this.tailIcon,
    this.tailIconSize,
    this.tailIconColor,
    VoidCallback onTap,
  }) : super(label,
            key: key,
            position: position,
            subLabel: subLabel,
            isShowArrow: isShowArrow,
            onTap: onTap);

  @override
  Widget prefixChild() => prefixChildModel == null
      ? super.prefixChild()
      : Row(
          children: [
            prefixChildModel.prefixChild(),
            kFbFormChildWMinMargin,
          ],
        );

  @override
  Widget suffixChild() => suffixChildModel == null
      ? super.suffixChild()
      : Row(
          children: [
            kFbFormChildWMinMargin,
            suffixChildModel.suffixChild(),
            if (tailIcon != null || isShowArrow == true)
              kFbFormChildWMinMargin
            else
              kFbFormChildWSideMargin
          ],
        );

  @override
  Widget tailChild() => tailIcon != null
      ? Row(
          children: [
            Icon(
              tailIcon,
              size: tailIconSize ?? 20,
              color: tailIconColor ??
                  appThemeData.iconTheme.color.withOpacity(0.4),
            ),
            kFbFormChildWSideMargin,
          ],
        )
      : super.tailChild();
}

//  统一表单：文本 + 开关
class _FbSwitchForm extends FbForm {
  // ====== Properties: Constant ====== //
  //  前缀视图
  FbFormPrefixChildModel prefixChildModel;

  //  后缀视图
  FbFormIconSuffixChild iconSuffixChild;

  //  开关为开时颜色
  final Color activeColor;

  //  是否打开开关
  final bool isOn;

  //  开关切换监听
  final Function(bool) onChanged;

  // ====== Properties: Private ====== //

  _FbSwitchForm(
    String label, {
    Key key,
    FbFormPosition position = FbFormPosition.singleLine,
    this.prefixChildModel,
    this.iconSuffixChild,
    String subLabel,
    this.isOn = false,
    this.activeColor,
    @required this.onChanged,
  }) : super(
          label,
          key: key,
          position: position,
          subLabel: subLabel,
          isShowArrow: false,
        );

  @override
  Widget prefixChild() => prefixChildModel == null
      ? super.prefixChild()
      : Row(
          children: [
            prefixChildModel.prefixChild(),
            kFbFormChildWMinMargin,
          ],
        );

  @override
  Widget mainChild() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(fit: FlexFit.tight, child: assembleMainLabel()),
          if (iconSuffixChild != null) ...[
            kFbFormChildWMinMargin,
            iconSuffixChild.suffixChild(),
          ],
          Transform.scale(
            scale: 0.8,
            child: CupertinoSwitch(
              activeColor: activeColor ?? Get.theme.primaryColor,
              value: isOn,
              onChanged: onChanged,
            ),
          ),
          kFbFormChildWMinMargin,
        ],
      );
}

//  统一表单：输入框
class _FbInputForm extends FbForm {
  // ====== Properties: Constant ====== //
  //  是否只读
  final bool isReadOnly;

  //  焦点
  final FocusNode focusNode;

  //  占位文字
  final String hintText;

  //  最大长度
  final int limit;

  //  展示多行
  final bool isShowMoreLine;

  //  开关切换监听
  final Function(String) onOutput;

  // ====== Properties: Private ====== //
  //  文本控制器
  TextEditingController _controller;

  //  长度监听
  ValueNotifier _lengthVN;

  _FbInputForm({
    Key key,
    FbFormPosition position = FbFormPosition.singleLine,
    this.isReadOnly = false,
    this.focusNode,
    String text,
    this.hintText = "",
    this.limit = 30,
    this.isShowMoreLine = false,
    @required this.onOutput,
  }) : super(
          "",
          key: key,
          position: position,
          isShowArrow: false,
        ) {
    //  初始化
    final String showText = text ?? "";
    _controller = TextEditingController(text: showText);
    _lengthVN = ValueNotifier(showText.length);
  }

  @override
  Widget mainChild() => _assembleTextFiled();

  @override
  Widget subMainChild() =>
      isShowMoreLine ? _assembleLimitLabel() : super.subMainChild();

  @override
  Widget tailChild() => Row(
        children: [
          if (!isShowMoreLine) ...[
            _assembleLimitLabel(),
          ],
          kFbFormChildWSideMargin,
        ],
      );

  // ====== Method: Private ====== //

  /// 组装视图：输入框
  Widget _assembleTextFiled() => Container(
        key: Key(isShowMoreLine ? "MultiLine" : "SingleLine"),
        color: Colors.transparent,
        child: NativeInput(
          height: isShowMoreLine ? 125 : 25,
          readOnly: isReadOnly,
          focusNode: focusNode,
          controller: _controller,
          decoration: InputDecoration.collapsed(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 16,
              color: appThemeData.textTheme.headline2.color,
            ),
          ),
          maxLengthEnforcement:
              MaxLengthEnforcement.truncateAfterCompositionEnds,
          maxLength: limit,
          maxLines: isShowMoreLine ? 4 : 1,
          onChanged: (text) {
            _lengthVN.value = text.length;
            onOutput(text);
          },
          onEditingComplete: () {
            onOutput(_controller.text);
          },
          buildCounter: (context, {currentLength, isFocused, maxLength}) =>
              const SizedBox(),
        ),
      );

  /// 组装视图：限制数字展示文本
  Widget _assembleLimitLabel() => ValueListenableBuilder(
        valueListenable: _lengthVN,
        builder: (context, value, child) => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!isShowMoreLine && value > 0) ...[
              kFbFormChildWMinMargin,
              GestureDetector(
                onTap: () {
                  _controller.clear();
                  _lengthVN.value = 0;
                  onOutput(_controller.text);
                },
                child: const Icon(
                  IconFont.buffClose,
                  size: 16,
                  color: clearColor,
                ),
              ),
              kFbFormChildWMinMargin,
            ],
            Text.rich(
              TextSpan(
                text: "$value",
                style: TextStyle(
                  fontSize: 14,
                  color: value > limit
                      ? Get.theme.errorColor
                      : appThemeData.textTheme.headline2.color,
                ),
                children: [
                  TextSpan(
                    text: "/$limit",
                    style: TextStyle(
                      fontSize: 14,
                      color: appThemeData.textTheme.headline2.color,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      );
}

//  统一表单：类按钮点击表单
class _FbClickForm extends FbForm {
  //  文本颜色
  Color textColor;

  // 是否展示加载圈
  bool isLoading;

  //  点击事件
  VoidCallback onClick;

  _FbClickForm(
    String text, {
    Key key,
    this.textColor,
    this.isLoading = false,
    @required this.onClick,
  }) : super(
          text,
          key: key,
          isShowArrow: false,
          onTap: onClick,
        );

  @override
  Widget mainChild() {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                backgroundColor: Colors.white,
                strokeWidth: 1.5,
              ),
            )
          : Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor ?? appThemeData.primaryColor,
              ),
            ),
    );
  }
}
