import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/db/db.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/quest/fb_quest_config.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/buttom_sheet_darg_tag.dart';
import 'package:im/widgets/share_link_popup/share_link_popup.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:quest_system/quest_system.dart';

class BusinessGuide extends StatefulWidget {
  final QuestGroup questGroup;
  final List<String> taskTitles;

  const BusinessGuide(this.questGroup, this.taskTitles, {Key key})
      : super(key: key);

  @override
  _BusinessGuideState createState() => _BusinessGuideState();
}

class _BusinessGuideState extends State<BusinessGuide> {
  final guildId = ChatTargetsModel.instance.selectedChatTarget?.id;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F6FA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetDragTag(),
            _title(context),
            _item(widget.taskTitles[0], IconFont.buffWenzipindaotubiao, 0, () {
              Get.toNamed(
                Routes.GUILD_CHANNEL_SETTINGS,
                preventDuplicates: false,
              );
              DLogManager.getInstance().customEvent(
                actionEventId: "guild_guide",
                actionEventSubId: "click_guide",
                actionEventSubParam: "channel",
                extJson: {"guild_id": guildId},
              );
            }),
            sizeHeight12,
            _item(widget.taskTitles[1], IconFont.buffChannelMessageSolid, 1,
                () {
              Get.back();
              HomeScaffoldController.to.gotoWindow(1);
              DLogManager.getInstance().customEvent(
                actionEventId: "guild_guide",
                actionEventSubId: "click_guide",
                actionEventSubParam: "send",
                extJson: {"guild_id": guildId},
              );
            }),
            sizeHeight12,
            _item(widget.taskTitles[2], IconFont.buffModuleMenuOpen, 2, () {
              showShareLinkPopUp(
                context,
                direction: TooltipDirection.right,
                margin: const EdgeInsets.only(left: 204),
              );
              DLogManager.getInstance().customEvent(
                actionEventId: "guild_guide",
                actionEventSubId: "click_guide",
                actionEventSubParam: "share",
                extJson: {"guild_id": guildId},
              );
            }),
            sizeHeight24,
            QuestBuilder<QuestGroup>.quest(widget.questGroup, builder: (q) {
              if (q.progress == q.length)
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: 8, left: 16, right: 16),
                  child: FadeButton(
                    onTap: () {
                      Get.back();
                      CustomTrigger.instance.dispatch(QuestTriggerData(
                        condition: QuestCondition([
                          QIDSegGroup.quickStart,
                          ChatTargetsModel.instance.selectedChatTarget.id,
                        ]),
                      ));
                      Db.guideBox.clear();
                      QuestSystem.removeContainer(widget.questGroup.id);
                    },
                    height: 44,
                    decoration: BoxDecoration(
                      color: Get.theme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('确认完成'.tr,
                        style: const TextStyle(color: Colors.white)),
                  ),
                );
              else
                return const SizedBox();
            }),
          ],
        ),
      ),
    );
  }

  SizedBox _title(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          Text(
            '快速上手服务器'.tr,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          SizedBox(
            width: 48,
            height: 48,
            child: QuestBuilder<QuestGroup>.quest(
              widget.questGroup,
              builder: (q) {
                if (q.progress == 3)
                  return Center(
                    child: Icon(IconFont.buffAllDone,
                        size: 32, color: Get.theme.primaryColor),
                  );
                else
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        "${q.progress}/3",
                        style: const TextStyle(
                          color: Color(0xFF8D93A6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: TaskScheduleAnimation(q.progressInPercent),
                      ),
                    ],
                  );
              },
            ),
          ),
          sizeWidth4,
        ],
      ),
    );
  }

  Widget _item(
      String text, IconData icon, int index, GestureTapCallback onTap) {
    return QuestBuilder<Quest>.quest(
      widget.questGroup[index],
      builder: (q) {
        final done = q.status == QuestStatus.completed;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: done ? Colors.white.withOpacity(.75) : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon,
                      size: 20, color: done ? const Color(0xFF8D93A6) : null),
                ),
                sizeWidth12,
                Text(text,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: done ? const Color(0xFF8D93A6) : null)),
                const Spacer(),
                if (done)
                  Icon(IconFont.buffTaskDone,
                      size: 24, color: Theme.of(context).primaryColor)
                else
                  Icon(IconFont.buffChannelMoreLarge,
                      size: 20, color: const Color(0xFF363940).withOpacity(.5)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TaskScheduleAnimation extends StatefulWidget {
  const TaskScheduleAnimation(this.schedulePercent, {Key key})
      : super(key: key);
  final double schedulePercent;

  @override
  _TaskScheduleAnimationState createState() => _TaskScheduleAnimationState();
}

class _TaskScheduleAnimationState extends State<TaskScheduleAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _animation;

  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _controller.animateTo(widget.schedulePercent);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, snapshot) {
        return CustomPaint(
          painter: TaskSchedule(
            Theme.of(context).disabledColor.withOpacity(.15),
            Theme.of(context).primaryColor,
            _animation.value,
          ),
        );
      },
    );
  }
}

class TaskSchedule extends CustomPainter {
  final double percent;
  final Color inActivateColor;
  final Color activateColor;

  @override
  void paint(Canvas canvas, Size size) {
    final inActPaint = Paint()
      ..strokeWidth = 4
      ..color = inActivateColor
      ..style = PaintingStyle.stroke;
    final actPaint = Paint()
      ..strokeWidth = 4
      ..color = activateColor
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
        const Rect.fromLTRB(0, 0, 48, 48), 0, 2 * pi, false, inActPaint);
    const startWith = -(pi / 2);
    const endWith = 2 * pi;
    canvas.drawArc(const Rect.fromLTWH(0, 0, 48, 48), startWith,
        percent * endWith, false, actPaint);
  }

  @override
  bool shouldRepaint(TaskSchedule oldDelegate) =>
      oldDelegate.percent != percent;

  TaskSchedule(this.inActivateColor, this.activateColor, this.percent);
}
