import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/pages/guild/widget/guild_icon.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:im/widgets/user_info/popup/stack_pictures.dart';
import 'package:im/widgets/user_info/popup/view_model.dart';

// 用户的关联组件【共同服务器、共同好友】
class AssociatedWidget extends StatefulWidget {
  final UserInfo user;
  final bool showRemoveFromGuild;

  const AssociatedWidget({Key key, this.user, this.showRemoveFromGuild = false})
      : super(key: key);

  @override
  _AssociatedWidgetState createState() => _AssociatedWidgetState();
}

class _AssociatedWidgetState extends State<AssociatedWidget> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserInfoViewModel>(
        tag: widget.user.userId,
        id: UserInfoViewModel.associatedWidgetId,
        builder: (controller) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sizeHeight6,
              Text(
                '我们的关联'.tr,
                style: appThemeData.textTheme.caption.copyWith(fontSize: 12),
              ),
              sizeHeight10,
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Column(
                  children: <Widget>[
                    FadeBackgroundButton(
                      onTap: () {
                        Routes.pushCommonGuildPage(context, widget.user.userId);
                      },
                      backgroundColor: appThemeData.backgroundColor,
                      tapDownBackgroundColor:
                          appThemeData.scaffoldBackgroundColor.withOpacity(0.5),
                      child: ListTile(
                        title: Text(
                          '共同服务器'.tr,
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _buildCommonGuild(controller),
                            const MoreIcon(),
                          ],
                        ),
                      ),
                    ),
                    FadeBackgroundButton(
                      onTap: () {
                        Routes.pushCommonFriendPage(
                          context,
                          widget.user.userId,
                          hideGuildName: widget.showRemoveFromGuild,
                          guildId: controller.guildId,
                        );
                      },
                      backgroundColor: appThemeData.backgroundColor,
                      tapDownBackgroundColor:
                          appThemeData.scaffoldBackgroundColor.withOpacity(0.5),
                      child: ListTile(
                        title: Text(
                          '共同好友'.tr,
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _buildCommonFriend(controller),
                            const MoreIcon(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              sizeHeight12,
            ],
          );
        });
  }

  Widget _buildCommonGuild(UserInfoViewModel controller) {
    final commonGuilds = controller.commonGuilds ?? [];
    final tempList =
        commonGuilds.length >= 4 ? commonGuilds.getRange(0, 4) : commonGuilds;
    final List<Widget> widgetList = tempList.map((v) => GuildIcon(v)).toList();
    return StackPictures(
      totalNum: commonGuilds.length,
      itemShape: BoxShape.rectangle,
      children: widgetList,
    );
  }

  Widget _buildCommonFriend(UserInfoViewModel controller) {
    final tempList = controller.commonFriends.length >= 4
        ? controller.commonFriends.getRange(0, 4)
        : controller.commonFriends;
    final List<Widget> widgetList =
        tempList.map((v) => Avatar(radius: 12, url: v.avatar)).toList();
    return StackPictures(
      totalNum: controller.commonFriends.length,
      children: widgetList,
    );
  }
}
