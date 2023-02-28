import 'package:flutter/material.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/wallet/views/user_dao_card_view.dart';
import 'package:im/widgets/user_info/popup/bot_solt.dart';
import 'package:im/widgets/user_info/popup/role_slot.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';
import 'package:im/widgets/user_role_card/user_role_card.dart';

//  用户信息的卡槽列表
class SlotListWidget extends StatelessWidget {
  final BuildContext parentContext;
  final UserInfo user;
  final String guildId;
  final String channelId;
  final EnterType enterType;
  final bool showRoleSlot;
  final bool showRobotSlot;

  const SlotListWidget({
    Key key,
    this.parentContext,
    this.user,
    this.guildId,
    this.channelId,
    this.enterType,
    this.showRoleSlot = false,
    this.showRobotSlot = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UserDaoCardView(user: user),
        if (showRobotSlot)
          BotSlot(
            parentContext: parentContext,
            user: user,
            guildId: guildId,
            channelId: channelId,
          ),
        UserRoleCard(
            user: user,
            guildId: guildId,
            channelId: channelId,
            enterType: enterType),
        if (showRoleSlot)
          RoleSlot(
            userId: user.userId,
            guildId: guildId,
          ),
      ],
    );
  }
}
