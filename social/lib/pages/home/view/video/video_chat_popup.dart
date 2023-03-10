import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_audio_manager/flutter_audio_manager.dart';
import 'package:get/get.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/hybrid/webrtc/room/multi_video_room.dart';
import 'package:im/hybrid/webrtc/room_manager.dart';
import 'package:im/pages/home/view/check_permission.dart';
import 'package:im/pages/video/model/video_room_controller.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/check_media_conflict_util.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/widgets/button/primary_button.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/share_link_popup/share_link_popup.dart';
import 'package:im/widgets/svg_tip_widget.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';
import 'package:im/widgets/user_info/realtime_nick_name.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../icon_font.dart';
import '../../../../routes.dart';
import '../../../../svg_icons.dart';
import '../../../../themes/const.dart';

class VideoChatPopup extends StatelessWidget {
  final String roomId;
  final Function(int) callback;

  const VideoChatPopup(this.roomId, {this.callback});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHead(context),
            _buildUserList(context),
            _buildBottomBar(context),
          ],
        ));
  }

  Widget _buildHead(BuildContext context) {
    return Container(
      height: 60,
      color: const Color(0xFFF5F5F8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const IconButton(
            padding: EdgeInsets.all(16),
            iconSize: 22,
            icon: Icon(
              IconFont.buffVideoCamera,
              color: Color(0xFF363940),
            ),
            onPressed: null,
          ),
          Expanded(
            child: GetBuilder<VideoRoomController>(
                key: Key(roomId),
                tag: VideoRoomController.sRoomId,
                id: VideoRoomController.headInfoObject,
                builder: (c) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        c.roomName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF363940)),
                      ),
                      sizeHeight2,
                      Text(c.guildName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              height: 1.25,
                              color: Color(0xFF8F959E))),
                    ],
                  );
                }),
          ),
          GetBuilder<VideoRoomController>(
              tag: VideoRoomController.sRoomId,
              id: VideoRoomController.invitedButtonObject,
              builder: (c) {
                final GuildPermission gp =
                    PermissionModel.getPermission(c.guildId);
                final hasInvitePermission = PermissionUtils.oneOf(
                    gp, [Permission.CREATE_INSTANT_INVITE],
                    channelId: roomId);
                if (!hasInvitePermission) return const SizedBox();
                return IconButton(
                  padding: const EdgeInsets.all(10),
                  visualDensity: const VisualDensity(
                      horizontal: VisualDensity.minimumDensity),
                  iconSize: 22,
                  icon: Icon(
                    IconFont.buffInviteUser,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () {
                    final channel = Db.channelBox.get(c.roomId);
                    showShareLinkPopUp(context, channel: channel);
                  },
                );
              }),
          GetBuilder<VideoRoomController>(
              tag: VideoRoomController.sRoomId,
              id: VideoRoomController.channelSettingObject,
              builder: (c) {
                final GuildPermission gp =
                    PermissionModel.getPermission(c.guildId);
                final hasManagePermission = PermissionUtils.oneOf(
                    gp, [Permission.MANAGE_CHANNELS],
                    channelId: roomId);
                if (!hasManagePermission) return const SizedBox();
                return IconButton(
                  padding: const EdgeInsets.all(10),
                  visualDensity: const VisualDensity(
                      horizontal: VisualDensity.minimumDensity),
                  iconSize: 22,
                  icon: Icon(
                    IconFont.buffSetting,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () {
                    final channel = Db.channelBox.get(c.roomId);
                    if (OrientationUtil.portrait) {
                      Routes.pushModifyChannelPage(context, channel);
                    } else {
                      Routes.pushChannelSetupPage(channel);
                    }
                  },
                );
              }),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildUserList(BuildContext context) {
    return GetBuilder<VideoRoomController>(
        tag: VideoRoomController.sRoomId,
        id: VideoRoomController.userListObject,
        builder: (c) {
          if (c.joined.value == JoinStatus.joinFail) {
            ///??????????????????????????????????????????????????????
            return _buildConnectFailWidget(c);
          }

          final GuildPermission gp = PermissionModel.getPermission(c.guildId);
          final hasInvitePermission = PermissionUtils.oneOf(
              gp, [Permission.CREATE_INSTANT_INVITE],
              channelId: roomId);
          final itemCount = c.users.isEmpty
              ? 0
              : (hasInvitePermission ? c.users.length + 1 : c.users.length);
          if (itemCount <= 0) {
            return _emptyUserWidget(context);
          } else {
            return ObxValue(
              (joined) {
                return Container(
                  height: joined.value == JoinStatus.joined ||
                          joined.value == JoinStatus.reconnect
                      ? 316
                      : 281,
                  color: Colors.white,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: itemCount,
                    itemBuilder: (context, idx) {
                      if (idx < c.users.length) {
                        return _buildUserItem(context, c.users[idx]);
                      } else if (idx == c.users.length) {
                        return _buildShareItem(context);
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                );
              },
              c.joined,
            );
          }
        });
  }

  Widget _buildUserItem(BuildContext context, VideoUser user) {
    return GetBuilder<VideoRoomController>(
      tag: VideoRoomController.sRoomId,
      builder: (c) {
        return Container(
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(
                  height: 55.5,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 13,
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: user.talking
                                  ? const Color(0xFF43B581)
                                  : Colors.white,
                              width: 1.5),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(19)),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            showUserInfoPopUp(
                              context,
                              userId: user.userId,
                              guildId: c.guildId,
                            );
                          },
                          child: RealtimeAvatar(
                            userId: user.userId,
                            size: 32,
                            showBorder: false,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 13,
                      ),
                      Expanded(
                          child: RealtimeNickname(
                        userId: user.userId,
                        showNameRule: ShowNameRule.remarkAndGuild,
                        guildId: c.guildId,
                        style: const TextStyle(
                            fontSize: 16,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF363940)),
                      )),
                      sizeWidth16,
                      GetBuilder<VideoRoomController>(
                          tag: VideoRoomController.sRoomId,
                          id: VideoRoomController.kickMemberButtonObject,
                          builder: (c) {
                            final GuildPermission gp =
                                PermissionModel.getPermission(c.guildId);
                            final hasMovePermission = PermissionUtils.oneOf(
                                gp, [Permission.MOVE_MEMBERS],
                                channelId: roomId);
                            if (!hasMovePermission) return const SizedBox();
                            if (c.joined.value == JoinStatus.unJoined)
                              return const SizedBox();
                            // ??????????????????
                            if (Global.user.id == user.userId)
                              return const SizedBox();
                            // ?????????????????????
                            if (PermissionUtils.isGuildOwner(
                                userId: user.userId,
                                guildId: c.guildId)) return const SizedBox();
                            // ?????????????????????????????????
                            // ???Id?????????roles
                            final roles =
                                Db.userInfoBox.get(user.userId)?.roles ?? [];
                            if (PermissionUtils.comparePosition(
                                    roleIds: roles) <=
                                0) return const SizedBox();

                            return IconButton(
                                padding: const EdgeInsets.all(11),
                                visualDensity: const VisualDensity(
                                    horizontal: VisualDensity.minimumDensity),
                                iconSize: 20,
                                icon: const Icon(
                                  IconFont.buffRemove,
                                  color: Color(0xFF646A73),
                                ),
                                onPressed: () async {
                                  final bool isConfirm =
                                      await showConfirmDialog(
                                    title: "????????????????????????????????????".tr,
                                    confirmStyle: Theme.of(context)
                                        .textTheme
                                        .bodyText2
                                        .copyWith(
                                            fontSize: 17,
                                            color: const Color(0xFF6179F2)),
                                  );
                                  if (isConfirm != null && isConfirm == true) {
                                    // c.toggleKickOutUser(user);
                                  }
                                });
                          }),
                      GetBuilder<VideoRoomController>(
                          tag: VideoRoomController.sRoomId,
                          id: VideoRoomController.muteMemberButtonObject,
                          builder: (c) {
                            final GuildPermission gp =
                                PermissionModel.getPermission(c.guildId);
                            final hasMutePermission = PermissionUtils.oneOf(
                                gp, [Permission.MUTE_MEMBERS],
                                channelId: roomId);
                            final canPress = (user.userId == Global.user.id) ||
                                (user.userId != Global.user.id &&
                                    !user.muted &&
                                    hasMutePermission); // ??????????????????????????????????????????
                            final double opacity = canPress ? 1 : 0.4;
                            return ObxValue<Rx<JoinStatus>>((v) {
                              if (v.value == JoinStatus.joined ||
                                  v.value == JoinStatus.reconnect) {
                                return IconButton(
                                    padding: const EdgeInsets.all(11),
                                    visualDensity: const VisualDensity(
                                        horizontal:
                                            VisualDensity.minimumDensity),
                                    iconSize: 20,
                                    icon: user.muted
                                        ? Icon(
                                            IconFont.buffMicrophoneOff,
                                            color: DefaultTheme.dangerColor
                                                .withOpacity(opacity),
                                          )
                                        : Icon(IconFont.buffMicrophoneOn,
                                            color: const Color(0xFF646A73)
                                                .withOpacity(opacity)),
                                    onPressed: canPress
                                        ? () {
                                            // c.toggleMicrophone(user: user);
                                          }
                                        : null);
                              } else {
                                return const SizedBox();
                              }
                            }, c.joined);
                          }),
                      sizeWidth6,
                    ],
                  ),
                ),
                Divider(
                  height: 0.5,
                  indent: 64,
                  color: const Color(0xFF8F959E).withOpacity(0.2),
                ),
              ],
            ));
      },
    );
  }

  Widget _buildShareItem(BuildContext context) {
    return GestureDetector(
      onTap: () {
        VideoRoomController c;
        try {
          c = Get.find<VideoRoomController>(tag: roomId);
        } catch (_) {
          return;
        }
        final channel = Db.channelBox.get(c.roomId);
        showShareLinkPopUp(context, channel: channel);
      },
      child: Container(
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(
                height: 55.5,
                child: Row(
                  children: [
                    sizeWidth16,
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF8F959E).withOpacity(0.15)),
                      child: const Icon(
                        IconFont.buffInviteUser,
                        color: Color(0xFF646A73),
                        size: 18,
                      ),
                    ),
                    sizeWidth16,
                    Expanded(
                        child: Text(
                      "????????????".tr,
                      style: const TextStyle(
                          fontSize: 16,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF363940)),
                    )),
                    sizeWidth16,
                  ],
                ),
              ),
              Divider(
                height: 0.5,
                indent: 64,
                color: const Color(0xFF8F959E).withOpacity(0.2),
              ),
            ],
          )),
    );
  }

  Widget _emptyUserWidget(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 281,
      child: Row(
        children: [
          sizeWidth32,
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                WebsafeSvg.asset(
                  SvgIcons.audioUserEmpty,
                  width: 140,
                  height: 140,
                ),
                sizeHeight16,
                Text(
                  "??????????????????????????????????????????".tr,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: const TextStyle(
                      fontSize: 14, height: 1.4, color: Color(0xFF646A73)),
                ),
                sizeHeight5,
              ],
            ),
          ),
          sizeWidth32,
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    VideoRoomController c;
    try {
      c = Get.find<VideoRoomController>(tag: VideoRoomController.sRoomId);
    } catch (_) {
      return Container();
    }
    return ObxValue(
      (joined) {
        if (joined.value == JoinStatus.joined ||
            joined.value == JoinStatus.reconnect) {
          return const SizedBox(); //_buildBottomControllerBar(context);
        } else {
          return _buildBottomEnterBar(context);
        }
      },
      c.joined,
    );
  }

  Widget _buildBottomEnterBar(BuildContext context) {
    return GetBuilder<VideoRoomController>(
        tag: VideoRoomController.sRoomId,
        id: VideoRoomController.joinRoomButtonObject,
        builder: (c) {
          final channel = Db.channelBox.get(c.roomId);
          if (channel == null) return const SizedBox();
          final GuildPermission gp = PermissionModel.getPermission(c.guildId);
          final hasManagerPermission =
              PermissionUtils.oneOf(gp, [Permission.MANAGE_CHANNELS]);
          final hasJoinPermission = PermissionUtils.oneOf(
              gp, [Permission.CONNECT],
              channelId: channel.id);
          final userLimit = channel.userLimit ?? 10;
          final curUserId = Global.user.id;
          bool isExist = false;
          //??????????????????????????????????????????
          for (int i = 0; i < c.users.length; i++) {
            final user = c.users[i];
            if (user.userId == curUserId) {
              isExist = true;
              break;
            }
          }

          bool canJoin = false;
          if (isExist) {
            //????????????????????????????????????????????????????????? '??????????????????'.tr
            canJoin = true;
          } else {
            canJoin = userLimit == -1 ||
                c.users.length < userLimit ||
                hasManagerPermission;
          }
          return Container(
            height: 91,
            decoration: BoxDecoration(
                color: const Color(0xFFF5F5F8),
                border: Border(
                    top: BorderSide(
                        color: const Color(0xFF8F959E).withOpacity(0.2),
                        width: 0.5))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    sizeHeight12,
                    Text(
                      "????????????????????????????????????".tr,
                      style: const TextStyle(
                          fontSize: 12, height: 1.25, color: Color(0xFF646A73)),
                    ),
                    sizeHeight12,
                    PrimaryButton(
                      label: canJoin ? '??????????????????'.tr : '????????????'.tr,
                      enabled: canJoin && hasJoinPermission,
                      textStyle: const TextStyle(fontSize: 16, height: 1.25),
                      height: 40,
                      width: 295,
                      borderRadius: 5,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      loading: c.joined.value == JoinStatus.joining,
                      onPressed: () async {
                        if (canJoin) {
                          final canGotoAVChannel = await checkAndExitLiveRoom();
                          if (!canGotoAVChannel) {
                            /// ???????????????????????????????????????????????????
                            return;
                          }
                          try {
                            await c.joinVideoRoom();
                          } catch (e) {
                            if (e.toString() == RoomManager.premissError) {
                              if (OrientationUtil.portrait) {
                                unawaited(checkSystemPermissions(
                                  context: context,
                                  permissions: [
                                    permission_handler.Permission.microphone
                                  ],
                                  onRejectedCancel: () {
                                    Get.back();
                                  },
                                ));
                              } else {
                                showToast("????????????????????????".tr);
                              }
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        });
  }

  ///???????????? ?????? ????????????
  Widget _buildConnectFailWidget(VideoRoomController c) {
    return Container(
      height: 281,
      color: Colors.white,
      alignment: Alignment.center,
      child: SvgTipWidget(
        svgName: SvgIcons.noNetState,
        text: '?????????????????????'.tr,
        desc: '???????????????????????????????????????\n????????????????????????',
      ),
    );
  }

  static IconData getAudioIconData(AudioPort port) {
    switch (port) {
      case AudioPort.receiver:
        return IconFont.buffOutputReceiver;
      case AudioPort.speaker:
        return IconFont.buffLoudspeaker;
      case AudioPort.headphones:
        return IconFont.buffAudioVisualHeadset;
      case AudioPort.bluetooth:
        return IconFont.buffOutputBluetooth;
      default:
        return IconFont.buffAudioVisualVolumeUp;
    }
  }

  static String getAudioName(AudioPort port) {
    switch (port) {
      case AudioPort.receiver:
        return "????????????".tr;
      case AudioPort.speaker:
        return "???????????????".tr;
      case AudioPort.headphones:
        return "??????".tr;
      case AudioPort.bluetooth:
        return "??????".tr;
      default:
        return "?????????";
    }
  }

  // // ????????????
  // Widget _buildAudioOutputWidget(BuildContext context) {
  //   VideoRoomController c;
  //   try {
  //     c = Get.find<VideoRoomController>(tag: VideoRoomController.sRoomId);
  //   } catch (_) {
  //     return Container();
  //   }
  //   return TextButton(
  //     onPressed: () => c.stream.add(ButtonType.toggleOutPut),
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         ObxValue<Rx<AudioInput>>((v) {
  //           return Icon(
  //             VideoChatPopup.getAudioIconData(v.value.port),
  //             size: 24,
  //             color: const Color(0xFF646A73),
  //           );
  //         }, c.audioOutput),
  //         ObxValue<Rx<AudioInput>>((v) {
  //           return Text(
  //             VideoChatPopup.getAudioName(v.value.port),
  //             style: const TextStyle(
  //                 fontSize: 10, height: 1.4, color: Color(0xFF646A73)),
  //           );
  //         }, c.audioOutput),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildBottomControllerBar(BuildContext context) {
  //   VideoRoomController c;
  //   try {
  //     c = Get.find<VideoRoomController>(tag: VideoRoomController.sRoomId);
  //   } catch (_) {
  //     return Container();
  //   }
  //   return Container(
  //     height: 56,
  //     decoration: BoxDecoration(
  //         color: const Color(0xFFF5F5F8),
  //         border: Border(
  //             top: BorderSide(
  //                 color: const Color(0xFF8F959E).withOpacity(0.2),
  //                 width: 0.5))),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceAround,
  //       children: [
  //         Expanded(child: _buildAudioOutputWidget(context)),
  //         Expanded(
  //           child: TextButton(
  //             onPressed: () {
  //               c.stream.add(ButtonType.quit);
  //               if (callback != null) callback(1);
  //             },
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 const Icon(
  //                   IconFont.buffAudioRoomQuit,
  //                   size: 24,
  //                   color: DefaultTheme.dangerColor,
  //                 ),
  //                 Text(
  //                   "????????????".tr,
  //                   style: const TextStyle(
  //                       fontSize: 10,
  //                       height: 1.4,
  //                       color: DefaultTheme.dangerColor),
  //                 )
  //               ],
  //             ),
  //           ),
  //         ),
  //         Expanded(
  //           child: TextButton(
  //             onPressed: () {
  //               c.stream.add(ButtonType.toggleMicro);
  //             },
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 ObxValue<RxBool>((v) {
  //                   if (v.value) {
  //                     return const Icon(
  //                       IconFont.buffMicrophoneOff,
  //                       size: 24,
  //                       color: DefaultTheme.dangerColor,
  //                     );
  //                   } else {
  //                     return const Icon(IconFont.buffMicrophoneOn,
  //                         size: 24, color: Color(0xFF646A73));
  //                   }
  //                 }, c.muted),
  //                 ObxValue<RxBool>((v) {
  //                   if (v.value) {
  //                     return Text(
  //                       "???????????????".tr,
  //                       style: const TextStyle(
  //                           fontSize: 10,
  //                           height: 1.4,
  //                           color: DefaultTheme.dangerColor),
  //                     );
  //                   } else {
  //                     return Text(
  //                       "???????????????".tr,
  //                       style: const TextStyle(
  //                           fontSize: 10,
  //                           height: 1.4,
  //                           color: Color(0xFF646A73)),
  //                     );
  //                   }
  //                 }, c.muted),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
