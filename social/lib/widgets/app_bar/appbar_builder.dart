///
/// @FilePath       : \social\lib\widgets\app_bar\appbar_builder.dart
///
/// @Info           : 统一导航栏 - 导航栏实例对象
///
///   详细说明地址：[https://idreamsky.feishu.cn/wiki/wikcnmJykorYX6hIMGFUHl0Fvjf?lang=en-US&open_in_browser=true#]
///   UI设计稿地址：[https://lanhuapp.com/web/#/item/project/stage?pid=b9034065-7bef-426f-81d4-b61a4a02859f&type=share_mark&teamId=571650b3-d642-443d-a4d3-16e06bb525e9]
///   交互规范：    [https://idreamsky.feishu.cn/docs/doccnaacUT08IJq5gZKXPGwcsbc]
///
/// @Author         : Whiskee Chan
/// @Date           : 2021-12-17 14:34:37
/// @Version        : 1.0.0
///
/// Copyright 2021 iDreamSky FanBook, All Rights Reserved.
///
/// @LastEditors    : Whiskee Chan
/// @LastEditTime   : 2021-12-22 10:35:46
///
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:just_throttle_it/just_throttle_it.dart';

import '../../icon_font.dart';
import 'appbar_action_button.dart';

/// - 全局常量 - AppBar高度
const double kFbAppBarHeight = 44;
//  自定义别称：
/// - 标题栏左视图创建函数
typedef AppBarLeadingBuilder = Widget Function(Icon);

/// - 标题栏左视图回调: 当 bool 为 false 时 调用 组件实现的返回方法，如果为true时，实现回调内的方法
typedef AppBarLeadingCallBack = bool Function();

/// - 标题栏标题视图函数
typedef AppBarTitleBuilder = Widget Function(BuildContext context, TextStyle);

/// - 标题栏右边按钮视图函数
typedef AppBarActionsBuilder = List<Widget> Function(BuildContext context);

/// 标题栏创建基类:
abstract class BaseAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  // ====== Properties: Private   ====== //

  // ====== Properties: Variable ====== //

  /// 基础属性：是否需要状态栏的安全边距
  final bool isNeedStatusBarPadding;

  /// 基础属性：背景色；默认：Get.theme.backgroundColor
  final Color backgroundColor;

  /// 左视图：不展示
  final bool hideLeading;

  /// 左视图: 图标；默认IconFont.buffNavBarBackItem;
  /// - 说明：原则上不使用该参数替换做左侧视图的样式，为了防止以后的要求变更跟，暂时保留
  final IconData leadingIcon;

  /// 左侧按钮是否白色，默认黑色
  final bool setLeadingIconWhite;

  /// 左侧视图：左侧视图宽度(最小宽度等于kFbAppBarHeight)， 仅当leadingBuilder ！= null 时生效
  final double leadingWidth;

  /// 左视图：自定义视图，当leadingBuilder != null时，优先展示
  final AppBarLeadingBuilder leadingBuilder;

  /// 左视图：回调监听; leadingBuilder != null, 覆盖返回事件，回调return一个bool值
  final AppBarLeadingCallBack leadingCallback;

  /// 左视图：展示消息数量;
  final ValueListenable<int> leadingShowMsgNum;

  /// 左视图：页面步进数 - 在特定需求下，某些页面需要在同个页面展示不同内容（效果如分页）：
  /// - 1、默认为空（或小于0），由系统判断
  /// - 2、为0时，展示关闭按钮
  /// - 3、大于0时，展示返回按钮
  final int pageStep;

  /// 标题视图：标题
  final String title;

  /// 标题视图：标题是否居中；默认居中，如果为false则靠左对齐
  final bool isCenterTitle;

  /// 标题视图：自定义标题视图，当titleBuilder != null时，优先展示
  final AppBarTitleBuilder titleBuilder;

  /// 右视图：按钮组属性创建模型集合，规则如下：
  /// - 1、类型为Text_**的仅支持创建一个
  /// - 2、类型为Icon的具体视业务需求而创建任意数量，上限2个
  /// - 3、由于目前仅支持单一类型，传入多个时，如果类型有Text和Icon，不会创建成功
  final List<AppBarActionModelInterface> actions;

  /// 基础属性：底部阴影高度；默认0
  final double elevation;

  /// 标题栏右边按钮视图函数
  final AppBarActionsBuilder actionsBuilder;

  ///
  const BaseAppBar({
    Key key,
    this.isNeedStatusBarPadding = true,
    this.backgroundColor,
    this.elevation = 0,
    this.hideLeading = false,
    this.leadingIcon,
    this.setLeadingIconWhite = false,
    this.leadingWidth = kFbAppBarHeight + 4,
    this.leadingBuilder,
    this.leadingCallback,
    this.leadingShowMsgNum,
    this.pageStep = -1,
    this.title,
    this.titleBuilder,
    this.isCenterTitle = true,
    this.actions,
    this.actionsBuilder,
  }) : super(
          key: key,
        );

  // ====== Override - Method: Parent ====== //

  @override
  Widget build(BuildContext context) {
    //  展示右侧按钮
    final List<Widget> showActions =
        actionsBuilder != null ? actionsBuilder(context) : actionButtons();
    //  匿名函数：组装AppBar
    //  - params: leadingWidth 右侧按钮宽度
    AppBar assembleAppBar(double leadingWidth) => AppBar(
        primary: isNeedStatusBarPadding,
        toolbarHeight: preferredSize.height,
        automaticallyImplyLeading: !hideLeading,
        backgroundColor: backgroundColor ?? Get.theme.backgroundColor,
        elevation: elevation,
        leadingWidth: leadingWidth,
        leading: hideLeading ? null : leadingView(context, leadingWidth),
        title: titleView(context),
        titleSpacing: 0,
        centerTitle: isCenterTitle,
        actions: showActions);
    return leadingShowMsgNum == null
        ? assembleAppBar(leadingWidth)
        : ValueListenableBuilder(
            valueListenable: leadingShowMsgNum,
            builder: (context, msgNum, child) {
              //  系统默认44宽度
              double numWidth = 0;
              //  - 根据数量大小计算左边距数量
              if (msgNum > 0 && msgNum < 10) {
                numWidth = 18;
              } else if (msgNum >= 10 && msgNum < 100) {
                numWidth = 25;
              } else if (msgNum >= 100) {
                numWidth = 34;
              }
              return assembleAppBar(leadingWidth + numWidth);
            },
          );
  }

  // ====== Override - Proprieties: PreferredSizeWidget ====== //

  @override
  Size get preferredSize => const Size.fromHeight(kFbAppBarHeight);

  // ====== Method: Abstract ====== //
  /// 左侧视图
  Widget leadingView(BuildContext context, double width);

  /// 标题视图
  Widget titleView(BuildContext context);

  /// 右侧视图
  List<Widget> actionButtons();
}

