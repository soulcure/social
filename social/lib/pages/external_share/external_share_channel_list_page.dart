import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/channel_icon.dart';

import '../../global.dart';
import 'external_share_model.dart';
import 'external_share_send_dialog.dart';

class ExternalShareChannelListPage extends StatefulWidget {
  final ExternalShareModel model;

  final GuildTarget guild;

  const ExternalShareChannelListPage(this.model, this.guild, {Key key})
      : super(key: key);

  @override
  _ExternalShareChannelListPageState createState() =>
      _ExternalShareChannelListPageState();
}

class _ExternalShareChannelListPageState
    extends State<ExternalShareChannelListPage> {
  Widget _buildChannel(ChatChannel channel, {VoidCallback onTap}) {
    final gp = PermissionModel.getPermission(channel.guildId);
    final bool isPrivate = PermissionUtils.isPrivateChannel(gp, channel.id);
    return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 52,
            child: Row(
              children: [
                ChannelIcon(
                  channel.type,
                  private: isPrivate,
                  color: const Color(0xFF8F959E),
                  size: 20,
                ),
                sizeWidth12,
                Text(
                  channel.name,
                  style: const TextStyle(
                      fontSize: 16,
                      height: 20.0 / 16.0,
                      color: Color(0xFF363940)),
                ),
              ],
            )));
  }

  List<ChatChannel> _guildChannels() {
    // 过滤掉分类，
    // 过滤掉dm
    // 过滤掉私密频道
    // 过滤掉当前用户没有发送权限的频道
    // final List<ChatChannel> list = [];
    final gp = PermissionModel.getPermission(widget.guild.id);
    return widget.guild.channels.where((c) {
      if (c.type == ChatChannelType.guildText) {
        final canSendMes = PermissionUtils.oneOf(gp, [Permission.SEND_MESSAGES],
            channelId: c.id);
        final bool isVisible = PermissionUtils.isChannelVisible(gp, c.id);
        if (isVisible && canSendMes) {
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final channels = _guildChannels();
    return Scaffold(
      appBar: CustomAppbar(
        title: '选择频道'.tr,
      ),
      body: SafeArea(
          child: ListView.separated(
              separatorBuilder: (context, index) => Divider(
                  indent: 48,
                  thickness: 0.5,
                  color: const Color(0xFF8F959E).withOpacity(0.2)),
              itemCount: channels.length,
              itemBuilder: (ctx, index) {
                final channel = channels.elementAt(index);
                return _buildChannel(channel, onTap: () async {
                  widget.model.selectChannel(channel);
                  final currContext = Global.navigatorKey.currentContext;
                  await showDialog(
                      context: currContext,
                      builder: (cxt) {
                        return ExternalShareSendDialog(
                          widget.model,
                          onConfirm: () {
                            Navigator.pop(cxt, true);
                            widget.model.share();
                          },
                          onCancel: () {
                            Navigator.pop(cxt, true);
                          },
                        );
                      },
                      barrierDismissible: false);
                });
              })),
    );
  }
}
