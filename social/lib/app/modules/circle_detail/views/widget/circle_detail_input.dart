import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/models/circle_post_data_model.dart';
import 'package:im/app/modules/circle/models/circle_share_poster_model.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/mute/views/mute_listener_widget.dart';
import 'package:im/app/modules/share_circle/controllers/share_circle_controller.dart';
import 'package:im/app/modules/share_circle/views/share_circle.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/input_placeholder.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/like_button.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/show_circle_reply_popup.dart';
import 'package:im/pages/guild_setting/circle/circle_share/circle_share_widget.dart';
import 'package:im/pages/guild_setting/circle/component/all_like_grid.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:oktoast/oktoast.dart';

class CircleDetailInput extends StatelessWidget {
  final String topicId;
  final String guildId;
  final String channelId;
  final String postId;
  final String likeId;
  final CirclePostDataModel data;
  final OnReplySend onReplySend;
  final OnLikeChange<bool, String> onLikeChange;

  /// 生成海报需要
  final CircleDetailData circleDetailData;
  final Alignment alignment;

  const CircleDetailInput({
    Key key,
    this.topicId,
    this.guildId,
    this.channelId,
    this.postId,
    this.likeId,
    this.data,
    this.onReplySend,
    this.onLikeChange,
    this.circleDetailData,
    this.alignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                  top: BorderSide(
                      color: const Color(0xFF8D93A6).withOpacity(0.1),
                      width: 0.5))),
          child: Row(
            children: [
              Expanded(
                child: MuteListenerWidget(
                  builder: (isMuted, muteTime) {
                    return ValidPermission(
                      guildId: guildId,
                      channelId: topicId,
                      permissions: [Permission.CIRCLE_REPLY],
                      builder: (hasPermission, isOwner) {
                        return InputPlaceholder(
                          pageContext: Get.context,
                          guildId: guildId,
                          channelId: channelId,
                          hasPermission: hasPermission || isOwner,
                          isMuted: isMuted,
                          onReplySend: onReplySend,
                          commentId: postId,
                          alignment: alignment,
                        );
                      },
                    );
                  },
                ),
              ),
              ValidPermission(
                channelId: topicId,
                permissions: [Permission.CIRCLE_ADD_REACTION],
                builder: (hasPermission, isOwner) {
                  return GestureDetector(
                    onLongPress: () {
                      showBottomModal(Get.context,
                          margin: const EdgeInsets.all(0),
                          backgroundColor:
                              Theme.of(Get.context).backgroundColor,
                          builder: (c, s) => AllLikeGrid(
                                postId,
                                data?.postSubInfoDataModel?.likeTotal ?? 0,
                                guildId: guildId,
                              ));
                    },
                    child: CircleAniLikeButton(
                      // liked: likeByMyself,
                      // count: likeTotal,
                      hasPermission: hasPermission || isOwner,
                      padding: const EdgeInsets.only(left: 16, right: 12),
                      fontWeight: FontWeight.w500,
                      iconSize: 20,
                      unLikeColor: appThemeData.iconTheme.color,
                      onLikeChange: onLikeChange,
                      requestError: (code) {
                        if (code == postNotFound) {
                          showToast(postNotFoundToast);
                          // Future.delayed(const Duration(seconds: 1),
                          //     () => Navigator.of(context).pop(true));
                        }
                      },
                      count: int.parse(
                          data?.postSubInfoDataModel?.likeTotal ?? '0'),
                      liked: data?.postSubInfoDataModel?.iLiked == '1',
                      postData: PostData(
                          guildId: guildId,
                          channelId: channelId,
                          topicId: topicId,
                          postId: postId,
                          t: 'post',
                          likeId: likeId,
                          increaseLike:
                              data?.postSubInfoDataModel?.increaseLike ?? 0),
                    ),
                  );
                },
              ),
              ShareButton(
                data: data,
                // alignment: Alignment.center,
                size: 20,
                color: appThemeData.iconTheme.color,
                constraints: const BoxConstraints.expand(width: 24),
                padding: const EdgeInsets.only(right: 4),
                alignment: Alignment.centerLeft,
                sharePosterModel:
                    CircleSharePosterModel(circleDetailData: circleDetailData),
                isFromList: false,
              ),
              InkWell(
                onTap: () {
                  ShareCircle.showCircleShareDialog(
                    ShareBean(
                      data: data,
                      guildId: guildId,
                      sharePosterModel: CircleSharePosterModel(
                          circleDetailData: circleDetailData),
                      // isFromList: false,
                    ),
                  );
                },
                child: Text(
                  '分享'.tr,
                  style: TextStyle(
                      fontSize: 13,
                      color: appThemeData.iconTheme.color,
                      fontWeight: FontWeight.w500),
                ),
              ),
              sizeWidth12,
            ],
          ),
        ),
      );
}
