import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/pages/video_call/video_control.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/realtime_user_info.dart';

class VideoTips extends StatelessWidget {
  final CallInfo info;

  const VideoTips(this.info);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: info.cancel,
      builder: (context, cancel, widget) {
        if (cancel) {
          Future.microtask(() => Routes.pop(context));
          return sizedBox;
        } else {
          return _buildBody(context);
        }
      },
    );
  }

  Widget _buildBody(context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: double.infinity,
          height: 210,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  RealtimeAvatar(userId: info.userId),
                  sizeWidth16,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      RealtimeNickname(userId: info.userId),
                      sizeHeight5,
                      Text(
                        "邀请你进行通话".tr,
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                    ],
                  )
                ],
              ),
              const Divider(height: 32),
              Text(
                "接听后将会结束当前通话".tr,
                style: const TextStyle(color: Colors.red),
              ),
              sizeHeight16,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  // 拒绝
                  InkWell(
                    onTap: () {
                      // Routes.pop(context);
                      VideoControl.cancel(info);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF2494A),
                      ),
                      child: const Icon(
                        Icons.call_end,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // 接听
                  InkWell(
                    onTap: () async {
                      // Routes.pop(context);
                      await VideoControl.answer(info);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF29CC5F),
                      ),
                      child: const Icon(
                        Icons.call,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
