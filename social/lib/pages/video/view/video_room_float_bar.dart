import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:im/core/widgets/button/base_button.dart';
import 'package:im/hybrid/webrtc/room/multi_video_room.dart';
import 'package:im/pages/home/home_page.dart';
import 'package:im/pages/video/model/video_room_controller.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/only.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:just_throttle_it/just_throttle_it.dart';
import 'package:oktoast/oktoast.dart';

import '../../../icon_font.dart';

class VideoRoomFloatBar extends StatefulWidget {
  final String roomId;

  const VideoRoomFloatBar(this.roomId, {Key key}) : super(key: key);

  @override
  State<VideoRoomFloatBar> createState() => _VideoRoomFloatBarState();
}

class _VideoRoomFloatBarState extends State<VideoRoomFloatBar> {
  VideoUser user;

  @override
  void dispose() {
    super.dispose();
    Throttle.clear(dispatch);
  }

  void dispatch(BuildContext context) =>
      RestoreMediaChannelViewNotification().dispatch(context);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VideoRoomController>(
        tag: widget.roomId,
        builder: (c) {
          user = c.me;
          return BaseButton(
            onTap: () => Throttle.milliseconds(800, dispatch, [context]),
            child: SizedBox(
              width: 90,
              height: 138.5,
              child: Column(
                children: [
                  Obx(() => Visibility(
                      visible: c.enableVideo.value &&
                          (c.screenShareState.value == ScreenShareType.normal),
                      child: _video(c))),
                  Obx(() => Visibility(
                      visible: !c.enableVideo.value &&
                          (c.screenShareState.value == ScreenShareType.normal),
                      child: _audio())),
                  Obx(() => Visibility(
                      visible:
                          c.screenShareState.value == ScreenShareType.opened,
                      child: _shareScreen())),
                  _menu(c),
                ],
              ),
            ),
          );
        });
  }

  Widget _video(VideoRoomController c) => Expanded(
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          child: RTCVideoView(
            user.video,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            mirror: c.isSelf && user.useFrontCamera,
          ),
        ),
      );

  Widget _audio() => Expanded(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Stack(
              children: <Widget>[
                // RealtimeAvatar(userId: item.userId, size: 48),
                RealtimeAvatar(userId: user.userId, size: 48),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Only(
                    showIndex: user.talking ? 1 : 0,
                    children: <Widget>[
                      const SizedBox(),
                      // 说话状态
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFF43B581),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          IconFont.buffNaviMic,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            // 名称
            SizedBox(
              width: 65,
              child: RealtimeNickname(
                // userId: item.userId,
                userId: user.userId,
                textAlign: TextAlign.center,
                showNameRule: ShowNameRule.remarkAndGuild,
                // guildId: c.guildId,
                style: const TextStyle(
                    fontSize: 13, height: 1.3, color: Color(0xFF363940)),
                // style: Theme.of(context).textTheme.bodyText2,
              ),
            ),
            // const SizedBox(height: 11),
            const Spacer(),
            divider,
          ],
        ),
      );

  Widget _shareScreen() => Expanded(
        child: Column(
          children: [
            const SizedBox(height: 22),
            Image.asset(
              'assets/images/share_default_new.png',
              height: 41,
              width: 41,
            ),
            const SizedBox(height: 12),
            const Text(
              "正在共享屏幕",
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: Color(0xFF363940),
              ),
            ),
            const Spacer(),
            divider,
          ],
        ),
      );

  Widget _menu(VideoRoomController c) => IgnorePointer(
        ignoring: c.ignoring,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            InkWell(
              onTap: () {
                if (c.muted.value != MicrophoneType.muteBan)
                  return c.toggleMuted();
              },
              // 静音状态
              child: Container(
                padding: const EdgeInsets.only(top: 8, bottom: 8, right: 13.5),
                child: ObxValue((muted) {
                  return Icon(
                    muted.value == MicrophoneType.mute
                        ? IconFont.buffMicrophoneOff
                        : muted.value == MicrophoneType.noMute
                            ? IconFont.buffMicrophoneOn
                            : IconFont.buffVideoMicBan,
                    color: (muted.value == MicrophoneType.mute ||
                            muted.value == MicrophoneType.muteBan)
                        ? DefaultTheme.dangerColor
                        : const Color(0xFF646A73),
                    size: 18,
                  );
                }, c.muted),
              ),
            ),
            const SizedBox(
              height: 14,
              child: VerticalDivider(
                thickness: 0.5,
                width: 0.5,
              ),
            ),
            InkWell(
              onTap: () {
                showToast("已断开视频连接".tr);
                return c.closeAndDispose();
              },
              child: Container(
                padding: const EdgeInsets.only(top: 8, bottom: 8, left: 13.5),
                child: const Icon(
                  IconFont.buffVideoHangup,
                  size: 18,
                  color: DefaultTheme.dangerColor,
                ),
              ),
            ),
          ],
        ),
      );
}
