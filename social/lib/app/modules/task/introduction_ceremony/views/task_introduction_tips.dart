import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/task/introduction_ceremony/open_task_introduction_ceremony.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/default_theme.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../../svg_icons.dart';

enum TaskStyle {
  /// 聊天样式
  Chat,

  /// 频道样式
  Channel,
}

const double kTaskIntroductionHeight = 78;

class TaskIntroductionTips extends StatefulWidget {
  final String content;
  final VoidCallback onTap;
  final String url;
  final TaskStyle taskStyle;

  const TaskIntroductionTips(
      {Key key,
      this.content,
      this.url,
      this.onTap,
      this.taskStyle = TaskStyle.Chat})
      : super(key: key);

  @override
  _TaskIntroductionTipsState createState() => _TaskIntroductionTipsState();
}

class _TaskIntroductionTipsState extends State<TaskIntroductionTips>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _animation;
  Timer timer;
  Timer firstAnimationTimer;

  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _animation = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.toDouble(), end: -(pi / 20)), weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: -(pi / 20), end: pi / 15), weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: pi / 15, end: -(pi / 15)), weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: -(pi / 15), end: pi / 15), weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: pi / 15, end: -(pi / 20)), weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: -(pi / 20), end: 0.toDouble()), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn))
      ..addListener(() {
        setState(() {});
      });

    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        //动画完成

        timer = Timer(const Duration(seconds: 3), () {
          _controller.reset();
          _controller.forward();
        });
      }
    });

    firstAnimationTimer = Timer(const Duration(seconds: 1), () {
      _controller.forward();
    });
    super.initState();
  }

  @override
  void dispose() {
    firstAnimationTimer?.cancel();
    timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.taskStyle == TaskStyle.Channel) {
      return channelStyleTask(context);
    }
    return chatStyleTask(context);
  }

  /// 频道界面任务卡片布局
  Widget channelStyleTask(BuildContext context) {
    return FadeBackgroundButton(
      onTap: () {
        final guild =
            ChatTargetsModel.instance.selectedChatTarget as GuildTarget;

        OpenTaskIntroductionCeremony.openTaskInterface();

        DLogManager.getInstance().customEvent(
            actionEventId: 'introductory_ceremony',
            actionEventSubId: 'click_start_now',
            actionEventSubParam: 'newguide_task_page',
            extJson: {"guild_id": guild.id});
      },
      height: kTaskIntroductionHeight,
      backgroundColor: const Color(0xFFF5F5F8),
      tapDownBackgroundColor: null,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 12.5,
            bottom: 58.5,
            width: 52,
            height: 52,
            child: Transform.rotate(
              angle: _animation.value,
              origin: const Offset(4, 10),
              child: SizedBox(
                  width: 52,
                  height: 52,
                  child: WebsafeSvg.asset(SvgIcons.taskIcon)),
            ),
          ),
          // ImageWidget.fromCachedNet(CachedImageBuilder(
          //   imageUrl: widget.url ?? '',
          //   cacheManager: CustomCacheManager.instance,
          //   fit: BoxFit.cover,
          //   memCacheWidth: 60,
          //   memCacheHeight: 60,
          // )),
          Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.content.breakWord ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.all(Radius.circular(18)),
                  ),
                  width: 76,
                  height: 36,
                  child: Center(
                    child: Text(
                      "立即开始".tr,
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  /// 聊天界面任务卡片布局
  Widget chatStyleTask(BuildContext context) {
    return Container(
      color: Colors.white,
      child: FadeBackgroundButton(
        onTap: () {
          OpenTaskIntroductionCeremony.openTaskInterface();
          final guildId = ChatTargetsModel.instance.selectedChatTarget.id;
          final selectChannelId = GlobalState?.selectedChannel?.value?.id ?? '';
          DLogManager.getInstance().customEvent(
              actionEventId: 'introductory_ceremony',
              actionEventSubId: 'click_start_now',
              actionEventSubParam: selectChannelId,
              extJson: {"guild_id": guildId});
        },
        height: 72 + Get.mediaQuery.padding.bottom + 0.5,
        backgroundColor: const Color(0xFFF5F5F8),
        tapDownBackgroundColor: null,
        child: Column(
          children: [
            Container(
              color: const Color(0xFF8F959E).withOpacity(0.15),
              height: 0.5,
            ),
            SizedBox(
              height: 72,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.5),
                    child: Transform.rotate(
                      angle: _animation.value,
                      origin: const Offset(4, 10),
                      child: SizedBox(
                          width: 52,
                          height: 52,
                          child: WebsafeSvg.asset(SvgIcons.taskIcon)),
                    ),
                  ),
                  // ImageWidget.fromCachedNet(CachedImageBuilder(
                  //   imageUrl: widget.url ?? '',
                  //   cacheManager: CustomCacheManager.instance,
                  //   fit: BoxFit.cover,
                  //   memCacheWidth: 60,
                  //   memCacheHeight: 60,
                  // )),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.content.breakWord ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 22, right: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20)),
                      ),
                      width: 88,
                      height: 36,
                      child: Center(
                        child: Text(
                          "立即开始".tr,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: Get.mediaQuery.padding.bottom,
            ),
          ],
        ),
      ),
    );
  }
}
