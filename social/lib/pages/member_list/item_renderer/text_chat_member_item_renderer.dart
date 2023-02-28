import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/role_bean.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/text_chat/text_chat_ui_creator.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/pages/member_list/user_info_profile.dart';
import 'package:im/web/pages/member_list/userinfo_context_menu.dart';
import 'package:im/web/widgets/context_menu_detector.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/mouse_hover_builder.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';
import 'package:im/widgets/user_role_card/role_badge.dart';

import '../../../icon_font.dart';

class TextChatMemberItemRenderer extends StatelessWidget {
  final UserInfo user;
  final Color color;
  final String channelId;
  final String guildId;

  const TextChatMemberItemRenderer(this.user,
      {this.color, this.channelId, this.guildId});

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTap: () {
        if (OrientationUtil.portrait) {
          // todo: 做个测试
          showUserInfoPopUp(
            context,
            guildId: guildId ?? ChatTargetsModel.instance.selectedChatTarget.id,
            userInfo: user,
            channelId: channelId ?? GlobalState.selectedChannel.value?.id,
            showRemoveFromGuild: true,
            enterType:
                GlobalState.selectedChannel.value?.type == ChatChannelType.dm
                    ? EnterType.fromDefault
                    : EnterType.fromServer,
          );
        } else {
          RoleBean.update(user.userId,
              ChatTargetsModel.instance.selectedChatTarget?.id, user.roles);
          showUserInfoProfile(context, user.userId,
              ChatTargetsModel.instance.selectedChatTarget?.id,
              offsetX: -8);
        }
      },
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: OrientationUtil.portrait ? 16 : 8),
        child: MouseHoverBuilder(builder: (context, selected) {
          return Container(
              height: OrientationUtil.portrait ? 52 : 42,
              padding: EdgeInsets.symmetric(
                  horizontal: OrientationUtil.portrait ? 0 : 8),
              decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).dividerTheme.color
                      : Theme.of(context).backgroundColor),
              child: _Item(
                user,
                color: color,
                channelId: channelId,
              ));
        }),
      ),
    );
    if (OrientationUtil.portrait) return child;
    return ContextMenuDetector(
      onContextMenu: (e) => showUserInfoContextMenu(context, e, user.userId),
      child: child,
    );
  }
}

class _Item extends StatelessWidget {
  final UserInfo user;
  final Color color;
  final String channelId;

  const _Item(this.user, {this.color, this.channelId});

  @override
  Widget build(BuildContext context) {
    var style = Theme.of(context).textTheme.bodyText1;
    if (color != null) style = style.copyWith(color: color);

    final ChatChannel channel = Db.channelBox.get(channelId);
    final String guildId =
        channel?.guildId ?? ChatTargetsModel.instance?.selectedChatTarget?.id;

    return Row(
      children: <Widget>[
        if (isNotNullAndEmpty(user.avatarNft))
          SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              children: [
                Avatar(
                  url: user.avatarNft,
                  radius: 16,
                ),
                _buildDaoFlag(12),
              ],
            ),
          )
        else
          Avatar(
            url: user.avatar,
            radius: 16,
          ),
        const SizedBox(
          width: 16,
        ),
        RoleBadge(user.userId, guildId, channelId),
        //  添加备注修改监听
        ValueListenableBuilder(
          valueListenable: Db.remarkBox.listenable(keys: [user.userId]),
          builder: (context, value, child) => Flexible(
            child: Text(
              // 根据服务端获取名称：备注 > 服务端昵称 > 个人昵称
              (user.markName != null && user.markName.isNotEmpty)
                  ? user.markName
                  : user.guildNickNames[guildId] ?? user.nickname,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (user.isBot) ...[sizeWidth4, TextChatUICreator.botMark],
      ],
    );
  }

  /// - 构建数字藏品标识,头像/标识 = 3
  Align _buildDaoFlag(double size) {
    return Align(
      alignment: Alignment.bottomRight,
      child: SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(1.5),
            child: ClipOval(
              child: Container(
                color: Colors.blue,
                child: Icon(
                  IconFont.buffDaoFlag,
                  size: size - 6,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
