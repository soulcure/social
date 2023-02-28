import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:im/pages/home/view/dock.dart';
import 'package:im/pages/video_call/model/video_model.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/timer_view.dart';
import 'package:provider/provider.dart';

import '../../../global.dart';

class VideoBar extends StatelessWidget {
  final VideoModel model;
  const VideoBar(this.model);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: model,
      child: Consumer<VideoModel>(
        builder: (_, value, __) {
          if (model.currentUser == null) return sizedBox;
          return SizedBox(
            width: 90,
            height: 138,
            child: Stack(
              children: <Widget>[
                // 背景
                InkWell(
                  onTap: () {
                    Dock.hide();
                    Routes.pushVideoPage(context, null, oldModel: model);
                  },
                  child: model.currentUser.enableCamera &&
                          model.currentUser.video != null
                      ? _buildVideo()
                      : _buildCard(context),
                ),
                // 关闭按钮
                _buildCloseButton(context),
                // 通话时长
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: ValueListenableBuilder(
                    valueListenable: model.connectTimer,
                    builder: (_, value, __) {
                      return value != null
                          ? Center(
                              child: TimerView(start: model.connectTimer.value),
                            )
                          : sizedBox;
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Positioned _buildCloseButton(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: InkWell(
        onTap: () {
          model.close("通话已结束".tr);
          Dock.hide();
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF2494A),
            ),
            child: const Icon(
              Icons.call_end,
              size: 10,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideo() {
    return SizedBox(
      width: 90,
      height: 138,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: RTCVideoView(
          model.currentUser.video,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          key: Key(model.currentUser.userId.toString()),
          mirror: model.currentUser.userId == Global.user.id &&
              model.currentUser.useFrontCamera,
        ),
      ),
    );
  }

  Container _buildCard(BuildContext context) {
    return Container(
      width: 90,
      height: 138,
      decoration: BoxDecoration(
        color: Theme.of(context).backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: <Widget>[
          sizeHeight16,
          Avatar(
            url: model.currentUser.avatar,
            radius: 24,
          ),
          sizeHeight16,
          Text(
            model.currentUser.nickname,
            style: Theme.of(context).textTheme.bodyText2.copyWith(fontSize: 12),
          ),
          sizeHeight16,
          ValueListenableBuilder(
            valueListenable: model.connectTimer,
            builder: (_, value, __) {
              return value == null
                  ? Text(
                      "呼叫中..".tr,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText2
                          .copyWith(fontSize: 12),
                    )
                  : sizedBox;
            },
          ),
        ],
      ),
    );
  }
}
