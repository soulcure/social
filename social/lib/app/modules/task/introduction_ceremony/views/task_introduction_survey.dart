import 'package:dynamic_card/dynamic_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:im/app/modules/task/introduction_ceremony/views/task_introduction_header.dart';
import 'package:im/app/modules/task/task_util.dart';
import 'package:im/app/modules/task/task_ws_util.dart';
import 'package:im/app/modules/task/welcome_util.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/dynamic_widget/dynamic_widget.dart';
import 'package:oktoast/oktoast.dart';

class TaskIntroductionSurvey extends StatefulWidget {
  final bool isShowBackBtn;

  const TaskIntroductionSurvey({Key key, this.isShowBackBtn = false})
      : super(key: key);

  @override
  _TaskIntroductionSurveyState createState() => _TaskIntroductionSurveyState();
}

class _TaskIntroductionSurveyState extends State<TaskIntroductionSurvey> {
  final _scrollController = ScrollController();
  RxBool isInvertColors = false.obs;
  double appBarHeight =
      Get.mediaQuery.padding.top + AppBar().preferredSize.height;
  RxDouble appBarAlpha = 0.0.obs;
  final _dynamicController = DynamicController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      // 如果滑动到底部
      if (_scrollController.position.pixels >= 188 - appBarHeight) {
        appBarAlpha.value = 1.0;
        isInvertColors.value = true;
      } else {
        isInvertColors.value = false;
        // final double pixels =
        //     _scrollController.position.pixels / (188 - appBarHeight);
        // appBarAlpha.value = pixels > 0 ? pixels : 0;
        appBarAlpha.value = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final headerText = TaskUtil.instance.takEntity?.taskTitle?.hasValue ?? false
        ? TaskUtil.instance.takEntity?.taskTitle
        : '完成新成员验证，开始畅聊'.tr;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onPanDown: (_) {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: ClipRRect(
          borderRadius: OrientationUtil.landscape
              ? const BorderRadius.all(Radius.circular(4))
              : const BorderRadius.all(Radius.circular(0)),
          child: Container(
            color: Colors.white,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: UniversalPlatform.isWeb ? -1 : 0,
                  top: 0,
                  bottom: 0,
                  child: CustomScrollView(
                    physics: const ClampingScrollPhysics(),
                    controller: _scrollController,
                    slivers: <Widget>[
                      SliverToBoxAdapter(
                        child: TaskIntroductionHeader(
                          welcomeMessage: TaskUtil
                                  .instance?.takEntity?.welcomeMessage
                                  .toString() ??
                              "",
                          child: Padding(
                            padding: const EdgeInsets.only(left: 40, right: 40),
                            child: Text(
                              headerText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Color(0xFF363940),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  height: 1.27),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white,
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 24,
                              ),
                              Divider(
                                color: const Color(0xFF8F959E).withOpacity(0.2),
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                              const SizedBox(
                                height: 24,
                              ),
                              Container(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16, bottom: 12),
                                  child: Text(
                                    "请完成下列问题".tr,
                                    style: const TextStyle(
                                        color: Color(0xFF4F5660),
                                        fontSize: 14,
                                        height: 1.2,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                          child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              border: Border.all(
                                  color:
                                      const Color(0xFF8F959E).withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(6)),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 1, right: 1, top: 3, bottom: 14),
                            child: buildDynamicWidget(_dynamicController),
                          ),
                        ),
                      )),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: 16,
                              top: 24,
                              bottom: 10 + Get.mediaQuery.padding.bottom),
                          child: Column(
                            children: [
                              Align(
                                alignment: OrientationUtil.landscape
                                    ? Alignment.centerRight
                                    : Alignment.center,
                                child: Padding(
                                  padding: OrientationUtil.landscape
                                      ? const EdgeInsets.only(right: 24)
                                      : const EdgeInsets.only(right: 16),
                                  child: TextButton(
                                    onPressed: submit,
                                    style: TextButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: OrientationUtil.landscape
                                            ? const BorderRadius.all(
                                                Radius.circular(4))
                                            : const BorderRadius.all(
                                                Radius.circular(20)),
                                      ),
                                      minimumSize: OrientationUtil.landscape
                                          ? const Size(88, 32)
                                          : const Size(343, 40),
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                    ),
                                    child: Text(
                                      '完成'.tr,
                                      style: OrientationUtil.landscape
                                          ? const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              height: 1,
                                            )
                                          : const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(() {
                  return Positioned(
                    left: 0,
                    right: UniversalPlatform.isWeb ? -1 : 0,
                    top: 0,
                    bottom: 0,
                    child: Column(
                      children: [
                        Container(
                            color: Colors.white.withOpacity(appBarAlpha.value),
                            height: appBarHeight,
                            child: AppBar(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              leading: widget.isShowBackBtn
                                  ? IconButton(
                                      icon: Icon(
                                        IconFont.buffNavBarBackItem,
                                        color: isInvertColors.value
                                            ? Theme.of(context)
                                                .textTheme
                                                .bodyText2
                                                .color
                                            : Colors.white,
                                      ),
                                      onPressed: Get.back,
                                    )
                                  : const SizedBox(),
                              actions: <Widget>[
                                IconButton(
                                  icon: Icon(
                                    IconFont.buffNavBarCloseItem,
                                    color: isInvertColors.value
                                        ? Theme.of(context)
                                            .textTheme
                                            .bodyText2
                                            .color
                                        : Colors.white,
                                  ),
                                  onPressed: close,
                                ),
                              ],
                            )),
                        Divider(
                          color: isInvertColors.value
                              ? const Color(0xFF8F959E).withOpacity(0.15)
                              : Colors.transparent,
                          height: 0.5,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> close({bool isDoneTask = false}) async {
    Get.close(widget.isShowBackBtn ? 2 : 1);
    if (isDoneTask) {
      await TaskUtil.instance
          .updateGuildTargetInfoWithGuildId(TaskWsUtil.onUserNoticeData);
    }

    TaskWsUtil.resetTaskWsState();
  }

  Future<void> submit() async {
    final node = _dynamicController.getNode();
    if (node.isDataEmpty) {
      showToast("请完成所有问题后再提交".tr, radius: 8);
      return;
    }

    Loading.show(context);
    final bool isSuccess =
        await TaskUtil.instance.postTaskResult(node.idData ?? {});
    Loading.hide();
    if (isSuccess) {
      final guildId = ChatTargetsModel.instance.selectedChatTarget.id;
      DLogManager.getInstance().customEvent(
          actionEventId: 'introductory_ceremony',
          actionEventSubId: 'click_finish_newguide_task',
          extJson: {"guild_id": guildId});
      await close(isDoneTask: isSuccess);

      await WelcomeUtil.welcomeInterface(guildId);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _dynamicController.dispose();
    _scrollController.dispose();
  }
}

Widget buildDynamicWidget(DynamicController controller) {
  return LayoutBuilder(builder: (context, constrains) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: DynamicWidget(
          json: TaskUtil.instance?.takEntity?.content ?? {},
          controller: controller,
          config: TempWidgetConfig(
              radioConfig: RadioConfig(
                singleSelected: Icon(
                  IconFont.buffSelectSingle,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                singleUnselected: const Icon(
                  IconFont.buffUnselectSingle,
                  size: 20,
                  color: color3,
                ),
                groupSelected: Icon(
                  IconFont.buffSelectGroup,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                groupUnselected: const Icon(
                  IconFont.buffUnselectGroup,
                  size: 20,
                  color: color3,
                ),
              ),
              buttonConfig: ButtonConfig(
                dropdownConfig: DropdownConfig(
                  dropdownIcon: () =>
                      const Icon(IconFont.buffDownMore, color: color3),
                ),
              ),
              commonConfig: CommonConfig(
                  widgetWith: kIsWeb ? 400 : constrains.maxWidth))),
    );
  });
}
