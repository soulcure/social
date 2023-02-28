import 'package:flutter/material.dart';
import 'package:im/hybrid/webrtc/room/base_room.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';

class AudioChatMemberItemRenderer extends StatelessWidget {
  final RoomUser memberInfo;

  const AudioChatMemberItemRenderer(this.memberInfo);

  @override
  Widget build(BuildContext context) {
    final BaseChatTarget selectedTarget =
        ChatTargetsModel.instance.selectedChatTarget;
    final bool isGuildOwner = selectedTarget is GuildTarget &&
        selectedTarget.ownerId == memberInfo.userId;

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GestureDetector(
          onTap: () {
            return showUserInfoPopUp(
              context,
              userId: memberInfo.userId,
              guildId: ChatTargetsModel.instance.selectedChatTarget.id,
              showRemoveFromGuild: true,
            );
          },
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 36,
                height: 36,
                child: Stack(
                  children: <Widget>[
                    RealtimeAvatar(userId: memberInfo.userId, size: 32),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: _buildVolumeIcon(
                          memberInfo.muted, memberInfo.talking),
                    ),
                  ],
                ),
              ),
              sizeWidth16,
              Flexible(
                child: RealtimeNickname(
                    userId: memberInfo.userId,
                    style: Theme.of(context).textTheme.bodyText2),
              ),
              if (isGuildOwner)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(IconFont.buffOtherStars,
                      color: Color(0xffFAA61A), size: 16),
                )
            ],
          ),
        ));
  }

  Widget _buildVolumeIcon(bool muted, bool talking) {
    if (muted) {
      return Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: Color(0xffF24848),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.mic_off,
          color: Colors.white,
          size: 10,
        ),
      );
    } else if (talking) {
      return Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: Color(0xff38BE2C),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.volume_up,
          color: Colors.white,
          size: 10,
        ),
      );
    } else {
      return null;
    }
  }
}
