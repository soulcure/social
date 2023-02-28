import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/global_methods/goto_direct_message.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/friend/relation.dart';
import 'package:im/pages/friend/widgets/relation_utils.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/check_media_conflict_util.dart';
import 'package:im/widgets/user_info/popup/view_model.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

//  用户的互动组件 【私信、语音、视频、好友关系处理】
class InteractiveWidget extends StatefulWidget {
  final UserInfo user;
  const InteractiveWidget({Key key, this.user}) : super(key: key);

  @override
  _InteractiveWidgetState createState() => _InteractiveWidgetState();
}

class _InteractiveWidgetState extends State<InteractiveWidget> {
  Widget _buildButtonItem(
      {String title,
      IconData icon,
      Function onTap,
      Color color,
      bool disabled = false}) {
    return Expanded(
      child: FadeButton(
        onTap: () {
          if (disabled) {
            showToast('内测中，敬请期待...'.tr);
            return;
          }
          if (onTap != null) onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Icon(
              icon,
              color: disabled
                  ? appThemeData.textTheme.bodyText1.color.withOpacity(0.4)
                  : (color ?? appThemeData.textTheme.bodyText1.color),
            ),
            sizeHeight5,
            Text(
              title,
              maxLines: 1,
              style: appThemeData.textTheme.bodyText1.copyWith(
                fontSize: 12,
                color: disabled
                    ? appThemeData.textTheme.bodyText1.color.withOpacity(0.4)
                    : (color ?? appThemeData.textTheme.bodyText1.color),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserInfoViewModel>(
        tag: widget.user.userId,
        builder: (controller) {
          return Column(
            children: [
              sizeHeight12,
              // 私信按钮栏
              Row(
                children: <Widget>[
                  _buildButtonItem(
                      title: '私信'.tr,
                      icon: IconFont.buffChatSingle,
                      color: Theme.of(context).textTheme.bodyText2.color,
                      onTap: () {
                        Get.back();
                        gotoDirectMessageChat(widget.user.userId);
                      }),
                  ObxValue<RxBool>((disabled) {
                    return _buildButtonItem(
                        title: '语音'.tr,
                        icon: IconFont.buffModuleMic,
                        color: Theme.of(context).textTheme.bodyText2.color,
                        disabled: disabled.value,
                        onTap: () async {
                          /// 判断是否正在直播中
                          final canGotoAudio = await checkAndExitLiveRoom();
                          if (!canGotoAudio) return;

                          ///发起语音前，需要获取到频道ID
                          final channel = await DirectMessageController.to
                              .createChannel(widget.user.userId);
                          if (channel == null) return;

                          if (Navigator.canPop(context)) {
                            Routes.pop(context);
                          }
                          unawaited(Routes.pushVideoPage(
                              context, widget.user.userId));
                        });
                  }, controller.videoDisabled),
                  ObxValue<RxBool>((disabled) {
                    return _buildButtonItem(
                        title: '视频'.tr,
                        icon: IconFont.buffModuleVideocam,
                        color: Theme.of(context).textTheme.bodyText2.color,
                        disabled: disabled.value,
                        onTap: () async {
                          /// 判断是否正在直播中
                          final canGotoVideo = await checkAndExitLiveRoom();
                          if (!canGotoVideo) return;

                          ///发起视频前，需要获取到频道ID
                          final channel = await DirectMessageController.to
                              .createChannel(widget.user.userId);
                          if (channel == null) return;

                          if (Navigator.canPop(context)) {
                            Routes.pop(context);
                          }
                          unawaited(Routes.pushVideoPage(
                              context, widget.user.userId,
                              isVideo: true));
                        });
                  }, controller.videoDisabled),
                  RelationUtils.consumer(widget.user.userId,
                      builder: (context, type, widget) {
                    final bool isApplyPending = [
                      RelationType.pendingOutgoing,
                      RelationType.pendingIncoming
                    ].contains(type);

                    return Visibility(
                        visible: type != RelationType.friend,
                        child: ObxValue<RxBool>((loading) {
                          if (loading.value)
                            return Expanded(
                                child: DefaultTheme.defaultLoadingIndicator(
                                    size: 8));
                          return _buildButtonItem(
                            color: isApplyPending
                                ? const Color(0xFFF3B331)
                                : Theme.of(context).textTheme.bodyText2.color,
                            title: isApplyPending ? '待通过'.tr : '添加好友'.tr,
                            icon: isApplyPending
                                ? IconFont.buffModuleWaiting
                                : IconFont.buffModuleMenuOpen,
                            onTap: isApplyPending
                                ? controller.cancelApply
                                : controller.sendApply,
                          );
                        }, controller.applyLoading));
                  })
                ],
              ),
              sizeHeight12,
            ],
          );
        });
  }
}
