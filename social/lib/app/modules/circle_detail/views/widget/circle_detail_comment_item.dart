import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/circle_detail_list_bean.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/common.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/show_portrait_circle_reply_popup.dart';
import 'package:im/pages/guild_setting/circle/component/circle_user_avatar.dart';
import 'package:im/pages/guild_setting/circle/component/circle_user_nickname.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/widgets/realtime_user_info.dart';

import '../../../../../global.dart';

class CircleDetailCommentItem extends StatelessWidget {
  final UserBean user;
  final CommentBean bean;
  final String content;
  final bool showLikeButton;
  final Widget likeButton;
  final String replyUserName;
  final String replayUserId;

  const CircleDetailCommentItem(this.user, this.bean, this.content,
      {Key key,
      this.showLikeButton = true,
      this.likeButton = sizedBox,
      this.replyUserName,
      this.replayUserId})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: replyUserName == null ? 36 : 24,
            child: CircleUserAvatar(
              user.userId,
              replyUserName == null ? 36 : 24,
              avatarUrl: user.avatar,
              tapToShowUserInfo: true,
              cacheManager: CircleCachedManager.instance,
              guildId: bean?.guildId,
            ),
          ),
          sizeWidth12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user != null)
                  CircleUserNickName(
                      user.userId,
                      const TextStyle(
                        color: Color(0xff5C6273),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      preferentialRemark: true,
                      guildId: bean?.guildId,
                      nickName: user.nickname),
                sizeHeight4,
                SizedBox(
                  width: double.infinity,
                  child: Text.rich(TextSpan(children: [
                    if (replyUserName?.isNotEmpty ?? false)
                      TextSpan(
                        text: '回复'.tr,
                        style: TextStyle(
                            color: Get.textTheme.bodyText2.color,
                            fontSize: 15,
                            height: 1.25),
                      ),
                    if (replayUserId.hasValue)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.top,
                        child: _checkBuildPrimaryColorBox(),
                      ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.top,
                      child: buildRichText(
                        content,
                        context,
                        padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                        style: const TextStyle(
                            // color: Get.theme.iconTheme.color,///h5显示不正常
                            color: Color(0xFF363940),
                            height: 1.25,
                            fontSize: 15),
                        guildId: bean?.guildId,
                      ),
                    )
                  ])),
                ),
                sizeHeight4,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(getTime(bean.createdAt),
                        style: TextStyle(
                            color: Get.theme.disabledColor, fontSize: 13)),
                    likeButton,
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  Widget _checkBuildPrimaryColorBox() {
    final atUserLayout = RealtimeNickname(
      prefix: "@",
      suffix: ':',
      userId: replayUserId,
      tapToShowUserInfo: true,
      guildId: bean?.guildId,
      showNameRule: ShowNameRule.remarkAndGuild,
      style: TextStyle(color: primaryColor, fontSize: 15, height: 1.25),
    );
    if (Global.user.id == replayUserId)
      return Container(
        // alignment: Alignment.center,
        // height: 23,
        margin: const EdgeInsets.fromLTRB(4, 0.5, 4, 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: primaryColor.withOpacity(0.15),
        ),
        child: atUserLayout,
      );
    else
      return atUserLayout;
  }
}
