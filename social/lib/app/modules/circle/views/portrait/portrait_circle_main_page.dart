import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/modules/circle/views/portrait/widgets/circle_header_tab_widget.dart';
import 'package:im/app/modules/circle/views/widgets/create_moment_button.dart';
import 'package:im/app/modules/circle/views/widgets/upload_progress_widget.dart';
import 'package:im/app/modules/circle_search/controllers/circle_search_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/circle/circle_loading_view.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/routes.dart';
import 'package:im/svg_icons.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/scroll_physics.dart';
import 'package:im/widgets/svg_tip_widget.dart';
import 'package:oktoast/oktoast.dart';

import '../circle_topic_page.dart';

class PortraitCircleMainPage extends StatefulWidget {
  const PortraitCircleMainPage();

  @override
  _PortraitCircleMainPageState createState() => _PortraitCircleMainPageState();
}

class _PortraitCircleMainPageState extends State<PortraitCircleMainPage> {
  CircleController controller;
  bool _hasCircleManagerPermission = false;
  bool _retry = false;

  @override
  void initState() {
    final args = Get.arguments as CircleControllerParam;
    controller = CircleController(args.guildId, args.channelId,
        topicId: args.topicId,
        autoPushCircleMessage: args.autoPushCircleMessage);
    final GuildPermission gp = PermissionModel.getPermission(
        ChatTargetsModel.instance?.selectedChatTarget?.id);
    if (gp != null) {
      _hasCircleManagerPermission =
          PermissionUtils.oneOf(gp, [Permission.MANAGE_CIRCLES]);
    }
    super.initState();
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CircleController>(
      init: controller,
      builder: (c) {
        return Material(
          child: () {
            if (controller.initFinish)
              return _buildMobileCircleMainPage(controller.circleInfoDataModel);
            else if (controller.initFailed) {
              if (_retry) showToast(networkErrorText);
              return _buildErrorWidget();
            } else
              return CircleLoadingView();
          }(),
        );
      },
    );
  }

  Widget _buildMobileCircleMainPage(CircleInfoDataModel circleInfo) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: GetBuilder<CircleController>(
        id: 'floatButton',
        builder: (_) {
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomRight,
            children: [
              AnimatedPositioned(
                bottom: controller.showFloatButton
                    ? 0
                    : -(68 + Get.mediaQuery.padding.bottom).toDouble(),
                duration: const Duration(milliseconds: 250),
                curve: Curves.ease,
                child: const CreateMomentButton(),
              ),
            ],
          );
        },
      ),
      backgroundColor: const Color(0xFFEDEFF2),
      appBar: FbAppBar.diyTitleView(
        leadingIcon: IconFont.buffNavBarBackChannelItem,
        titleBuilder: (context, p1) => Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 22,
                height: 22,
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: appThemeData.dividerColor.withOpacity(.2),
                    width: .5,
                  ),
                ),
                child: ImageWidget.fromCachedNet(
                  CachedImageBuilder(
                    imageUrl: circleInfo.circleIcon,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                circleInfo?.circleName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: appThemeData.textTheme.bodyText2,
              ),
            )
          ],
        ),
        actions: [
          AppBarIconActionModel(
            IconFont.buffCommonSearchNew,
            actionBlock: () {
              Routes.pushCircleSearchPage(
                      context, circleInfo.guildId, circleInfo.channelId)
                  .then((value) {
                Get.delete<CircleSearchController>(tag: circleInfo.guildId);
              });
            },
          ),
          if (_hasCircleManagerPermission)
            AppBarIconActionModel(
              IconFont.buffSetting,
              actionBlock: () =>
                  Routes.pushCircleManagementPage(context, circleInfo),
            ),
        ],
      ),
      body: Column(
        children: [
          const CircleHeaderTabWidget(),
          Expanded(
            child: Stack(
              children: [
                TabBarView(
                    controller: controller.tabController,
                    physics: const TabViewScrollPhysics(),
                    children: controller.circleTopicList
                        .map((e) => CircleTopicPage(
                              topicId: e.topicId,
                              showType: e.showType,
                              type: e.type,
                              key: ValueKey(e.topicId),
                            ))
                        .toList()),
                const Positioned(
                    top: 0, left: 0, right: 0, child: UploadProgressWidget()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: SvgTipWidget(
              svgName: SvgIcons.noNetState,
              desc: '加载失败，请重试'.tr,
            ),
          ),
          FadeButton(
            onTap: () {
              _retry = true;
              controller.initFromNet();
            },
            decoration: BoxDecoration(
              color: appThemeData.primaryColor,
              borderRadius: BorderRadius.circular(5),
            ),
            width: 180,
            height: 36,
            child: Text(
              '重新加载'.tr,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