/// 标题栏实体对象，基于UI规范实现
class FbAppBar extends BaseAppBar {
  /// 构造函数：左侧按钮监听捕获，展示标题，标题展示位置，右侧按钮展示
  const FbAppBar.custom(
    String title, {
    Key key,
    Color backgroundColor = Colors.white,
    AppBarLeadingCallBack leadingBlock,
    //  设置左侧按钮为白色，不设置为黑色
    bool setLeadingIconWhite = false,
    ValueListenable<int> leadingShowMsgNum,
    bool isCenterTitle = true,
    List<AppBarActionModelInterface> actions,
  }) : super(
          key: key,
          backgroundColor: backgroundColor,
          leadingCallback: leadingBlock,
          leadingShowMsgNum: leadingShowMsgNum,
          setLeadingIconWhite: setLeadingIconWhite,
          title: title,
          isCenterTitle: isCenterTitle,
          actions: actions,
        );

  /// 构造函数：无左侧按钮，展示标题，右侧按钮展示
  FbAppBar.noLeading(
    String title, {
    Key key,
    List<AppBarActionModelInterface> actions,
  }) : super(
          key: key,
          hideLeading: true,
          titleBuilder: (context, style) => Container(
            alignment: Alignment.centerLeft,
            margin: const EdgeInsets.only(left: 12),
            child: Text(title,
                textAlign: TextAlign.left,
                style: TextStyle(
                    color: style.color,
                    fontSize: 20,
                    fontWeight: style.fontWeight)),
          ),
          isCenterTitle: false,
          actions: actions,
        );

  /// 构造函数：圈子详情专属
  const FbAppBar.circleInfo({
    Key key,
    AppBarLeadingCallBack leadingBlock,
    ValueListenable<int> leadingShowMsgNum,
    AppBarTitleBuilder titleBuilder,
    AppBarActionsBuilder actionsBuilder,
  }) : super(
          key: key,
          leadingCallback: leadingBlock,
          leadingShowMsgNum: leadingShowMsgNum,
          titleBuilder: titleBuilder,
          actionsBuilder: actionsBuilder,
        );

