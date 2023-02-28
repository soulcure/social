import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/channel_icon.dart';
import 'package:im/widgets/realtime_user_info.dart';

import '../../../../../../icon_font.dart';

class RichEditorChannelListPage extends StatefulWidget {
  final void Function(ChatChannel channel) onSelect;
  final VoidCallback onClose;
  const RichEditorChannelListPage({@required this.onSelect, this.onClose});

  @override
  _RichEditorChannelListPageState createState() =>
      _RichEditorChannelListPageState();
}

class _RichEditorChannelListPageState extends State<RichEditorChannelListPage> {
  List<ChatChannel> channels;

  @override
  void initState() {
    final GuildPermission gp = PermissionModel.getPermission(
        ChatTargetsModel.instance.selectedChatTarget.id);
    channels = (ChatTargetsModel.instance.selectedChatTarget as GuildTarget)
        .channels
        .where((element) => PermissionUtils.isChannelVisible(gp, element.id))
        .toList(); //[dj private channel] 屏蔽掉私密频道
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget appBar;
    if (OrientationUtil.portrait) {
      appBar = CustomAppbar(
        title: '选择频道'.tr,
        leadingIcon: IconFont.buffNavBarCloseItem,
      );
    } else {
      appBar = CustomAppbar(
        title: '选择频道'.tr,
        leadingBuilder: (icon) => const SizedBox(),
        actions: [
          AppbarIconButton(
              onTap: () {
                widget.onClose?.call();
              },
              icon: IconFont.buffChatTextShrink,
              size: 18,
              color: CustomColor(context).disableColor)
        ],
      );
    }

    return Scaffold(
      appBar: appBar,
      body: ListView.builder(
        itemCount: channels.length,
        itemBuilder: (context, i) => _buildChannelItem(channels[i]),
      ),
    );
  }

  Widget _buildChannelItem(ChatChannel item) {
    final channel = item;
    if (channel.type == ChatChannelType.guildCategory) {
      return const SizedBox();
    }

    final gp = PermissionModel.getPermission(channel.guildId);
    final bool isPrivate = PermissionUtils.isPrivateChannel(gp, channel.id);

    final categoryName = _getChannelCateName(channel.parentId).tr;
    return FadeButton(
      height: 52,
      backgroundColor: Theme.of(context).backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: () {
        widget.onSelect?.call(item);
      },
      child: Row(
        children: <Widget>[
          Icon(
            ChannelIcon.getChannelTypeIcon(channel.type, isPrivate: isPrivate),
            size: 16,
            color: appThemeData.textTheme.bodyText2.color,
          ),
          const SizedBox(width: 6),
          Expanded(
              child: RealtimeChannelName(
            channel.id,
          )),
          if (categoryName != null) ...[
            const SizedBox(width: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: (MediaQuery.of(context).size.width - 32) / 2),
              child: Text(categoryName,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontSize: 12)),
            )
          ],
        ],
      ),
    );
  }

  String _getChannelCateName(String channelCateId) {
    final GuildTarget guild =
        ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    final selectedChannel = guild?.channels?.firstWhere(
        (element) => element.id == channelCateId,
        orElse: () => null);
    return selectedChannel?.name;
  }
}
