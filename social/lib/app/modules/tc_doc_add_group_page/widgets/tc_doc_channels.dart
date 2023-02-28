import 'package:flutter/material.dart';
import 'package:im/app/modules/tc_doc_add_group_page/controllers/tc_doc_add_group_page_controller.dart';
import 'package:im/app/modules/tc_doc_add_group_page/entities/tc_doc_group.dart';
import 'package:im/app/modules/tc_doc_add_group_page/widgets/tc_doc_group_mixin.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

class TcDocChannels extends StatefulWidget {
  final TcDocAddGroupPageController controller;
  const TcDocChannels(this.controller);

  @override
  State<TcDocChannels> createState() => _TcDocChannelsState();
}

class _TcDocChannelsState extends State<TcDocChannels>
    with AutomaticKeepAliveClientMixin, TcDocGroupMixin {
  List<ChatChannel> _channels;
  @override
  void initState() {
    final chatTarget =
        ChatTargetsModel.instance.getChatTarget(widget.controller.guildId);
    if (chatTarget is GuildTarget) {
      _channels =
          widget.controller.filterChannels(chatTarget.getViewSendChannels());
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView.separated(
        itemBuilder: (c, i) {
          return _buildItem(_channels[i]);
        },
        separatorBuilder: (c, i) => const Divider(
              thickness: 0.5,
              indent: 50,
            ),
        itemCount: _channels.length);
  }

  Widget _buildItem(ChatChannel channel) {
    final isPrivate = PermissionUtils.isPrivateChannel(
        PermissionModel.getPermission(channel.guildId), channel.id);
    return GestureDetector(
      onTap: () {
        widget.controller.toggleSelect(channel.id, TcDocGroupType.channel);
      },
      child: Container(
        height: 52,
        color: appThemeData.backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                ...buildLeading(
                    widget.controller, channel.id, TcDocGroupType.channel),
                Icon(
                  isPrivate
                      ? IconFont.buffSimiwenzipindao
                      : IconFont.buffWenzipindaotubiao,
                  size: 20,
                  color: appThemeData.iconTheme.color,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    channel.name,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],
            ),
            // sizeHeight16,
            // Divider(
            //     indent: 50,
            //     height: 0.5,
            //     color: const Color(0xFF8F959E).withOpacity(0.15))
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
