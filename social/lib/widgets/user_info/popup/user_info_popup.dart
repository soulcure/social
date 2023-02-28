import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/global.dart';
import 'package:im/global_methods/goto_direct_message.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/bot_market/widget/bot_description.dart';
import 'package:im/pages/home/view/text_chat/text_chat_ui_creator.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/user.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/pages/member_list/userinfo_dialog.dart';
import 'package:im/widgets/id_with_copy.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/user_info/fb_nick_name.dart';
import 'package:im/widgets/user_info/popup/user_privileges_widget.dart';
import 'package:im/widgets/user_info/popup/view_model.dart';

import 'associated_widget.dart';
import 'friend_request_widget.dart';
import 'interactive_widget.dart';
import 'slot_list_widget.dart';

// showRemoveFromGuild 是否显示从服务器移除按钮，默认不显示
Future<void> showUserInfoPopUp(
  BuildContext context, {
  String userId,
  String videoId,
  String guildId,
  String channelId,
  UserInfo userInfo,
  bool showRemoveFromGuild = false,
  bool hideGuildName = false,
  EnterType enterType = EnterType.fromDefault,
  bool showRemoveMember = true,
}) async {
  // final context = Global.navigatorKey.currentContext;
  if (UniversalPlatform.isMobileDevice)
    await showBottomModal(
      context,
      builder: (c, s) => UserInfoPopup(
        userId: userId,
        userInfo: userInfo,
        videoId: videoId,
        guildId: guildId,
        channelId: channelId,
        context: context,
        showRemoveFromGuild: showRemoveFromGuild,
        enterType: enterType,
        hideGuildName: hideGuildName,
        showRemoveMember: showRemoveMember,
      ),
      backgroundColor: appThemeData.backgroundColor,
      resizeToAvoidBottomInset: false,
      showHalf: true,
    );
  else {
    await UserInfo.get(userId).then((userInfo) {
      showUserinfoDialog(context, userInfo);
    });
  }
}

Widget userInfoComponent(BuildContext context, String userId,
    {String guildId}) {
  if (UniversalPlatform.isMobileDevice) {
    return UserInfoPopup(userId: userId, guildId: guildId, buildHeadOnly: true);
  } else {
    return const SizedBox();
  }
}

void _toModifyUserInfo(BuildContext context) {
  Get.back();
  Routes.pushModifyUserInfoPage(context);
}

class UserInfoPopup extends StatefulWidget {
  final String userId;
  final String videoId;
  final bool showRemoveFromGuild;
  final bool hideGuildName;
  final EnterType enterType;
  final String guildId;
  final UserInfo userInfo;
  final String channelId;
  final bool buildHeadOnly;
  final BuildContext context;
  final bool showRemoveMember;

  const UserInfoPopup({
    @required this.guildId,
    this.userId,
    this.userInfo,
    this.videoId,
    this.channelId,
    this.showRemoveFromGuild = false,
    this.hideGuildName = false,
    this.buildHeadOnly = false,
    this.enterType,
    this.context, // 机器人用的
    this.showRemoveMember,
  });

  @override
  _UserInfoPopupState createState() => _UserInfoPopupState();
}

class _UserInfoPopupState extends State<UserInfoPopup> {
  //  问题链接：https://www.tapd.cn/53785969/bugtrace/bugs/view/1153785969001135456
  String previousRoute;

  /// 首页用户卡片机器人指令展示条件，使用入口目前有三处
  /// 1、聊天公屏消息发送者头像
  /// 2、聊天公屏消息@包含的用户
  /// 3、成员列表头像
  ///
  bool get shouldShowBotCommand {
    return previousRoute == app_pages.Routes.HOME ||
        previousRoute == directChatViewRoute;
  }