  /// 构造函数：合作伙伴专属
  FbAppBar.partners(
    String title, {
    Key key,

    /// 合作描述(des = describe)
    @required String brandDes,

    /// 合作品牌Logo地址
    @required String brandLogoUrl,

    /// 合作品牌名称
    @required String brandName,
    AppBarLeadingCallBack leadingBlock,
    ValueListenable<int> leadingShowMsgNum,
    VoidCallback showMoreMenuBlock,
  }) : super(
          key: key,
          leadingCallback: leadingBlock,
          leadingShowMsgNum: leadingShowMsgNum,
          titleBuilder: (context, style) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: style),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(brandDes,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                            color: Get.theme.disabledColor, fontSize: 11)),
                    SizedBox(width: sizeWidth2.width),
                    Padding(
                      padding: EdgeInsets.only(top: sizeHeight2.height),
                      child: ImageWidget.fromCachedNet(CachedImageBuilder(
                          cacheManager: CustomCacheManager.instance,
                          imageUrl: brandLogoUrl,
                          width: 13,
                          height: 13,
                          fit: BoxFit.fill)),
                    ),
                    const SizedBox(width: 1),
                    Text(
                      brandName,
                      style: TextStyle(
                        color: style.color,
                        fontSize: 10,
                      ),
                    ),
                  ],
                )
              ],
            );
          },
          actions: [
            AppBarIconActionModel(IconFont.buffMoreHorizontal, actionBlock: () {
              showMoreMenuBlock();
            })
          ],
        );

  /// 构造函数：带下拉图标展示的标题栏
  FbAppBar.withArrow(
    String title, {
    Key key,
    AppBarLeadingCallBack leadingBlock,

    /// 箭头方向；true = 向下， false = 向上
    @required bool isArrowDown,

    /// 回调监听：下拉/上收事件
    @required Function(bool) arrowDirectionBlock,
    List<AppBarActionModelInterface> actions,
  }) : super(
          key: key,
          leadingCallback: leadingBlock,
          titleBuilder: (context, style) => GestureDetector(
            onTap: () {
              arrowDirectionBlock(!isArrowDown);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: style),
                Transform.rotate(
                  // 旋转180度
                  angle: isArrowDown ? 0 : math.pi,
                  child: const Align(
                    child: Icon(IconFont.buffFilePullDown, size: 20),
                  ),
                ),
              ],
            ),
          ),
          actions: actions,
        );

  /// 构造函数：左侧按钮监听捕获，自定义标题，右侧按钮展示
  const FbAppBar.diyTitleView({
    Key key,
    int pageStep,
    IconData leadingIcon,
    bool hideLeading = false,
    AppBarLeadingCallBack leadingBlock,
    ValueListenable<int> leadingShowMsgNum,
    AppBarTitleBuilder titleBuilder,
    List<AppBarActionModelInterface> actions,
  }) : super(
          key: key,
          pageStep: pageStep,
          leadingIcon: leadingIcon,
          hideLeading: hideLeading,
          leadingCallback: leadingBlock,
          leadingShowMsgNum: leadingShowMsgNum,
          titleBuilder: titleBuilder,
          actions: actions,
        );

  /// 构造函数：适用于底部弹窗展示用
  const FbAppBar.forSheet(
    String title, {
    Key key,

    /// 页面步进数：在特定需求下，某些页面需要在同个页面展示不同内容（效果如分页），当stepCount为0时，展示关闭按钮，不为0时，展示返回按钮
    int pageStep,
    AppBarLeadingCallBack leadingBlock,
    List<AppBarActionModelInterface> actions,
  }) : super(
          key: key,
          isNeedStatusBarPadding: false,
          pageStep: pageStep,
          leadingCallback: leadingBlock,
          title: title,
          actions: actions,
        );

  // ====== Override Method: Parent ====== //

  /// 组装：左视图
  /// - 优先判断是否采用leadingBuilder，否则使用默认Icon视图
  @override
  Widget leadingView(BuildContext context, double width) {
    /// 匿名方法：根据路由类型，返回正确左侧视图：返回或关闭
    IconData getLeadingIcon() {
      //  - 1、步进数判断：
      if (pageStep != null && pageStep >= 0) {
        return pageStep == 0
            ? IconFont.buffNavBarCloseItem
            : IconFont.buffNavBarBackItem;
      }
      //  - 2、路由判断：
      final ModalRoute<dynamic> parentRoute = ModalRoute.of(context);
      if (parentRoute == null) return IconFont.buffNavBarBackItem;
      final bool useCloseButton =
          parentRoute is PageRoute<dynamic> && parentRoute.fullscreenDialog;
      return useCloseButton
          ? IconFont.buffNavBarCloseItem
          : IconFont.buffNavBarBackItem;
    }

    //  创建相应图标
    final Icon icon = Icon(
      leadingIcon ?? getLeadingIcon(),
      size: 22,
      color: setLeadingIconWhite ? Colors.white : Colors.black,
    );
    final leadingView = (leadingBuilder != null && leadingBuilder(icon) != null)
        ? leadingBuilder(icon)
        : Padding(
            padding: const EdgeInsets.only(left: 12),
            child: icon,
          );
    return GestureDetector(
      onTap: () {
        /// NOTE(jp@jin.dev): 2022/6/1 谁实现路由跳转、谁就做防抖
        if (leadingCallback == null || !leadingCallback()) {
          Throttle.milliseconds(500, Navigator.of(context).maybePop);
        }
      },
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: width,
        child: Row(
          children: [
            leadingView,
            if (leadingShowMsgNum != null)
              ValueListenableBuilder(
                valueListenable: leadingShowMsgNum,
                builder: (context, value, child) =>
                    _assembleMsgNumView(context, value),
              )
          ],
        ),
      ),
    );
  }

  /// 组装：标题视图
  /// - 1、优先判断是否采用titleBuilder，否则使用默认标题格式
  /// - 2、为了统一导航栏通用性，标题的属性不允许自定义，所以不开放TextStyle修改
  @override
  Widget titleView(BuildContext context) => titleBuilder != null
      ? titleBuilder(context, Get.theme.textTheme.headline5)
      : Text(title ?? '',
          style: Get.theme.textTheme.headline5,
          overflow: TextOverflow.ellipsis);

  /// 右视图：可展示按钮组
  @override
  List<Widget> actionButtons() {
    /// 根据传入的actions创建对应的AppBarButton
    if (actions == null || actions.isEmpty) return [];
    //  1、限制混用不同类型action button
    //  - 1.1、只判断大于一个以上的组件
    if (actions.length > 1 && OrientationUtil.portrait) {
      //  - 1.2、只要是文字按钮的都不允许存在多个以上
      final AppBarActionType firstActionType = actions.first.actionType;
      assert(firstActionType == AppBarActionType.icon,
          "AppBarBuilder - actions : Only icon allow to create more than one");
      // - 1.3、如果在图标类型的按钮混入了文字按钮也不允许创建
      assert(
          (() => actions
              .every((action) => action.actionType == firstActionType))(),
          "AppBarBuilder - actions : The actions are not the same type, please check it carefully");
    }
    //  2、执行遍历，创建对应类型的按钮并添加至按钮集合中
    final List<Widget> actionBtns = [];
    for (var i = 0; i < actions.length; i++) {
      final AppBarActionModelInterface action = actions[i];
      switch (action.actionType) {
        case AppBarActionType.text_pure:
          actionBtns.add(AppBarTextPureActionButton(actionModel: action));
          break;
        case AppBarActionType.text_primary:
          actionBtns.add(AppBarTextPrimaryActionButton(actionModel: action));
          break;
        case AppBarActionType.text_light:
          actionBtns.add(AppBarTextLightActionButton(actionModel: action));
          break;
        case AppBarActionType.icon:
          actionBtns.add(AppBarIconActionButton(actionModel: action));
          break;
        default:
          break;
      }
    }
    return [...actionBtns, sizeWidth2];
  }

  // ====== Method: Private ====== //

  /// 组装：消息数量展示视图
  Widget _assembleMsgNumView(BuildContext context, int msgNum) {
    String valueStr = "$msgNum";
    if (msgNum >= 100) {
      valueStr = "99+";
    }
    //  2、如果实现了监听就展示消息数量
    return msgNum <= 0
        ? const SizedBox()
        : Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(minWidth: 22, maxHeight: 22),
            decoration: BoxDecoration(
              color: appThemeData.dividerColor.withOpacity(0.15),
              borderRadius: const BorderRadius.all(Radius.circular(11)),
            ),
            margin: const EdgeInsets.only(left: 2, right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              valueStr,
              style: TextStyle(
                color: appThemeData.textTheme.caption.color,
                height: 1.25,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
  }
}
