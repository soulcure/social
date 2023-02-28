import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/text_chat/text_chat_ui_creator.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/check_square_box.dart';
import 'package:im/widgets/mouse_hover_builder.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/user_role_card/role_badge.dart';

import '../../../icon_font.dart';

class DocMemberItemRenderer extends StatelessWidget {
  final UserInfo user;
  final Color color;
  final String channelId;
  final String guildId;
  final ValueChanged<bool> toggleSelect;
  final bool isSelected;

  const DocMemberItemRenderer(
    this.user, {
    this.color,
    this.channelId,
    this.guildId,
    this.toggleSelect,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => toggleSelect?.call(null),
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: OrientationUtil.portrait ? 16 : 8),
        child: MouseHoverBuilder(builder: (context, selected) {
          return Container(
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
              toggleSelect: toggleSelect,
              isSelected: isSelected,
            ),
          );
        }),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final UserInfo user;
  final Color color;
  final String channelId;
  final bool isSelected;
  final ValueChanged<bool> toggleSelect;

  const _Item(
    this.user, {
    this.color,
    this.channelId,
    this.isSelected = false,
    this.toggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    var style = Theme.of(context).textTheme.bodyText1;
    if (color != null) style = style.copyWith(color: color);

    final ChatChannel channel = Db.channelBox.get(channelId);
    final String guildId =
        channel?.guildId ?? ChatTargetsModel.instance?.selectedChatTarget?.id;
    return Row(
      children: <Widget>[
        IgnorePointer(
          child: CheckSquareBox(
            value: isSelected,
            onChanged: toggleSelect,
          ),
        ),
        sizeWidth12,
        if (isNotNullAndEmpty(user.avatarNft))
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              children: [
                Avatar(
                  url: user.avatarNft,
                  radius: 20,
                ),
                _buildDaoFlag(12),
              ],
            ),
          )
        else
          Avatar(
            url: user.avatar,
            radius: 20,
          ),
        const SizedBox(
          width: 16,
        ),
        RoleBadge(user.userId, guildId, channelId),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                //  添加备注修改监听
                ValueListenableBuilder(
                  valueListenable: Db.remarkBox.listenable(keys: [user.userId]),
                  builder: (context, value, child) => Flexible(
                    child: RealtimeNickname(userId: user.userId),
                  ),
                ),
                if (user.isBot) ...[sizeWidth4, TextChatUICreator.botMark],
              ],
            ),
            sizeHeight4,
            Text(
              '#${user.username}',
              style: const TextStyle(
                color: Color(0xFF8F959E),
                fontSize: 13,
              ),
            ),
          ],
        )
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
