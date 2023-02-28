import 'package:flutter/material.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/web/pages/member_list/user_info_profile.dart';
import 'package:im/web/pages/member_list/userinfo_context_menu.dart';
import 'package:im/web/widgets/context_menu_detector.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/shape/row_bottom_border.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';

class FriendItem extends StatelessWidget {
  final String userId;

  const FriendItem({Key key, this.userId}) : super(key: key);

  Widget _portraitWidget(BuildContext context) {
    return FadeBackgroundButton(
      tapDownBackgroundColor:
          Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
      onTap: () =>
          showUserInfoPopUp(context, userId: userId, hideGuildName: true),
      child: Container(
        height: 64,
        padding: const EdgeInsets.fromLTRB(16, 12, 50, 12),
        decoration: const ShapeDecoration(
          shape: RowBottomBorder(leading: 68),
        ),
        child: UserInfo.consume(
          userId,
          builder: (context, user, widget) => Row(
            children: [
              RealtimeAvatar(
                userId: user.userId,
                size: 40,
              ),
              sizeWidth12,
              Expanded(
                child: RealtimeNickname(
                  userId: userId,
                  showNameRule: ShowNameRule.remark,
                ),
              ),
              sizeWidth16,
            ],
          ),
        ),
      ),
    );
  }

  Widget _landscapeWidget(BuildContext context) {
    return ContextMenuDetector(
      onContextMenu: (e) => showUserInfoContextMenu(context, e, userId),
      child: Container(
        height: 72,
        padding: const EdgeInsets.fromLTRB(16, 12, 50, 12),
        child: UserInfo.consume(
          userId,
          builder: (context, user, widget) => Row(
            children: [
              Builder(builder: (context) {
                return GestureDetector(
                  onTap: () => showUserInfoProfile(context, userId, null,
                      offsetX: 8, tooltipDirection: TooltipDirection.rightTop),
                  child: RealtimeAvatar(
                    userId: user.userId,
                    size: 40,
                  ),
                );
              }),
              sizeWidth12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RealtimeNickname(
                      userId: userId,
                      showNameRule: ShowNameRule.remark,
                    ),
                    sizeHeight4,
                    Text(
                      user.username,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8F959E)),
                    )
                  ],
                ),
              ),
              sizeWidth16,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationUtil.portrait
        ? _portraitWidget(context)
        : _landscapeWidget(context);
  }
}