  @override
  void initState() {
    previousRoute = Get.previousRoute;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userInfo?.userId ?? widget.userId;
    final isSelf = Global.user.id == userId;
    final bool showRemoveMember = widget.showRemoveMember;
    return GetBuilder<UserInfoViewModel>(
        init: UserInfoViewModel(
            uId: widget.userId,
            gId: widget.guildId,
            userInfo: widget.userInfo,
            showRemoveFromGuild: widget.showRemoveFromGuild),
        tag: userId,
        builder: (controller) {
          return UserInfo.consume(controller.userId,
              guildId: widget.guildId, placeHolder: _placeHolderWidget(),
              builder: (context, user, widget) {
            return Stack(
              children: <Widget>[
                ListView(
                  padding: const EdgeInsets.only(top: 4),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildProfile(user, controller),
                    sizeHeight16,
                    if (isSelf) ..._buildSelfContent(user, controller),
                    if (!isSelf) ..._buildContent(user, controller),
                  ],
                ),
                if (!isSelf)
                  Positioned(
                    right: 16,
                    top: 0,
                    child: SizedBox(
                      height: 24,
                      width: 36,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          IconFont.buffMoreHorizontal,
                          color: appThemeData.textTheme.bodyText2.color,
                        ),
                        onPressed: () => controller.onMoreAction(user,
                            showRemoveMember: showRemoveMember),
                      ),
                    ),
                  )
              ],
            );
          });
        });
  }

  Widget _placeHolderWidget() {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: const SizedBox(
        height: 40,
        width: 40,
        child: CircularProgressIndicator(),
      ),
    );
  }

  // 用户头像等信息
  Widget _buildProfile(UserInfo user, UserInfoViewModel controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (user.userId != Global.user.id) sizeHeight24,
          Row(
            children: [
              RealtimeAvatar(
                userId: user.userId,
                size: 72,
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: <Widget>[
                          Flexible(
                              child: RealtimeNickname(
                            initName: user.nickname ?? '',
                            userId: user.userId,
                            style: appThemeData.textTheme.bodyText2.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                height: 1.25),
                            maxLines: 2,
                            guildId: controller.guildId,
                          )),
                          if (user.isBot) ...[
                            const SizedBox(
                              width: 6,
                            ),
                            TextChatUICreator.botMark
                          ],
                          sizeWidth10,
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: getGenderIcon(user.gender, size: 16),
                          ),
                          sizeWidth10,
                        ],
                      ),
                      if (isShowNick(widget.guildId, user.userId))
                        FBNickname(
                          padding: const EdgeInsets.only(top: 8),
                          userId: user.userId,
                          style: TextStyle(
                              color: Get.theme.disabledColor, fontSize: 14),
                          prefix: "昵称: ".tr,
                          guildId: widget.guildId,
                        ),
                      const SizedBox(height: 4),
                      IdWithCopy(user.username),
                    ],
                  ),
                ),
              ),
              if (user.isBot || user.userId == Global.user.id)
                _buildDmButton(user.userId),
            ],
          ),
          // 机器人描述
          if (user.isBot) ...[
            sizeHeight16,
            BotDescription(
              botId: user.userId,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildContent(UserInfo user, UserInfoViewModel controller) {
    return [
      // Bot不需要展示的UI部分
      if (!user.isBot) InteractiveWidget(user: user),

      if (!widget.buildHeadOnly) ...[
        const Divider(
          thickness: 0.5,
        ),
        Container(
          color: appThemeData.scaffoldBackgroundColor,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FriendRequestWidget(user: user),
              SlotListWidget(
                user: user,
                guildId: controller.guildId,
                channelId: widget.channelId,
                enterType: widget.enterType,
                showRoleSlot: !controller.hideGuildInfo,
                showRobotSlot: user.isBot && shouldShowBotCommand,
              ),
              if (!user.isBot)
                AssociatedWidget(
                    user: user,
                    showRemoveFromGuild: widget.showRemoveFromGuild),
              if (widget.enterType == EnterType.fromVideo)
                UserPrivilegesWidget(
                    user: user,
                    channelId: widget.channelId,
                    videoId: widget.videoId,
                    showRemoveFromGuild: widget.showRemoveFromGuild),
              if (widget.enterType == EnterType.fromVideo) sizeHeight20,
              SizedBox(
                height: getBottomViewInset(),
              )
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildSelfContent(UserInfo user, UserInfoViewModel controller) {
    final double bottomOffset = widget.buildHeadOnly ? 0 : getBottomViewInset();
    return [
      Container(
        color: appThemeData.scaffoldBackgroundColor,
        padding: EdgeInsets.fromLTRB(16, 24, 16, 24 + bottomOffset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SlotListWidget(
              parentContext: widget.context,
              user: user,
              guildId: controller.guildId,
              channelId: widget.channelId,
              enterType: widget.enterType,
              showRoleSlot: !controller.hideGuildInfo,
            ),
            sizeHeight20,
            FadeBackgroundButton(
              height: 48,
              borderRadius: 8,
              backgroundColor: appThemeData.backgroundColor,
              tapDownBackgroundColor:
                  appThemeData.scaffoldBackgroundColor.withOpacity(0.5),
              onTap: () => _toModifyUserInfo(context),
              child: Text(
                '编辑资料'.tr,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  //头像右侧的私信按钮
  Widget _buildDmButton(String user) {
    return FadeButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: appThemeData.scaffoldBackgroundColor),
      onTap: () {
        Get.back();
        gotoDirectMessageChat(user);
      },
      child: Text(
        '私信',
        style: appThemeData.textTheme.bodyText1.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

///表示点击头像的来源
enum EnterType {
  ///没有特殊说明，默认值
  fromDefault,

  ///表示从服务器成员列表点击头像
  fromServer,

  ///表示从圈子点击头像
  fromCircle,

  ///表示从视频频道点击头像
  fromVideo
}
