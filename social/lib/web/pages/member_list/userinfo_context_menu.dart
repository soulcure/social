import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/app/modules/friend_list_page/controllers/friend_list_page_controller.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/friend/relation.dart';
import 'package:im/pages/friend/widgets/relation_utils.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/member_list/model/member_list_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/web/pages/member_list/modify_remark_page.dart';
import 'package:im/web/pages/member_list/userinfo_dialog.dart';
import 'package:im/web/pages/setting/member_manage_page.dart';
import 'package:im/web/utils/show_web_tooltip.dart';
import 'package:im/web/widgets/button/web_hover_button.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:oktoast/oktoast.dart';

import 'viewmodel/userinfo_viewmodel.dart';

void showUserInfoContextMenu(
    BuildContext context, PointerDownEvent e, String userId) {
  showWebTooltip(context,
      globalPoint: e.position,
      minimumOutSidePadding: 4,
      containsBackgroundOverlay: false,
      popupDirection: TooltipDirection.followMouse, builder: (context, done) {
    return UserInfoContextMenu(
      userId: userId,
      closeCallback: () => done(null),
    );
  });
}

enum ClickEvent {
  personal,
  setRemarks,
  addFriend,
  deleteFriend,
  cancelAddFriend,
  chat,
  copy,
  kickOut,
  report,
  shield,
  unShield,
  distributeRole
}

class UserInfoContextMenu extends StatefulWidget {
  final String userId;
  final VoidCallback closeCallback;

  const UserInfoContextMenu({this.userId, this.closeCallback});

  @override
  _UserInfoContextMenuState createState() => _UserInfoContextMenuState();
}

class _UserInfoContextMenuState extends State<UserInfoContextMenu> {
  UserinfoViewmodel _viewModel;

  @override
  void initState() {
    _viewModel = UserinfoViewmodel(userId: widget.userId);
    super.initState();
  }

