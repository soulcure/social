import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/controllers/audio_room_controller.dart';
import 'package:im/core/widgets/button/base_button.dart';
import 'package:im/hybrid/webrtc/room/audio_room.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/home_page.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/only.dart';
import 'package:im/widgets/realtime_user_info.dart';

import '../../../../global.dart';

class AudioBar extends StatelessWidget {
  final String roomId;

  const AudioBar(this.roomId);

  @override
  Widget build(BuildContext context) {
    int _currTimeMillis = 0;
    return GetBuilder<AudioRoomController>(
      key: Key(roomId),
      tag: roomId,
      id: AudioRoomController.audioBarObject,
      builder: (c) {
        // logger.info("AudioBar c:${c.roomName},${c.roomId}");
        if (c.joined.value == JoinStatus.unJoined) return const SizedBox();

        ///显示用户头像的顺序：正在说话的 -> 最后说话的 -> users[0]
        AudioUser item =
            c.users.firstWhere((e) => e.talking, orElse: () => null);
        final item0 = c.users[0];
        item ??= c.users
            .firstWhere((e) => e.userId == Global.user.id, orElse: () => item0);
        return BaseButton(
          onTap: () {
            final tmpCurrentMillis = DateTime.now().millisecondsSinceEpoch;
            if (tmpCurrentMillis - _currTimeMillis < 800) {
              _currTimeMillis = tmpCurrentMillis;
            } else {
              _currTimeMillis = tmpCurrentMillis;
              RestoreMediaChannelViewNotification().dispatch(context);
            }
          },
          child: Container(
            width: 90,
            height: 138.5,
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    RealtimeAvatar(userId: item.userId, size: 48),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Only(
                        showIndex: item.talking ? 1 : 0,
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
                    userId: item.userId,
                    textAlign: TextAlign.center,
                    showNameRule: ShowNameRule.remarkAndGuild,
                    guildId: c.guildId,
                    style: const TextStyle(
                        fontSize: 13, height: 1.3, color: Color(0xFF363940)),
                    // style: Theme.of(context).textTheme.bodyText2,
                  ),
                ),
                const SizedBox(height: 11),
                divider,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    InkWell(
                      onTap: () {
                        c.stream.add(ButtonType.toggleMicro);
                      },
                      // 静音状态
                      child: Container(
                        padding: const EdgeInsets.only(
                            top: 8, bottom: 8, right: 13.5),
                        child: ObxValue((isMuted) {
                          return Icon(
                            isMuted.value
                                ? IconFont.buffMicrophoneOff
                                : IconFont.buffMicrophoneOn,
                            color: isMuted.value
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
                        c.closeAndDispose(msg: "语音聊天已结束".tr, flag: 4);
                      },
                      child: Container(
                        padding: const EdgeInsets.only(
                            top: 8, bottom: 8, left: 13.5),
                        child: const Icon(
                          IconFont.buffAudioRoomQuit,
                          size: 18,
                          color: DefaultTheme.dangerColor,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
