import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/video/model/video_room_controller.dart';
import 'package:im/themes/const.dart';

import '../../../icon_font.dart';
import '../../../routes.dart';

void showVideoMorePopUp(
  BuildContext context, {
  String userId,
  String guildId,
  String channelId,
}) {
  Get.bottomSheet(VideoMorePopup(channelId: channelId),
      backgroundColor: const Color(0xFFF5F5F8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10), topRight: Radius.circular(10)),
      ),
      isScrollControlled: false);
}

class VideoMorePopup extends StatefulWidget {
  final String channelId;

  const VideoMorePopup({Key key, this.channelId}) : super(key: key);

  @override
  _VideoMorePopupState createState() => _VideoMorePopupState();
}

class _VideoMorePopupState extends State<VideoMorePopup> {
  VideoRoomController _videoRoomController;
  bool hasManagePermission = false; //管理频道权限
  bool hasMutePermission = false; //全员闭麦权限

  @override
  void initState() {
    _videoRoomController = Get.find<VideoRoomController>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const _textColor = Color(0xFF1F2126);
    const _textColor1 = Color(0xFFF24848);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDropTag,
        Container(
          margin: const EdgeInsets.only(left: 16, top: 20, right: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FadeBackgroundButton(
              onTap: () async {
                await _videoRoomController?.closeAndDispose("视频聊天已结束".tr);
                Get.back();
                Get.back();
              },
              backgroundColor: appThemeData.backgroundColor,
              tapDownBackgroundColor:
                  appThemeData.scaffoldBackgroundColor.withOpacity(0.5),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  const Icon(
                    IconFont.buffVideoHangup,
                    color: _textColor1,
                  ),
                  sizeWidth16,
                  Text(
                    '断开连接'.tr,
                    style: const TextStyle(
                        color: _textColor1,
                        fontWeight: FontWeight.w500,
                        fontSize: 17),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 16, top: 12, right: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FadeBackgroundButton(
              onTap: () {
                _videoRoomController?.toggleRoomMute();
              },
              backgroundColor: appThemeData.backgroundColor,
              tapDownBackgroundColor:
                  appThemeData.scaffoldBackgroundColor.withOpacity(0.5),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Obx(() {
                    return Icon(
                        _videoRoomController.roomMute.value
                            ? IconFont.buffAudioVisualVolumeClose
                            : IconFont.buffAudioVisualVolumeUp,
                        color: Colors.black54);
                  }),
                  sizeWidth16,
                  Obx(() {
                    return Text(
                      _videoRoomController.roomMute.value ? "取消静音" : "静音",
                      style: const TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 17),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 16, top: 12, right: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GetBuilder<VideoRoomController>(
                id: VideoRoomController.muteMemberButtonObject,
                builder: (c) {
                  final GuildPermission gp =
                      PermissionModel.getPermission(c.guildId);
                  hasMutePermission = PermissionUtils.oneOf(
                      gp, [Permission.MUTE_MEMBERS],
                      channelId: widget.channelId);
                  if (hasMutePermission) {
                    return FadeBackgroundButton(
                      onTap: () {
                        _videoRoomController?.muteRoom();
                        Get.back();
                      },
                      backgroundColor: appThemeData.backgroundColor,
                      tapDownBackgroundColor:
                          appThemeData.scaffoldBackgroundColor.withOpacity(0.5),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            IconFont.buffVideoMicOff,
                            color: Colors.black54,
                          ),
                          sizeWidth16,
                          Text(
                            '全员闭麦'.tr,
                            style: const TextStyle(
                                color: _textColor,
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
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 16, top: 12, right: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: <Widget>[
                // GetBuilder<VideoRoomController>(
                //     id: VideoRoomController.muteMemberButtonObject,
                //     builder: (c) {
                //       final GuildPermission gp =
                //           PermissionModel.getPermission(c.guildId);
                //       // final hasMutePermission = PermissionUtils.oneOf(
                //       //     gp, [Permission.MUTE_MEMBERS],
                //       //     channelId: widget.channelId);
                //       const hasMutePermission = true;
                //       if (hasMutePermission) {
                //         return FadeBackgroundButton(
                //             onTap: () {},
                //             backgroundColor: appThemeData.backgroundColor,
                //             tapDownBackgroundColor: appThemeData
                //                 .scaffoldBackgroundColor
                //                 .withOpacity(0.5),
                //             padding: const EdgeInsets.all(16),
                //             child: Row(
                //               children: [
                //                 Text('音频设备'.tr,
                //                     style: const TextStyle(
                //                         fontWeight: FontWeight.w500,
                //                         fontSize: 17)),
                //               ],
                //             ));
                //       } else {
                //         return const SizedBox();
                //       }
                //     }),
                // if (hasManagePermission)
                //   const Divider(
                //     height: 1,
                //     color: Color(0x1A8D93A6),
                //     indent: 16,
                //   ),
                GetBuilder<VideoRoomController>(
                    id: VideoRoomController.channelSettingObject,
                    builder: (c) {
                      final GuildPermission gp =
                          PermissionModel.getPermission(c.guildId);
                      hasManagePermission = PermissionUtils.oneOf(
                          gp, [Permission.MANAGE_CHANNELS],
                          channelId: widget.channelId); //需改;
                      if (hasManagePermission) {
                        return FadeBackgroundButton(
                            onTap: () {
                              final channel = Db.channelBox.get(c.roomId);
                              Routes.pushModifyChannelPage(context, channel);
                            },
                            backgroundColor: appThemeData.backgroundColor,
                            tapDownBackgroundColor: appThemeData
                                .scaffoldBackgroundColor
                                .withOpacity(0.5),
                            child: const ListTile(
                              title: Text('频道设置',
                                  style: TextStyle(
                                      color: _textColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 17)),
                              trailing: Icon(Icons.keyboard_arrow_right),
                            ));
                      } else {
                        return const SizedBox();
                      }
                    }),
              ],
            ),
          ),
        ),
        sizeHeight44
      ],
    );
  }

  Widget get _buildDropTag => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color: Get.textTheme.bodyText1.color.withOpacity(0.2),
              borderRadius: const BorderRadius.all(Radius.circular(4))),
        ),
      );
}
