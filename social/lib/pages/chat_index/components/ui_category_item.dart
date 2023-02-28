import 'package:flutter/material.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/animated_icons/animated_expandable_icon.dart';
import 'package:im/db/db.dart';
import 'package:im/db/guild_table.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../../../icon_font.dart';
import '../../../routes.dart';

class UICategoryItem extends StatelessWidget {
  final ChatChannel channel;
  final GuildTarget model;
  final bool hasManagePermission;
  final ValueChanged<bool> onChange;
  const UICategoryItem({
    @required this.channel,
    @required this.model,
    @required this.hasManagePermission,
    this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(channel.id),
      padding: const EdgeInsets.only(bottom: 6),
      color: OrientationUtil.portrait
          ? Theme.of(context).backgroundColor
          : Colors.transparent,
      alignment: Alignment.bottomLeft,
      height: 34,
      child: ConstrainedBox(
        // 16 是右侧展开图标的高度
        constraints: const BoxConstraints(minHeight: 16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: AnimatedExpandableIcon(
                initialExpanded: channel.expanded,
                color: channel.expanded
                    ? Theme.of(context).textTheme.bodyText1.color
                    : primaryColor,
                size: 18,
                space: 4,
                follow: Row(
                  children: [
                    Expanded(
                      child: Text(
                        channel.name.breakWord ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: appThemeData.textTheme.caption
                            .copyWith(fontWeight: FontWeight.w500, height: 1.3),
                      ),
                    ),
                  ],
                ),
                onChange: (value) {
                  channel.expanded = value;
                  unawaited(Db.channelCollapseBox
                      .put(channel.id, (!value).toString()));
                  // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
                  model.notifyListeners();
                  onChange?.call(value);
                },
              ),
            ),
            if (hasManagePermission)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final Tuple2 rtn = await Routes.pushChannelCreation(
                      context,
                      (ChatTargetsModel.instance.selectedChatTarget
                              as GuildTarget)
                          .id,
                      cateId: channel.id);
                  final ChatChannel c = rtn?.item1;
                  if (c != null) {
                    final m =
                        Provider.of<BaseChatTarget>(context, listen: false)
                            as GuildTarget;

                    var index =
                        m.channels.indexWhere((e) => e.id == channel.id) + 1;
                    for (; index < m.channels.length; index++) {
                      if (m.channels[index].type ==
                          ChatChannelType.guildCategory) {
                        break;
                      }
                    }
                    if (!m.channelOrder.contains(c.id))
                      m.channelOrder.insert(index, c.id);
                    m.addChannel(c,
                        initPermissions:
                            rtn?.item2 as List<PermissionOverwrite>);

                    final gp = PermissionModel.getPermission(
                        ChatTargetsModel.instance.selectedChatTarget.id);
                    final isVisible =
                        PermissionUtils.isChannelVisible(gp, c.id);

                    final notJump = c.type == ChatChannelType.guildLink ||
                        c.type == ChatChannelType.guildLive ||
                        c.type == ChatChannelType.guildVoice ||
                        !isVisible;
                    unawaited(Db.channelBox.put(c.id, c));
                    if (!notJump)
                      unawaited(m.setSelectedChannel(c, notify: true));
                    // if(!isVisible){
                    //   unawaited(m.setSelectedChannel(null, notify: true));
                    // }
                    GuildTable.add(m);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    IconFont.buffTianjia,
                    size: 14,
                    color: Theme.of(context).textTheme.bodyText1.color,
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
