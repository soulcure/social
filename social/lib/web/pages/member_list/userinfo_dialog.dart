import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/friend_list_page/controllers/friend_list_page_controller.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/friend/common_friend_page.dart';
import 'package:im/pages/friend/relation.dart';
import 'package:im/pages/friend/widgets/relation_utils.dart';
import 'package:im/pages/guild/common_guild_page.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/web/widgets/popup/web_popup.dart';
import 'package:im/widgets/id_with_copy.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:pedantic/pedantic.dart';

import 'viewmodel/userinfo_viewmodel.dart';

Future showUserinfoDialog(BuildContext context, UserInfo userInfo) {
  return showDialog(
      context: context,
      builder: (context) => UserinfoDialog(
            userInfo: userInfo,
          ));
}

class UserinfoDialog extends StatefulWidget {
  final UserInfo userInfo;

  const UserinfoDialog({this.userInfo});

  @override
  _UserinfoDialogState createState() => _UserinfoDialogState();
}

class _UserinfoDialogState extends State<UserinfoDialog> {
  UserinfoViewmodel _viewModel;

  @override
  void initState() {
    _viewModel = UserinfoViewmodel(userId: widget.userInfo.userId);
    super.initState();
  }

  Future<void> _onMore(BuildContext context) async {
    final relation = RelationUtils.getRelation(widget.userInfo.userId);
    final isInBlacklist =
        FriendListPageController.to.blackListIsContain(widget.userInfo.userId);
    final dangerousTextStyle = Theme.of(context)
        .textTheme
        .bodyText2
        .copyWith(fontSize: 12, color: Theme.of(context).errorColor);

    final index = await showWebSelectionPopup(context,
        padding: const EdgeInsets.all(8),
        width: 148,
        offsetX: 8,
        popupDirection: TooltipDirection.rightTop,
        actions: [
//          if (RelationType.friend == relation)
//            const SelectionAction(IconFont.buffChannelMessageSolid, '私信'.tr, 0),
          if (isInBlacklist) SelectionAction(IconFont.webShield, '解除屏蔽'.tr, 5),
          if (RelationType.friend == relation)
            SelectionAction(IconFont.buffChatDelete, '删除好友'.tr, 1,
                textStyle: dangerousTextStyle),
//          if ([RelationType.none, RelationType.unrelated,RelationType.pendingIncoming].contains(relation))
//            const SelectionAction(IconFont.webSetupInvite, '添加好友'.tr, 2),
          if (RelationType.pendingOutgoing == relation)
            SelectionAction(IconFont.buffAudioVisualWithdraw, '撤回好友请求'.tr, 3,
                textStyle: dangerousTextStyle),
          if (!isInBlacklist)
            SelectionAction(IconFont.webShield, '屏蔽'.tr, 4,
                textStyle: dangerousTextStyle),
          SelectionAction(IconFont.webAccusation, '举报'.tr, 6,
              textStyle: dangerousTextStyle),
        ]);
    switch (index) {
      case 0:
        _viewModel.directChat();
        break;
      case 1:
        await FriendListPageController.to.remove(widget.userInfo.userId);
        break;
      case 2:
        unawaited(_viewModel.applyFriendRequest());
        break;
      case 3:
        unawaited(_viewModel.cancelFriendRequest(context));
        break;
      case 4:
        unawaited(_viewModel.shieldFriend(context));
        break;
      case 5:
        unawaited(_viewModel.shieldFriend(context));
        break;
      case 6:
        _viewModel.reportFriend(context, widget.userInfo);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 800,
        height: 532,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Theme.of(context).scaffoldBackgroundColor),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      margin: const EdgeInsets.only(right: 24),
                      child: RealtimeAvatar(
                        userId: widget.userInfo.userId,
                        size: 80,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.userInfo.nickname,
                                style: const TextStyle(
                                    color: Color(0xFF1F2125),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                              ),
                              Container(
                                width: 16,
                                height: 16,
                                margin: const EdgeInsets.only(left: 4),
                                decoration: BoxDecoration(
                                    color: widget.userInfo.gender == 1
                                        ? const Color(0xFF677CE6)
                                        : const Color(0xFFE900FE),
                                    borderRadius: BorderRadius.circular(4)),
                                child: Icon(
                                  widget.userInfo.gender == 1
                                      ? IconFont.buffTabMale
                                      : IconFont.buffTabFemale,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ],
                          ),
                          sizeHeight12,
                          IdWithCopy(widget.userInfo.username),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: Global.user.id != widget.userInfo.userId,
                      child: RelationUtils.consumer(widget.userInfo.userId,
                          builder: (context, type, widget) {
                        final bool isApplyPending = [
                          RelationType.pendingOutgoing,
                          RelationType.pendingIncoming
                        ].contains(type);
                        final text = type == RelationType.friend
                            ? '私信'.tr
                            : (isApplyPending ? '待通过'.tr : '添加好友'.tr);
                        return ObxValue<RxBool>((loading) {
                          if (loading.value)
                            return SizedBox(
                                height: 32,
                                width: 88,
                                child: DefaultTheme.defaultLoadingIndicator(
                                    size: 8));
                          return GestureDetector(
                            onTap: () {
                              if (type == RelationType.friend) {
                                _viewModel.directChat();
                              } else if (isApplyPending) {
                                _viewModel.cancelFriendRequest(context);
                              } else {
                                _viewModel.applyFriendRequest();
                              }
                            },
                            child: Container(
                              height: 32,
                              width: 88,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                  color: (type != RelationType.friend &&
                                          isApplyPending)
                                      ? const Color(0xFFFF8800)
                                      : Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(4)),
                              alignment: Alignment.center,
                              child: Text(
                                text,
                                style: const TextStyle(
                                    fontSize: 14, color: Color(0xFFFFFFFF)),
                              ),
                            ),
                          );
                        }, _viewModel.loading);
                      }),
                    ),
                    Visibility(
                      visible: Global.user.id != widget.userInfo.userId,
                      child: Builder(builder: (context) {
                        return IconButton(
                          onPressed: () => _onMore(context),
                          iconSize: 20,
                          icon: const Icon(IconFont.buffMoreHorizontal),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _contentPopUp(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _contentPopUp() {
    // TabController mController;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: SizedBox(
              width: 220,
              child: TabBar(
                tabs: <Widget>[
                  Tab(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text('共同服务器'.tr),
                    ),
                  ),
                  Tab(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text('共同好友'.tr),
                    ),
                  ),
                ],
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 36),
                unselectedLabelStyle: Theme.of(context)
                    .textTheme
                    .bodyText1
                    .copyWith(fontWeight: FontWeight.bold),
                unselectedLabelColor:
                    Theme.of(context).textTheme.bodyText1.color,
                labelStyle: Theme.of(context)
                    .textTheme
                    .bodyText2
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(
            height: 342,
            child: TabBarView(
              children: [
                CommonGuildPage(widget.userInfo.userId),
                CommonFriendPage(widget.userInfo.userId)
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: camel_case_types
class commonService extends StatefulWidget {
  const commonService({Key key}) : super(key: key);

  @override
  _commonService createState() => _commonService();
}

// ignore: camel_case_types
class _commonService extends State<commonService> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Text('页面1'.tr),
    );
  }
}

// ignore: camel_case_types
class commonFriends extends StatefulWidget {
  const commonFriends({Key key}) : super(key: key);

  @override
  _commonFriends createState() => _commonFriends();
}

// ignore: camel_case_types
class _commonFriends extends State<commonFriends> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Text('页面2'.tr),
    );
  }
}
