///
/// @FilePath       : \social\lib\widgets\app_bar\appbar_action_model.dart
///
/// @Info           : 统一导航栏 - 右侧按钮数据模型
///
/// @Author         : Whiskee Chan
/// @Date           : 2021-12-14 16:44:09
/// @Version        : 1.0.0
///
/// Copyright 2021 iDreamSky FanBook, All Rights Reserved.
///
/// @LastEditors    : Whiskee Chan
/// @LastEditTime   : 2021-12-22 11:29:00
///
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 别称： 右视图按钮回调
typedef AppBarActionCallBack = void Function();

/// 枚举类: 按钮类型
enum AppBarActionType {
  text_pure, // 纯文本按钮
  text_primary, // 背景填充模式文字按钮
  text_light, // 背景浅色模式文字按钮
  icon // 图标按钮
}

/// 核心 - 抽象类：基础属性抽取
abstract class AppBarActionModelInterface {
  /// 按钮类型
  AppBarActionType actionType;

  /// 按钮是否生效
  bool isEnable;

  //  是否需要Loading,默认为false，且仅为文字按钮的时候才有效
  bool isLoading;

  /// 透明值(0~1)
  double alpha;

  /// 按钮点击回调
  AppBarActionCallBack actionBlock;

  AppBarActionModelInterface(
    this.actionType, {
    this.isEnable,
    this.isLoading = false,
    this.alpha = 1,
    this.actionBlock,
  });
}

/// 导航栏右侧按钮：文字按钮
class AppBarTextPureActionModel extends AppBarActionModelInterface {
  // ====== Properties: Variable ====== //
  //  带展示的按钮文字
  String text;

  AppBarTextPureActionModel(
    this.text, {
    bool isLoading = false,
    bool isEnable = true,
    double alpha = 1,
    AppBarActionCallBack actionBlock,
  }) : super(
          AppBarActionType.text_pure,
          isEnable: isEnable,
          isLoading: isLoading,
          alpha: alpha,
          actionBlock: actionBlock,
        );
}

/// 导航栏右侧按钮：文字-背景填充按钮
class AppBarTextPrimaryActionModel extends AppBarActionModelInterface {
  // ====== Properties: Variable ====== //
  //  带展示的按钮文字
  String text;

  AppBarTextPrimaryActionModel(
    this.text, {
    bool isLoading = false,
    bool isEnable = true,
    double alpha = 1,
    AppBarActionCallBack actionBlock,
  }) : super(
          AppBarActionType.text_primary,
          isEnable: isEnable,
          isLoading: isLoading,
          alpha: alpha,
          actionBlock: actionBlock,
        );
}

/// 导航栏右侧按钮：文字-明亮色按钮
class AppBarTextLightActionModel extends AppBarActionModelInterface {
  // ====== Properties: Variable ====== //
  //  带展示的按钮文字
  String text;

  AppBarTextLightActionModel(
    this.text, {
    bool isLoading = false,
    bool isEnable = true,
    double alpha = 1,
    AppBarActionCallBack actionBlock,
  }) : super(
          AppBarActionType.text_light,
          isEnable: isEnable,
          isLoading: isLoading,
          alpha: alpha,
          actionBlock: actionBlock,
        );
}

/// 导航栏右侧按钮：图标按钮
class AppBarIconActionModel<T> extends AppBarActionModelInterface {
  // ====== Properties: Variable ====== //
  /// 图标按钮， 仅当actionType为icon生效
  IconData icon;

  /// 是否展示带数字的红点,默认展示不带数字的红点
  bool isShowRedDotWithNum;

  /// 展示的颜色
  Color showColor;

  /// 消息数量监听
  ValueListenable<T> unreadMsgNumListenable;

  /// 红点数量点击回调
  int Function(T) selector;

  /// 图标的size
  double iconSize;

  AppBarIconActionModel(this.icon,
      {double alpha = 1,
      this.isShowRedDotWithNum = false,
      this.showColor,
      this.unreadMsgNumListenable,
      this.selector,
      this.iconSize,
      bool isLoading = false,
      AppBarActionCallBack actionBlock})
      : super(
          AppBarActionType.icon,
          alpha: alpha,
          isLoading: isLoading,
          actionBlock: actionBlock,
        );
}
