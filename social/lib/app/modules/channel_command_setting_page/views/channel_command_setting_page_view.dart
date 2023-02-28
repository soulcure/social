import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/app/modules/circle/views/portrait/widgets/custom_tabbar_indicator.dart';
import 'package:im/app/routes/app_pages.dart' as get_pages;
import 'package:im/app/theme/app_colors.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/bot_market/model/robot_model.dart';
import 'package:im/pages/bot_market/widget/add_button.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/refresh/common_error_widget.dart';
import 'package:im/widgets/svg_tip_widget.dart';

import '../../../../svg_icons.dart';
import '../controllers/channel_command_setting_page_controller.dart';

// 标题高度
const double _titleHeight = 37;
// CommandItem的高度
const double _addedItemHeight = 52;

class ChannelCommandSettingPageView
    extends GetView<ChannelCommandSettingPageController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appThemeData.backgroundColor,
      appBar: FbAppBar.custom(
        '频道快捷指令'.tr,
        backgroundColor: appThemeData.backgroundColor,
        actions: controller.actionModels,
      ),
      body: _buildBody(context),
    );
  }

  // 置顶栏的高度（_titleHeight + 边距 + (已添加机器人为空 ? 已添加机器人行高度 : 0);）
  double get _pinWidgetHeight =>
      _titleHeight + 6 + (controller.addedRobots.isNotEmpty ? 98 : 0);

  EdgeInsets _getSafePadding({double padding = 80}) {
    return EdgeInsets.only(bottom: padding, top: _pinWidgetHeight + padding);
  }

  // 未添加指令视图
  Widget _noAddedCmdView() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Container(
        alignment: Alignment.center,
        height: 52,
        // decoration: DottedDecoration(
        //   shape: Shape.box,
        //   color: appThemeData.textTheme.headline2.color,
        //   strokeWidth: 0.5,
        //   dash: const [3, 3],
        //   borderRadius: BorderRadius.circular(6.5),
        // ),
        child: Text(
          '暂无快捷指令，点击下方添加'.tr,
          style: TextStyle(
            fontSize: 14,
            color: appThemeData.textTheme.headline2.color,
          ),
        ),
      ),
    );
  }

  // 未添加机器人视图
  Widget _noAddedBotView() {
    return _buildScrollView(
      child: Padding(
        padding: _getSafePadding(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgTipWidget(
              svgName: SvgIcons.nullState,
              desc: '暂未添加机器人'.tr,
            ),
            sizeHeight32,
            FadeButton(
              width: 180,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.5),
                color: primaryColor,
              ),
              onTap: () async {
                await Get.toNamed(get_pages.Routes.BOT_MARKET_PAGE);
                await controller.initPage();
              },
              child: Text(
                '添加机器人'.tr,
                style: TextStyle(
                  fontSize: 14,
                  color: Get.theme.backgroundColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return GetBuilder<ChannelCommandSettingPageController>(
        builder: (controller) {
      return controller.obx(
        (state) {
          return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return _buildSliverAppBar(context, controller);
              },
              body: controller.addedRobots.isEmpty
                  ? _noAddedBotView()
                  : TabBarView(
                      controller: controller.tabController,
                      children:
                          controller.addedRobots.map(_buildCmdsView).toList()));
        },
        onLoading: DefaultTheme.defaultLoadingIndicator(),
        onError: (e) {
          return CommonErrorMsgWidget(
            errorMsg: e,
            onRetry: controller.initPage,
          );
        },
      );
    });
  }

  List<Widget> _buildSliverAppBar(
      BuildContext context, ChannelCommandSettingPageController controller) {
    final cmds = controller.addedCommandItems;
    // 根据不同情况，计算 SliverAppBar 展开高度，
    double expandedHeight =
        _titleHeight + _addedItemHeight + 16 + 8 + _pinWidgetHeight;
    if (cmds.isNotEmpty) {
      expandedHeight = _titleHeight +
          cmds.length * _addedItemHeight +
          16 +
          8 +
          _pinWidgetHeight;
    }
    return [
      SliverOverlapAbsorber(
        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        sliver: SliverAppBar(
          stretch: true,
          pinned: true,
          floating: true,
          automaticallyImplyLeading: false,
          shadowColor: Colors.transparent,
          backgroundColor: appThemeData.backgroundColor,
          expandedHeight: expandedHeight,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            stretchModes: const [],
            background: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTitle('当前快捷指令'),
                _buildAddedCmds(),
                Container(
                  height: 8,
                  color: appThemeData.scaffoldBackgroundColor,
                ),
              ],
            ),
          ),
          bottom: controller.addedRobots.isEmpty
              ? null
              : PreferredSize(
                  preferredSize: Size.fromHeight(_pinWidgetHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTitle('所有指令'.tr),
                      _buildAddedBots(context),
                      divider,
                    ],
                  )),
        ),
      ),
      const SliverToBoxAdapter(
        child: SizedBox(height: 0.5),
      )
    ];
  }

  // 已添加指令列表
  Widget _buildAddedCmds() {
    final cmds = controller.addedCommandItems;
    if (cmds.isEmpty) {
      return _noAddedCmdView();
    }
    return Container(
      // height + padding
      height: cmds.length * _addedItemHeight + 16,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      // color: Colors.green,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 6, bottom: 10),
        itemBuilder: (c, i) {
          final cmd = cmds[i];
          return _buildAddedCmdItem(cmd, i);
        },
        itemCount: cmds.length,
        separatorBuilder: (context, index) => const Divider(
          indent: 24.0 + 8.0,
          endIndent: 4,
        ),
      ),
    );
  }

  // 单个已添加指令的ui
  Container _buildAddedCmdItem(BotCommandItem cmd, int index) {
    BorderRadius borderRadius;
    const radius = Radius.circular(6.5);
    if (index == 0) {
      borderRadius = const BorderRadius.only(
        topLeft: radius,
        topRight: radius,
      );
    } else if (index == controller.addedCommandItems.length - 1) {
      borderRadius = const BorderRadius.only(
        bottomLeft: radius,
        bottomRight: radius,
      );
    }

    return Container(
      height: _addedItemHeight,
      alignment: Alignment.centerLeft,
      // padding: const EdgeInsets.only(left: 18, right: 16.5),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: Get.theme.backgroundColor,
      ),
      child: Row(
        children: [
          FlutterAvatar(
            url: cmd.botAvatar,
            radius: 12,
          ),
          sizeWidth8,
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    cmd.command,
                    style: const TextStyle(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                sizeWidth4,
                if (!cmd.isValid)
                  _statusTag(
                    text: '已失效'.tr,
                    color: errorColor,
                    bgColor: appThemeData.dividerColor,
                  )
                else if (cmd.isAdminVisible)
                  _statusTag(
                    text: '管理员可见'.tr,
                    color: appThemeData.textTheme.headline2.color,
                    bgColor: appThemeData.dividerColor,
                  ),
              ],
            ),
          ),
          sizeWidth4,
          IconButton(
            icon: Icon(
              IconFont.buffClose,
              size: 20,
              color: appThemeData.textTheme.headline2.color,
            ),
            constraints: BoxConstraints.tight(const Size(20, 20)),
            padding: EdgeInsets.zero,
            onPressed: () => controller.removeCommand(cmd),
          )
        ],
      ),
    );
  }

  // 指令状态tag
  Container _statusTag({Color bgColor, Color color, String text = ''}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 4),
      decoration:
          BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(2)),
      child: Text(
        text,
        style: TextStyle(
          height: 13 / 11,
          fontSize: 10,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Container(
      height: _titleHeight,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, color: Color(0xFF5C6273)),
      ),
    );
  }

  // 已添加的机器人tabs
  Widget _buildAddedBots(BuildContext context) {
    final addedRobots = controller.addedRobots;
    final _tabs = addedRobots.map((id) {
      return GestureDetector(
        onTap: () => controller.onSelectBot(id),
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              sizeHeight16,
              RealtimeAvatar(userId: id, size: 48),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: RealtimeNickname(
                  userId: id,
                  style: const TextStyle(fontSize: 11, height: 14 / 11),
                ),
              ),
              sizeHeight12,
            ],
          ),
        ),
      );
    }).toList();
    return TabBar(
      tabs: _tabs,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      labelColor: appThemeData.textTheme.bodyText1.color,
      unselectedLabelColor: Get.theme.iconTheme.color,
      controller: controller.tabController,
      isScrollable: true,
      labelPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      unselectedLabelStyle: Get.textTheme.bodyText1.copyWith(fontSize: 16),
      labelStyle: Get.textTheme.bodyText2
          .copyWith(fontSize: 16, fontWeight: FontWeight.w500),
      indicator: MyUnderlineTabIndicator(
        indicatorWidth: 24,
        borderSide: BorderSide(width: 2, color: primaryColor),
      ),
    );
  }

  // 已添加机器人的指令视图
  Widget _buildCmdsView(String botId) {
    return Builder(builder: (c) {
      return FutureBuilder<List<BotCommandItem>>(
        future: controller.getFutureByBotId(botId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 加载中
            return Center(
              child: DefaultTheme.defaultLoadingIndicator(),
            );
          }
          if (snapshot.hasError) {
            if (snapshot.error is InvalidRobotError) {
              return _invalidBotView();
            }
            return _cmdErrorView();
          }
          if (!snapshot.hasData) {
            return sizedBox;
          }
          return _buildCmdList(snapshot.data);
        },
      );
    });
  }

  // 机器人被开发者删除，点击删除当前选中的机器人
  Widget _invalidBotView() {
    return _buildScrollView(
      child: Padding(
        padding: _getSafePadding(padding: 100),
        child: Column(
          children: [
            Text(
              '该机器人已被开发者删除',
              style: TextStyle(
                  fontSize: 16, color: appThemeData.textTheme.headline2.color),
            ),
            sizeHeight24,
            FadeButton(
              width: 90,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.5),
                color: primaryColor,
              ),
              onTap: () {
                controller.removeInvalidRobot();
              },
              child: Text(
                '点击移除'.tr,
                style: TextStyle(
                  fontSize: 14,
                  color: Get.theme.backgroundColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _cmdErrorView() {
    return Padding(
      padding: _getSafePadding(padding: 100),
      child: Column(
        children: [
          Text(
            '加载失败',
            style: TextStyle(
                fontSize: 16, color: appThemeData.textTheme.headline2.color),
          ),
          sizeHeight24,
          FadeButton(
            width: 90,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.5),
              color: primaryColor,
            ),
            onTap: () {
              controller.update();
            },
            child: Text(
              '点击重试'.tr,
              style: TextStyle(
                fontSize: 14,
                color: Get.theme.backgroundColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        ],
      ),
    );
  }

  // 机器人的指令列表
  Widget _buildCmdList(List<BotCommandItem> cmds) {
    return GetBuilder<ChannelCommandSettingPageController>(
      builder: (c) {
        if (cmds.isEmpty)
          return _buildScrollView(
            child: Padding(
              padding: _getSafePadding(),
              child: SvgTipWidget(
                svgName: SvgIcons.nullState,
                desc: '该机器人未添加任何指令'.tr,
              ),
            ),
          );

        return Builder(builder: (context) {
          return CustomScrollView(
            slivers: <Widget>[
              SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverList(
                  delegate: SliverChildBuilderDelegate((c, i) {
                if (i.isOdd)
                  return const Divider(
                    indent: 16,
                    endIndent: 16,
                  );
                return _buildCmdItem(
                    cmds[(i + 1) ~/ 2], i == (cmds.length + cmds.length - 2));
              }, childCount: cmds.length + cmds.length - 1)),
            ],
          );
        });
      },
    );
  }

  Widget _buildCmdItem(BotCommandItem command, bool isLast) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Get.theme.backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  command.command,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                sizeHeight8,
                Text(
                  command.description ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: appThemeData.textTheme.headline2.color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          sizeWidth16,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AddButton(
                status: controller.getCommandStatus(command),
                onAdd: () => controller.addCommand(command),
              ),
              sizeHeight4,
              if (command.isAdminVisible)
                Text(
                  '管理员可见'.tr,
                  style: TextStyle(
                    height: 14 / 11,
                    color: appThemeData.textTheme.headline2.color,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScrollView({@required Widget child}) {
    return SingleChildScrollView(
      child: child,
    );
  }
}
