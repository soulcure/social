///
/// @FilePath       : \social\lib\widgets\app_bar\appbar_action_button.dart
///
/// @Info           : 统一导航栏 - 右侧按钮实例对象
///
/// @Author         : Whiskee Chan
/// @Date           : 2021-12-14 16:44:09
/// @Version        : 1.0.0
///
/// Copyright 2021 iDreamSky FanBook, All Rights Reserved.
///
/// @LastEditors    : Whiskee Chan
/// @LastEditTime   : 2021-12-22 11:20:56
///
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/pages/home/components/red_dot.dart';
import 'package:im/themes/default_theme.dart';

import 'appbar_action_model.dart';

/// 核心 - 右侧按钮导航基类：仅提供顶层父类
abstract class AppBarActionButton<T extends AppBarActionModelInterface>
    extends StatelessWidget {
  // ====== Properties: Constant ====== //

  /// 按钮属性数据模型
  final T actionModel;

  const AppBarActionButton(this.actionModel, {Key key}) : super(key: key);

  // ====== Method: Override ====== //
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: actionModel.alpha,
        child: childView(context, actionModel),
      );

  // ====== Method: Abstract ====== //
  /// 返回子视图
  Widget childView(BuildContext context, T actionModel);

  // ====== Method: Public ====== //

  /// 组装视图：带有可选Loading的文字视图
  Widget assembleTextButtonWithLoading(BuildContext context, String text,
      bool isLoading, AppBarActionModelInterface actionModel) {
    return UnconstrainedBox(
      child: isLoading
          ? Container(
              alignment: Alignment.center,
              width: 60,
              child: DefaultTheme.defaultLoadingIndicator(
                  size: 8, color: Theme.of(context).disabledColor),
            )
          : FadeBackgroundButton(
              height: 32,
              backgroundColor: _getTextActionTypeBgColor(
                  actionModel.actionType, actionModel.isEnable),
              tapDownBackgroundColor:
                  _geTextActionTypeTapDownBgColor(actionModel.actionType),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: 5,
              onTap: !actionModel.isEnable
                  ? null
                  : () {
                      if (actionModel.actionBlock != null) {
                        actionModel.actionBlock();
                      }
                    },
              child: Text(text,
                  style: TextStyle(
                      fontSize:
                          actionModel.actionType == AppBarActionType.text_pure
                              ? 16
                              : 14,
                      color: _geTextActionTypeTextColor(
                          actionModel.actionType, actionModel.isEnable))),
            ),
    );
  }

  /// 获取：文字背景色
  Color _getTextActionTypeBgColor(AppBarActionType actionType, bool isEnable) {
    final Color primaryColor = Get.theme.primaryColor;
    final Color lightColor = Get.theme.primaryColor.withOpacity(0.15);
    final Color disableColor = Get.theme.disabledColor.withOpacity(0.15);
    switch (actionType) {
      case AppBarActionType.text_primary:
        return isEnable ? primaryColor : disableColor;
      case AppBarActionType.text_light:
        return isEnable ? lightColor : disableColor;
      default:
        return Colors.transparent;
    }
  }

  /// 获取：文字按钮点击时展示的背景色
  Color _geTextActionTypeTapDownBgColor(AppBarActionType actionType) {
    final Color disableColor = Get.theme.disabledColor.withOpacity(0.15);
    switch (actionType) {
      case AppBarActionType.text_primary:
      case AppBarActionType.text_light:
        return disableColor;
      default:
        return null;
    }
  }

  /// 获取：文字颜色
  Color _geTextActionTypeTextColor(AppBarActionType actionType, bool isEnable) {
    final Color primaryColor = Get.theme.primaryColor;
    final disableTextColor = Get.theme.disabledColor;
    switch (actionType) {
      case AppBarActionType.text_pure:
      case AppBarActionType.text_light:
        return isEnable ? primaryColor : disableTextColor;
      default:
        return isEnable ? Colors.white : disableTextColor;
    }
  }
}

