import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/components/red_dot.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/dock.dart';
import 'package:im/pages/video_call/model/video_model.dart';
import 'package:im/pages/video_call/view/video_bar.dart';
import 'package:im/pages/video_call/view/video_tool_bar.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/timer_view.dart';

class VideoToolView extends StatelessWidget {
  final VideoModel model;

  const VideoToolView(this.model);

  @override
  Widget build(BuildContext context) {
    final double _stausBarHeight = MediaQuery.of(context).padding.top;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        sizeHeight16,
        ValueListenableBuilder(
          valueListenable: model.showToolBar,
          builder: (context, value, child) {
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: value ? -(_stausBarHeight + 60) : 16,
              left: 0,
              right: 0,
              curve: Curves.easeOutSine,
              child: _TopBar(model),
            );
          },
        ),
        ValueListenableBuilder(
          valueListenable: model.showToolBar,
          builder: (context, value, child) {
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: value ? -80 : 32,
              left: 0,
              right: 0,
              curve: Curves.easeOutSine,
              child: VideoToolBar(model),
            );
          },
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final VideoModel model;

  const _TopBar(this.model);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        sizeWidth8,
        InkWell(
          onTap: () {
            Routes.pop(context);
            Dock.show(VideoBar(model), customControl: true);
          },
          child: Row(
            children: <Widget>[
              Icon(
                IconFont.buffOtherColes,
                size: 24,
                color: Theme.of(context).textTheme.bodyText2.color,
              ),
              RedDotListenable(valueListenable: GlobalState.totalNumUnread)
            ],
          ),
        ),
        Expanded(
          child: model.state == VideoState.chatting
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    RealtimeNickname(
                      userId: model.callUserId,
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                    sizeHeight8,
                    ValueListenableBuilder(
                      valueListenable: model.connectTimer,
                      builder: (_, value, __) {
                        return value != null
                            ? TimerView(
                                prefix: "通话中 ".tr,
                                start: model.connectTimer.value,
                              )
                            : sizedBox;
                      },
                    ),
                  ],
                )
              : sizedBox,
        ),
        SizedBox(
          width: 40,
          child: Visibility(
            visible:
                model.currentUser != null && model.currentUser.enableCamera,
            child: InkWell(
              onTap: model.switchCamera,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Icon(
                  IconFont.buffModuleSwitchCamera,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        sizeWidth8,
      ],
    );
  }
}