  Widget _item(
      {@required String title,
      @required void Function(BuildContext) done,
      bool showArrow = false,
      bool dangerousOperation = false}) {
    final color = dangerousOperation
        ? Theme.of(context).errorColor
        : Theme.of(context).textTheme.bodyText2.color;
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: WebHoverButton(
            align: Alignment.centerLeft,
            hoverColor: Theme.of(context).disabledColor.withOpacity(0.2),
            onTap: () => done?.call(context),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            borderRadius: 4,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title ?? '',
                    style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w400),
                  ),
                ),
                if (showArrow) const MoreIcon(),
              ],
            )),
      );
    });
  }

  void handleCallback(
      BuildContext context, UserInfo userInfo, ClickEvent event) {
    switch (event) {
      case ClickEvent.personal:
        showUserinfoDialog(context, userInfo);
        break;
      case ClickEvent.setRemarks:
        showDialog(
            context: context,
            builder: (context) {
              return ModifyRemarkPage(
                userId: widget.userId,
                nickName: userInfo.nickname,
              );
            });
        break;
      case ClickEvent.addFriend:
        _viewModel.applyFriendRequest();
        break;
      case ClickEvent.deleteFriend:
        FriendListPageController.to.remove(widget.userId);
        break;
      case ClickEvent.cancelAddFriend:
        _viewModel.cancelFriendRequest(context);
        break;
      case ClickEvent.chat:
        _viewModel.directChat();
        break;
      case ClickEvent.copy:
        Clipboard.setData(ClipboardData(text: userInfo.username));
        showToast("#号已复制".tr);
        break;
      case ClickEvent.kickOut:
        _removeMember(userInfo);
        break;
      case ClickEvent.report:
        _viewModel.reportFriend(context, userInfo);
        break;
      case ClickEvent.shield:
        _viewModel.shieldFriend(context);
        break;
      case ClickEvent.unShield:
        _viewModel.shieldFriend(context);
        break;
      case ClickEvent.distributeRole:
        final guildId = ChatTargetsModel.instance.selectedChatTarget?.id;
        MemberManagePage.distributeGuildRole(
            context: context,
            guildId: guildId,
            offsetX: -4,
            popupDirection: TooltipDirection.leftTop,
            userId: widget.userId);
        break;
    }
    if (ClickEvent.distributeRole != event) widget.closeCallback?.call();
  }

  @override
  Widget build(BuildContext context) {
    final relation = RelationUtils.getRelation(widget.userId);
    final isFriend = relation == RelationType.friend;
    final isApplyPending = [
      RelationType.pendingOutgoing,
      RelationType.pendingIncoming
    ].contains(relation);
    return UserInfo.consume(widget.userId, builder: (context, user, widget) {
      return Container(
        width: 190,
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            sizeHeight8,
            if (!isSelf)
              _item(
                  title: '个人资料'.tr,
                  done: (context) =>
                      handleCallback(context, user, ClickEvent.personal)),
            if (!isSelf)
              _item(
                  title: '设置备注名'.tr,
                  done: (context) =>
                      handleCallback(context, user, ClickEvent.setRemarks)),
            if (!isFriend && !isApplyPending && !isSelf)
              _item(
                  title: '添加好友'.tr,
                  done: (context) =>
                      handleCallback(context, user, ClickEvent.addFriend)),
            if (!isSelf)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: divider,
              ),
            if (!isSelf)
              _item(
                  title: '私信'.tr,
                  done: (context) =>
                      handleCallback(context, user, ClickEvent.chat)),
            if (!isSelf)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: divider,
              ),
            _item(
                title: '复制ID'.tr,
                done: (context) =>
                    handleCallback(context, user, ClickEvent.copy)),
            if (!isSelf)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: divider,
              ),
            if (!isSelf && isFriend)
              _item(
                  title: '删除好友'.tr,
                  dangerousOperation: true,
                  done: (context) =>
                      handleCallback(context, user, ClickEvent.deleteFriend)),
            if (!isSelf && !isFriend && isApplyPending)
              _item(
                  title: '撤回好友请求'.tr,
                  dangerousOperation: true,
                  done: (context) => handleCallback(
                      context, user, ClickEvent.cancelAddFriend)),
            if (!isSelf && cankickOut(user))
              _item(
                  title: '移出服务器'.tr,
                  dangerousOperation: true,
                  done: (context) =>
                      handleCallback(context, user, ClickEvent.kickOut)),
            if (!isSelf && !isInBlacklist)
              _item(
                  title: '屏蔽'.tr,
                  dangerousOperation: true,
                  done: (context) =>
                      handleCallback(context, user, ClickEvent.shield)),
            if (!isSelf && isInBlacklist)
              _item(
                  title: '解除屏蔽'.tr,
                  dangerousOperation: true,
                  done: (context) =>
                      handleCallback(context, user, ClickEvent.unShield)),
            if (!isSelf)
              _item(
                  title: '举报'.tr,
                  dangerousOperation: true,
                  done: (context) =>
                      handleCallback(context, user, ClickEvent.report)),
            if (ChatTargetsModel.instance.selectedChatTarget?.id != null &&
                (PermissionUtils.isGuildOwner(userId: Global.user.id) ||
                    PermissionUtils.comparePosition(roleIds: user.roles) ==
                        1)) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: divider,
              ),
              _item(
                  title: '分配角色'.tr,
                  showArrow: true,
                  done: (context) =>
                      handleCallback(context, user, ClickEvent.distributeRole))
            ]
          ],
        ),
      );
    });
  }

  Future<void> _removeMember(UserInfo user) async {
    final res = await showConfirmDialog(
      title: '移出成员'.tr,
      content: '确定移出服务器成员 %s ？移出后，该成员可以通过新的邀请链接再加入。'.trArgs([user.showName()]),
    );
    if (res) {
      await GuildApi.removeUser(
        guildId: ChatTargetsModel.instance.selectedChatTarget.id,
        userId: Global.user.id,
        userName: user.showName(),
        memberId: widget.userId,
        showDefaultErrorToast: false,
        isOriginDataReturn: true,
      );

      await MemberListModel.instance.remove(widget.userId);

      // TextChannelController.to().segmentMemberListModel?.updateUserInfo(user);

      if (widget.closeCallback != null)
        widget.closeCallback();
      else
        Get.back();
    }
  }

  bool get isSelf => Global.user.id == widget.userId;

  bool cankickOut(UserInfo user) {
    if (ChatTargetsModel.instance.selectedChatTarget?.id == null) return false;
    final gp = Db.guildPermissionBox
        .get(ChatTargetsModel.instance.selectedChatTarget?.id);
    if (isSelf ||
        PermissionUtils.isGuildOwner(userId: widget.userId) ||
        PermissionUtils.comparePosition(roleIds: user.roles) != 1 ||
        gp == null ||
        !PermissionUtils.oneOf(gp, [Permission.KICK_MEMBERS])) return false;
    return true;
  }

  bool get isInBlacklist =>
      FriendListPageController.to.blackListIsContain(widget.userId);
}
