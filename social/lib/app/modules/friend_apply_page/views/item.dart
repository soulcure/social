import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/relation_api.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/modules/friend_apply_page/controllers/friend_apply_page_controller.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/pages/friend/relation.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/pages/member_list/user_info_profile.dart';
import 'package:im/web/pages/member_list/userinfo_context_menu.dart';
import 'package:im/web/widgets/context_menu_detector.dart';
import 'package:im/widgets/circle_icon.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';
import 'package:im/widgets/user_info/realtime_nick_name.dart';
import 'package:oktoast/oktoast.dart';

import '../../../../icon_font.dart';

class FriendApplyItem extends StatelessWidget {
  final FriendApply request;

  const FriendApplyItem({Key key, this.request}) : super(key: key);

  Widget _portraitItem(BuildContext context) {
    String requestText = '';
    switch (request.relationType) {
      case RelationType.pendingIncoming:
        requestText = '收到的好友请求'.tr;
        break;
      case RelationType.pendingOutgoing:
        requestText = '发出的好友请求'.tr;
        break;
      default:
    }
    return FadeBackgroundButton(
      tapDownBackgroundColor:
          Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
      onTap: () => showUserInfoPopUp(context, userId: request.userId),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: <Widget>[
            UserInfo.consume(
              request.userId,
              builder: (context, user, widget) => RealtimeAvatar(
                userId: user.userId,
                size: 48,
              ),
            ),
            sizeWidth16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  UserInfo.consume(
                    request.userId,
                    builder: (context, user, widget) =>
                        RealtimeNickname(userId: user.userId),
                  ),
                  sizeHeight5,
                  Text(
                    '${formatDate2Str(DateTime.fromMillisecondsSinceEpoch(request.time * 1000))}   $requestText',
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        .copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Visibility(
                visible: request.relationType == RelationType.pendingOutgoing,
                child: Row(
                  children: <Widget>[
                    CircleIcon(
                      icon: IconFont.buffChatWithdraw,
                      size: 16,
                      color: Theme.of(context).textTheme.bodyText1.color,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      radius: 14,
                      onTap: () => _cancel(request.userId),
                    ),
                  ],
                )),
            Visibility(
              visible: request.relationType == RelationType.pendingIncoming,
              child: Row(
                children: <Widget>[
                  CircleIcon(
                    icon: IconFont.buffAudioVisualRight,
                    size: 16,
                    color: Colors.green,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    radius: 14,
                    onTap: () => _agree(request.userId),
                  ),
                  sizeWidth16,
                  CircleIcon(
                    icon: IconFont.buffNavBarCloseItem,
                    size: 12,
                    color: DefaultTheme.dangerColor,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    radius: 14,
                    onTap: () => _refuse(request.userId),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _landscapeItem(BuildContext context) {
    String requestText = '';
    switch (request.relationType) {
      case RelationType.pendingIncoming:
        requestText = '收到的好友请求'.tr;
        break;
      case RelationType.pendingOutgoing:
        requestText = '发出的好友请求'.tr;
        break;
      default:
    }
    return ContextMenuDetector(
      onContextMenu: (e) => showUserInfoContextMenu(context, e, request.userId),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: <Widget>[
            Builder(builder: (context) {
              return GestureDetector(
                onTap: () => showUserInfoProfile(context, request.userId, null,
                    offsetX: 8, tooltipDirection: TooltipDirection.rightTop),
                child: RealtimeAvatar(
                  userId: request.userId,
                  size: 48,
                ),
              );
            }),
            sizeWidth16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  UserInfo.consume(
                    request.userId,
                    builder: (context, user, widget) =>
                        RealtimeNickname(userId: user.userId),
                  ),
                  sizeHeight5,
                  Text(
                    '${formatDate2Str(DateTime.fromMillisecondsSinceEpoch(request.time * 1000))}   $requestText',
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        .copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Visibility(
                visible: request.relationType == RelationType.pendingOutgoing,
                child: Row(
                  children: <Widget>[
                    CircleIcon(
                      icon: IconFont.buffChatWithdraw,
                      size: 16,
                      color: Theme.of(context).textTheme.bodyText1.color,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      radius: 14,
                      onTap: () => _cancel(request.userId),
                    ),
                  ],
                )),
            Visibility(
              visible: request.relationType == RelationType.pendingIncoming,
              child: Row(
                children: <Widget>[
                  CircleIcon(
                    icon: IconFont.buffAudioVisualRight,
                    size: 16,
                    color: Colors.green,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    radius: 14,
                    onTap: () => _agree(request.userId),
                  ),
                  sizeWidth16,
                  CircleIcon(
                    icon: IconFont.buffNavBarCloseItem,
                    size: 12,
                    color: DefaultTheme.dangerColor,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    radius: 14,
                    onTap: () => _refuse(request.userId),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationUtil.portrait
        ? _portraitItem(context)
        : _landscapeItem(context);
  }

  Future<void> _cancel(String userId) async {
    await FriendApplyPageController.to.cancel(userId);
  }

  Future<void> _refuse(String userId) async {
    await FriendApplyPageController.to.refuse(userId);
    showToast('已忽略对方的好友请求'.tr);
  }

  Future<void> _agree(String userId) async {
    await FriendApplyPageController.to.agree(userId);
    //接受添加好友请求后，如果未创建dm频道,则创建
    await DirectMessageController.to.createChannel(userId);
    showToast('已通过对方的好友请求'.tr);
  }
}
