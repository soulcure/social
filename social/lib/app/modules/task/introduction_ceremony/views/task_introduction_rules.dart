import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/task/introduction_ceremony/views/task_introduction_header.dart';
import 'package:im/app/modules/task/introduction_ceremony/views/task_introduction_survey.dart';
import 'package:im/app/modules/task/task_util.dart';
import 'package:im/app/modules/task/task_ws_util.dart';
import 'package:im/app/modules/task/welcome_util.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/routes.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/button/round_check_box.dart';
import 'package:oktoast/oktoast.dart';

import '../../../../../icon_font.dart';

class TaskIntroductionRules extends StatefulWidget {
  final bool isShowBackBtn;

  const TaskIntroductionRules({Key key, this.isShowBackBtn = false})
      : super(key: key);

  @override
  _TaskIntroductionRulesState createState() => _TaskIntroductionRulesState();
}

class _TaskIntroductionRulesState extends State<TaskIntroductionRules> {
  final ScrollController _scrollController = ScrollController();

  RxBool isInvertColors = false.obs;
  var _checkboxSelected = false;
  double appBarHeight =
      Get.mediaQuery.padding.top + AppBar().preferredSize.height;
  RxDouble appBarAlpha = 0.0.obs;

  bool isHasNext = false;

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
    isHasNext = TaskUtil.instance?.takEntity?.content != null &&
        TaskUtil.instance.takEntity.content.isNotEmpty;

    final rules = TaskUtil.instance?.takEntity?.rule ?? [];
    final headerText = TaskUtil.instance.takEntity?.taskTitle?.hasValue ?? false
        ? TaskUtil.instance.takEntity?.taskTitle
        : '完成新成员验证，开始畅聊'.tr;
    const headerStyle = TextStyle(
        color: Color(0xFF363940),
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.27);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ClipRRect(
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
                            style: headerStyle,
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
                            Container(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 24, left: 16, bottom: 12),
                                child: Text(
                                  "请阅读并同意服务器规则".tr,
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
                            color: const Color(0xFFF2F3F5),
                            borderRadius: BorderRadius.circular(6)),
                        child: ListView.separated(
                            padding: const EdgeInsets.only(),
                            primary: false,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                    left: 12,
                                    right: 12,
                                    top: 13.5,
                                    bottom: 13.5),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${index + 1}.  ',
                                      style: const TextStyle(
                                          color: Color(0xFF747F8D),
                                          height: 1.4,
                                          fontSize: 15),
                                    ),
                                    Expanded(
                                      child: Text(
                                        rules[index],
                                        overflow: TextOverflow.clip,
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            height: 1.4),
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
                            separatorBuilder: (context, index) => const Divider(
                                  height: 1,
                                  indent: 12,
                                  endIndent: 12,
                                ),
                            itemCount: rules.length),
                      ),
                    )),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: 16,
                            top: 18,
                            bottom: 10 + Get.mediaQuery.padding.bottom),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                RoundCheckBox(
                                  size: 22,
                                  left: 0,
                                  right: 8,
                                  bottom: 0,
                                  top: 0,
                                  defaultValue: _checkboxSelected ?? false,
                                  onChanged: (value) {
                                    setState(() {
                                      _checkboxSelected = value;
                                    });
                                  },
                                ),
                                Text(
                                  "我已阅读并同意规则".tr,
                                  style: const TextStyle(
                                      color: Color(0xFF363940),
                                      fontSize: 16,
                                      height: 1.3,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 20,
                            ),
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
                                    isHasNext ? '下一步'.tr : '完成'.tr,
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
                                onPressed: () {
                                  Get.close(1);
                                },
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
    );
  }

  Future<void> submit() async {
    if (!_checkboxSelected) {
      showToast("请阅读并同意服务器规则".tr, radius: 8);
      return;
    }

    if (isHasNext) {
      if (OrientationUtil.portrait) {
        await Routes.push(
            Get.context,
            const TaskIntroductionSurvey(
              isShowBackBtn: true,
            ),
            null);
      } else {
        await Get.dialog(
          UnconstrainedBox(
            child: Container(
              alignment: Alignment.center,
              width: 440,
              height: 724,
              child: const TaskIntroductionSurvey(
                isShowBackBtn: true,
              ),
            ),
          ),
          barrierDismissible: false,
        );
      }

      final guildId = ChatTargetsModel.instance.selectedChatTarget.id;
      DLogManager.getInstance().customEvent(
          actionEventId: 'introductory_ceremony',
          actionEventSubId: 'click_agree_rule',
          extJson: {"guild_id": guildId});
    } else {
      Loading.show(context);
      final bool isSuccess = await TaskUtil.instance.postTaskResult({});
      Loading.hide();
      if (isSuccess) {
        final guildId = ChatTargetsModel.instance.selectedChatTarget.id;
        DLogManager.getInstance().customEvent(
            actionEventId: 'introductory_ceremony',
            actionEventSubId: 'click_finish_newguide_task',
            extJson: {"guild_id": guildId});

        Get.back();

        await TaskUtil.instance
            .updateGuildTargetInfoWithGuildId(TaskWsUtil.onUserNoticeData);

        TaskWsUtil.resetTaskWsState();

        await WelcomeUtil.welcomeInterface(guildId);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    TaskWsUtil.resetTaskWsState();
  }
}
