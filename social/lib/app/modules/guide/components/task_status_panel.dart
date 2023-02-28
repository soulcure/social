import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:quest_system/quest_system.dart';
import 'package:im/app/modules/guide/components/business_guide.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';

class TaskStatusPanel extends StatelessWidget {
  const TaskStatusPanel({Key key, this.questGroup}) : super(key: key);
  final QuestGroup questGroup;

  static final taskTitles = ['了解频道管理'.tr, '发送一条消息'.tr, '邀请好友'.tr];

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.bottomSheet(
          BusinessGuide(questGroup, taskTitles),
          isScrollControlled: true,
          settings: const RouteSettings(name: Routes.BS_GUILD_INTRO),
        );
        DLogManager.getInstance().customEvent(
          actionEventId: "guild_guide",
          actionEventSubId: "show_guide",
          actionEventSubParam: "click_task_push",
          extJson: {
            "guild_id": ChatTargetsModel.instance.selectedChatTarget?.id,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 81,
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('快速上手服务器'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    sizeHeight6,
                    Text(
                      () {
                        ///面板显示最前的一个未完成的任务标题
                        final firstUndone = questGroup.children.indexWhere(
                            (e) => e.status != QuestStatus.completed);
                        if (questGroup.progress >= 3)
                          return '全部完成!'.tr;
                        else
                          return '%s/3：%s'.trArgs([
                            (questGroup.progress).toString(),
                            taskTitles[firstUndone]
                          ]);
                      }(),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF5C6273)),
                    ),
                    sizeHeight8,
                  ],
                ),
                const Spacer(),
                Icon(
                  IconFont.buffPayArrowNext,
                  size: 12,
                  color: appThemeData.dividerColor.withOpacity(.75),
                )
              ],
            ),
            const Spacer(),
            TaskStatusBarAnimation(
              const Size(double.infinity, 6),
              questGroup.progressInPercent,
            ),
          ],
        ),
      ),
    );
  }
}

class TaskStatusBarAnimation extends StatefulWidget {
  const TaskStatusBarAnimation(this.size, this.schedulePercent, {Key key})
      : super(key: key);
  final Size size;
  final double schedulePercent;

  @override
  _TaskStatusBarAnimationState createState() => _TaskStatusBarAnimationState();
}

class _TaskStatusBarAnimationState extends State<TaskStatusBarAnimation>
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
          size: Size(widget.size.width, widget.size.height),
          painter: TaskStatusBar(
            _animation.value,
            Theme.of(context).disabledColor.withOpacity(.15),
            Theme.of(context).primaryColor,
          ),
        );
      },
    );
  }
}

class TaskStatusBar extends CustomPainter {
  TaskStatusBar(this.percent, this.inActivateColor, this.activateColor);

  final double percent;
  final Color inActivateColor;
  final Color activateColor;

  @override
  void paint(Canvas canvas, Size size) {
    final inActPaint = Paint()
      ..strokeWidth = 6
      ..color = inActivateColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final actPaint = Paint()
      ..strokeWidth = 6
      ..color = activateColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final double schedule = max(3, (size.width - 3) * percent);
    canvas.drawLine(Offset(3, size.height / 2),
        Offset(size.width - 3, size.height / 2), inActPaint);
    canvas.drawLine(Offset(3, size.height / 2),
        Offset(schedule, size.height / 2), actPaint);
  }

  @override
  bool shouldRepaint(TaskStatusBar oldDelegate) =>
      oldDelegate.percent != percent;
}
