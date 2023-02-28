import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/models/circle_share_poster_model.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/circle_detail/views/widget/circle_detail_article_topic.dart';
import 'package:im/app/modules/circle_detail/views/widget/circle_detail_reload_layout.dart';
import 'package:im/app/modules/share_circle/controllers/share_circle_controller.dart';
import 'package:im/app/modules/share_circle/views/share_circle.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/appbar_action_button.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';

import '../../../../icon_font.dart';
import 'abstract_circle_detail_factory.dart';

class PortraitCircleDetailFactory extends AbstractCircleDetailFactory {
  @override
  Widget showAppBar(CircleDetailController controller, {BuildContext context}) {
    return FbAppBar.circleInfo(actionsBuilder: (context) {
      return [
        ObxValue((v) {
          // 加载的圈圈
          if (v?.value ?? false) {
            return loadingCircle(22, margin: const EdgeInsets.only(right: 16));
          } else {
            if (!controller.initialError)
              return AppBarIconActionButton(
                actionModel: AppBarIconActionModel(
                  IconFont.buffChatForwardNew,
                  actionBlock: () {
                    ///分享按钮的回调
                    ShareCircle.showCircleShareDialog(
                      ShareBean(
                        data: controller.data,
                        guildId: controller.guildId,
                        sharePosterModel: CircleSharePosterModel(
                            circleDetailData: controller.circleDetailData),
                      ),
                    );
                  },
                ),
              );
            else
              return sizedBox;
          }
        }, controller.showLoading),
        ObxValue((v) {
          if (v?.value ?? false) {
            return loadingCircle(22, margin: const EdgeInsets.only(right: 16));
          } else {
            if (!controller.initialError)
              return AppBarIconActionButton(
                actionModel: AppBarIconActionModel(
                  controller.isFollow
                      ? IconFont.buffCircleSubscribeSelect
                      : IconFont.buffCircleSubscribeUnselect,
                  showColor:
                      controller.isFollow ? appThemeData.primaryColor : null,
                  actionBlock: () async {
                    ///关注按钮的回调
                    final r = await controller
                        .postFollow(controller.isFollow ? '0' : '1');
                    if (r) {
                      controller.update();
                      if (Get.isRegistered<CircleController>())
                        CircleController.to.loadSubscriptionList();
                    }
                  },
                ),
              );
            else
              return sizedBox;
          }
        }, controller.showLoading),
        ObxValue((v) {
          if (v?.value ?? false) {
            return loadingCircle(22, margin: const EdgeInsets.only(right: 12));
          } else {
            if (!controller.initialError)
              return AppBarIconActionButton(
                actionModel: AppBarIconActionModel(
                  IconFont.buffMoreHorizontal,
                  isLoading: controller.menuModel?.loading ?? false,
                  actionBlock: () {
                    ///菜单按钮的回调
                    controller.menuModel?.showCircleDetailMenu(context);
                  },
                ),
              );
            else
              return sizedBox;
          }
        }, controller.showLoading),
      ];
    }, titleBuilder: (context, style) {
      return ObxValue((v) {
        if (v?.value ?? false) {
          return Row(
            children: [
              loadingCircle(28),
              sizeWidth8,
              SizedBox(
                width: 80,
                height: 20,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: appThemeData.dividerColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          );
        } else {
          if (controller.initialError) return sizedBox;
          return Row(
            children: [
              RealtimeAvatar(
                userId: controller?.headUser?.userId ?? '',
                size: 28,
                tapToShowUserInfo: true,
                guildId: controller.guildId,
                enterType: EnterType.fromCircle,
              ),
              sizeWidth8,
              Expanded(
                child: RealtimeNickname(
                  userId: controller?.headUser?.userId ?? '',
                  style: appThemeData.textTheme.bodyText2,
                  showNameRule: ShowNameRule.remarkAndGuild,
                  guildId: controller.guildId,
                ),
              ),
            ],
          );
        }
      }, controller.showLoading);
    });
  }

  @override
  CircleDetailArticleTopic createArticleTopic(String topicName,
          {double top, double bottom, Color textColor, Color bgColor}) =>
      CircleDetailArticleTopic(
        topicName,
        top: top,
        bottom: bottom,
        textColor: textColor,
        bgColor: bgColor,
      );
}
