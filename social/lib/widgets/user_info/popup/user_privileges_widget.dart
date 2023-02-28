import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/video/model/video_room_controller.dart';
import 'package:im/themes/const.dart';

class UserPrivilegesWidget extends StatefulWidget {
  final UserInfo user;
  final bool showRemoveFromGuild;
  final String channelId;
  final String videoId;

  const UserPrivilegesWidget(
      {Key key,
      this.user,
      this.channelId,
      this.videoId,
      this.showRemoveFromGuild = false})
      : super(key: key);

  @override
  _UserPrivilegesWidgetState createState() => _UserPrivilegesWidgetState();
}

class _UserPrivilegesWidgetState extends State<UserPrivilegesWidget> {
  bool hasMutePermission = false; //关麦权限
  bool hasBanMutePermission = false; //禁言权限
  bool hasKickMembersPermission = false; //踢人权限

  @override
  void initState() {
    super.initState();
  }

  List<Widget> _buildTitle() {
    final List<Widget> widgets = [];
    if (hasMutePermission || hasBanMutePermission || hasKickMembersPermission) {
      widgets.add(
        sizeHeight12,
      );
      widgets.add(Text(
        '视频频道管理'.tr,
        style: appThemeData.textTheme.caption.copyWith(fontSize: 12),
      ));
      widgets.add(
        sizeHeight10,
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    const _textColor = Color(0xFFF24848);
    const _textColor1 = Color(0xFF1F2126);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._buildTitle(),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Column(
            children: <Widget>[
              GetBuilder<VideoRoomController>(
                  id: VideoRoomController.muteMemberButtonObject,
                  tag: VideoRoomController.sRoomId,
                  builder: (c) {
                    final GuildPermission gp =
                        PermissionModel.getPermission(c.guildId);
                    hasMutePermission = PermissionUtils.oneOf(
                        gp, [Permission.MUTE_MEMBERS],
                        channelId: widget.channelId);
                    if (hasMutePermission) {
                      return FadeBackgroundButton(
                        onTap: () {
                          c.toggleMicrophone(widget.videoId);
                          Get.back();
                        },
                        backgroundColor: appThemeData.backgroundColor,
                        tapDownBackgroundColor: appThemeData
                            .scaffoldBackgroundColor
                            .withOpacity(0.5),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              IconFont.buffVideoMicOff,
                              color: Colors.black54,
                            ),
                            sizeWidth16,
                            Text(
                              '闭麦'.tr,
                              style: const TextStyle(
                                  color: _textColor1,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return const SizedBox();
                    }
                  }),
              if (hasMutePermission)
                const Divider(
                  height: 1,
                  color: Color(0x1A8D93A6),
                  indent: 16,
                ),
              GetBuilder<VideoRoomController>(
                  id: VideoRoomController.kickMemberButtonObject,
                  tag: VideoRoomController.sRoomId,
                  builder: (c) {
                    final GuildPermission gp =
                        PermissionModel.getPermission(c.guildId);
                    hasKickMembersPermission = PermissionUtils.oneOf(
                        gp, [Permission.KICK_MEMBERS],
                        channelId: widget.channelId); //需改
                    if (hasKickMembersPermission) {
                      return FadeBackgroundButton(
                          onTap: () {
                            c.toggleKickOutUser(widget.videoId);
                            Get.back();
                          },
                          backgroundColor: appThemeData.backgroundColor,
                          tapDownBackgroundColor: appThemeData
                              .scaffoldBackgroundColor
                              .withOpacity(0.5),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                IconFont.buffVideoMemberRemove,
                                color: _textColor,
                              ),
                              sizeWidth16,
                              Text(
                                '移出频道'.tr,
                                style: const TextStyle(
                                    color: _textColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 17),
                              ),
                            ],
                          ));
                    } else {
                      return const SizedBox();
                    }
                  }),
            ],
          ),
        ),
      ],
    );
  }
}