/// 导航栏右侧按钮实例对象：纯文本按钮
class AppBarTextPureActionButton
    extends AppBarActionButton<AppBarTextPureActionModel> {
  /// 构造函数
  const AppBarTextPureActionButton(
      {Key key, @required AppBarTextPureActionModel actionModel})
      : super(actionModel, key: key);

  // ====== Override - Method: Parent ====== //
  @override
  Widget childView(
          BuildContext context, AppBarTextPureActionModel actionModel) =>
      assembleTextButtonWithLoading(
          context, actionModel.text, actionModel.isLoading, actionModel);
}

/// 导航栏右侧按钮实例对象：填充背景文字按钮
class AppBarTextPrimaryActionButton
    extends AppBarActionButton<AppBarTextPrimaryActionModel> {
  /// 构造函数
  const AppBarTextPrimaryActionButton(
      {Key key, @required AppBarTextPrimaryActionModel actionModel})
      : super(actionModel, key: key);

  /// ====== Override - Method: Parent ====== ///

  @override
  Widget childView(
          BuildContext context, AppBarTextPrimaryActionModel actionModel) =>
      Padding(
          padding: const EdgeInsets.only(right: 10),
          child: assembleTextButtonWithLoading(
              context, actionModel.text, actionModel.isLoading, actionModel));
}

/// 导航栏右侧按钮实例对象：浅色色背景文字按钮
class AppBarTextLightActionButton
    extends AppBarActionButton<AppBarTextLightActionModel> {
  /// 构造函数
  const AppBarTextLightActionButton(
      {Key key, @required AppBarTextLightActionModel actionModel})
      : super(actionModel, key: key);

  /// ====== Override - Method: Parent ====== ///

  @override
  Widget childView(
          BuildContext context, AppBarTextLightActionModel actionModel) =>
      Padding(
        padding: const EdgeInsets.only(right: 10),
        child: assembleTextButtonWithLoading(
            context, actionModel.text, actionModel.isLoading, actionModel),
      );
}

/// 导航栏右侧按钮实例对象：浅色色背景文字按钮
class AppBarIconActionButton extends AppBarActionButton<AppBarIconActionModel> {
  /// 构造函数
  const AppBarIconActionButton(
      {Key key, @required AppBarIconActionModel actionModel})
      : super(actionModel, key: key);

  /// ====== Override - Method: Parent ====== ///

  @override
  Widget childView(BuildContext context, AppBarIconActionModel actionModel) {
    //  计算视图宽度
    final double childSize = (actionModel.iconSize ?? 22) + 16.0;
    //  展示loading
    if (actionModel.isLoading) {
      return Container(
        alignment: Alignment.center,
        width: childSize,
        child: DefaultTheme.defaultLoadingIndicator(
          size: 8,
          color: Theme.of(context).disabledColor,
        ),
      );
    }
    //  展示图标
    final child = GestureDetector(
      onTap: actionModel.actionBlock,
      child: Container(
        color: Colors.transparent,
        width: childSize,
        height: 44,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 12),
        child: Icon(
          actionModel.icon,
          size: actionModel.iconSize ?? 22,
          color: actionModel.showColor ?? const Color(0xFF1F2125),
        ),
      ),
    );
    //  - 不带消息红点
    if (actionModel.unreadMsgNumListenable == null) {
      return child;
    }
    //  - 展示消息红点
    return UnconstrainedBox(
      child: ValueListenableBuilder(
        valueListenable: actionModel.unreadMsgNumListenable,
        builder: (_, value, __) {
          int unreadNum = 0;
          if (value is int) {
            unreadNum = value;
          }
          if (actionModel.selector != null) {
            unreadNum = actionModel.selector(value);
            unreadNum = unreadNum ?? 0;
          }
          if (actionModel.isShowRedDotWithNum) {
            double rdOffsetX = 15;
            if (unreadNum >= 10 && unreadNum < 100) {
              rdOffsetX = 13;
            } else if (unreadNum >= 100) {
              rdOffsetX = 7;
            }
            return RedDot(
              unreadNum,
              borderColor: Get.theme.backgroundColor,
              offset: Offset(rdOffsetX, 3),
              fontSize: 11,
              child: child,
            );
          }
          return RedDotFill(
            unreadNum,
            radius: 5,
            offset: const Offset(-4, 3),
            borderColor: Get.theme.backgroundColor,
            child: child,
          );
        },
      ),
    );
  }
}
