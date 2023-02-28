import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluwx/fluwx.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/share_circle/controllers/share_circle_controller.dart';
import 'package:im/app/modules/share_circle/views/base_share_circle_state.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/channel_icon.dart';
import 'package:im/widgets/share_link_popup/share_type.dart';

class PortraitShareCircleState extends BaseShareCircleState {
  PortraitShareCircleState(ShareBean shareBean) : super(shareBean);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ShareCircleController>(
        init: ShareCircleController(shareBean),
        builder: (controller) {
          return IgnorePointer(
            ignoring: controller.shareUrl == null,
            child: Wrap(children: [
              Stack(children: [
                Wrap(
                  children: <Widget>[
                    _buildDropTag,
                    _buildTitle(controller),
                    _buildShareUrlJoinFlag(controller),
                    Divider(
                        color: const Color(0xFF919499).withOpacity(0.2),
                        height: 0.5),
                    _buildShare(controller),
                    Divider(
                        color: const Color(0xFF919499).withOpacity(0.2),
                        height: 0.5,
                        indent: 16),
                    _buildChannelTitle,
                    _buildShareChannel(),
                    const Divider(
                        height: 8, thickness: 8, color: Color(0xFFF5F5F8)),
                    _buildCancel,
                  ],
                ),
                if (controller.shareUrl == null)
                  const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: CupertinoActivityIndicator(),
                      ))
              ]),
            ]),
          );
        });
  }

  Widget get _buildCancel => InkWell(
        onTap: Get.back,
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(
                top: 17.5, bottom: 17.5 + Get.mediaQuery.padding.bottom),
            child: Text('取消'.tr,
                style: Get.textTheme.bodyText2.copyWith(fontSize: 17)),
          ),
        ),
      );

  Widget _buildTitle(ShareCircleController controller) => Padding(
        padding: EdgeInsets.only(
            left: 16,
            top: 13.5,
            bottom: controller.hasInvitePermission ? 0 : 21.5),
        child: Text("分享动态".tr,
            style: Get.textTheme.bodyText2
                .copyWith(fontSize: 17, fontWeight: FontWeight.w500)),
      );

  Widget get _buildChannelTitle => Padding(
      padding: const EdgeInsets.only(top: 16, left: 16, bottom: 8),
      child: Text(
        '分享至频道'.tr,
        style: Get.textTheme.bodyText2
            .copyWith(fontSize: 14, color: const Color(0xff5c6273)),
      ));

  Widget get _buildDropTag => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color: Get.textTheme.bodyText1.color.withOpacity(0.2),
              borderRadius: const BorderRadius.all(Radius.circular(4))),
        ),
      );

  ///允许通过分享链接加入的开关
  Widget _buildShareUrlJoinFlag(ShareCircleController controller) {
    if (!controller.hasInvitePermission) return sizedBox;

    final TextStyle textStyle = Get.textTheme.headline5
        .copyWith(fontSize: 15, fontWeight: FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 10, bottom: 21.5),
      child: Row(
        children: [
          Expanded(
              child: Text(
            '允许外部用户通过分享链接加入服务器'.tr,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )),
          Padding(
              padding: const EdgeInsets.only(left: 10, right: 16),
              child: Transform.scale(
                scale: 0.9,
                alignment: Alignment.centerRight,
                child: CupertinoSwitch(
                    activeColor: Theme.of(context).primaryColor,
                    value: controller.shareUrlJoinFlag,
                    onChanged: (_) {
                      controller.updateShareUrlJoinFlag();
                    }),
              )),
        ],
      ),
    );
  }

  Widget _buildShare(ShareCircleController controller) {
    final TextStyle textStyle = Get.textTheme.headline5
        .copyWith(fontSize: 11, fontWeight: FontWeight.normal);
    const padding = EdgeInsets.only(left: 8, right: 8, top: 5);
    return SizedBox(
      width: double.infinity,
      height: 105,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        children: [
          /// 分享给微信好友
          ShareItem(
            onShareClick: () =>
                controller.circleShareDestinationEvent('wechat'),
            config: WechatShareToFriendConfig(),
            action: WechatShareLinkAction(
              title: controller.title,
              subtitle:
                  '来自 ${controller.guildName} 的Fanbook圈子动态，作者：${shareBean.data.userInfo['nickname']}',
              link: controller.shareUrl,
              // icon: shareBean.data.userInfo['avatar'],
              icon: controller.image,
            ),
            textStyle: textStyle,
            padding: padding,
          ),

          /// 分享到微信朋友圈
          ShareItem(
            onShareClick: () =>
                controller.circleShareDestinationEvent('wechat_moments'),
            config: WechatShareToMomentConfig(),
            action: WechatShareLinkAction(
              title: controller.title,
              subtitle:
                  '来自 ${controller.guildName} 的Fanbook圈子动态，作者：${shareBean.data.userInfo['nickname']}',
              link: controller.shareUrl,
              icon: controller.image,
              scene: WeChatScene.TIMELINE,
            ),
            textStyle: textStyle,
            padding: padding,
          ),

          /// 复制链接
          ShareItem(
            onShareClick: () =>
                controller.circleShareDestinationEvent('copy_link'),
            config: CopyLinkShareConfig(),
            action: CopyLinkShareAction(controller.shareUrl),
            textStyle: textStyle,
            padding: padding,
          ),

          /// 生成分享图
          if (shareBean.sharePosterModel != null)
            ShareItem(
              config: SaveShareConfig(),
              textStyle: textStyle,
              padding: padding,
              action: SaveShareAction(controller.shareUrl, shareBean),
            )
        ],
      ),
    );
  }

  Widget _buildShareChannel() => GetBuilder<ShareCircleController>(
      init: ShareCircleController(shareBean),
      builder: (controller) {
        final h = controller.hasInvitePermission ? 70 : 0;
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                Get.size.height - 112 - 20 - 44 - 10 - 105 - 8 - 56 - 41 - h,
            minHeight: Get.size.height - 379 - 20 - 44 - 10 - 105 - 8 - 56,
          ),
          child: Scrollbar(
            child: ListView.builder(
              shrinkWrap: true,
              itemBuilder: (_, index) => _buildItem(controller, index),
              itemCount: controller.channelValue.length,
            ),
          ),
        );
      });

  Widget _buildItem(ShareCircleController controller, index) {
    final channel = controller.channels[index];
    final isPrivate = PermissionUtils.isPrivateChannel(
        PermissionModel.getPermission(channel.guildId), channel.id);
    return GestureDetector(
      onTap: () => controller.onOnItemClick(index),
      behavior: HitTestBehavior.translucent,
      child: Obx(
        () => Container(
          color: controller.select == index
              ? const Color(0xFFF5F5F8)
              : Get.theme.backgroundColor,
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    sizeWidth16,
                    ChannelIcon(
                      ChatChannelType.guildText,
                      private: isPrivate,
                      size: 16,
                      color: Get.theme.disabledColor,
                    ),
                    sizeWidth12,
                    Expanded(
                      child: Text(
                        controller.channels[index].name,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            height: 1.17,
                            color: Get.theme.iconTheme.color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Visibility(
                    //   visible: controller.select == index,
                    //   child: MaterialButton(
                    //     height: 32,
                    //     minWidth: 60,
                    //     elevation: 0,
                    //     color: Get.theme.primaryColor,
                    //     textTheme: ButtonTextTheme.normal,
                    //     padding: EdgeInsets.zero,
                    //     textColor: Get.theme.backgroundColor,
                    //     shape: const RoundedRectangleBorder(
                    //         borderRadius:
                    //             BorderRadius.all(Radius.circular(16))),
                    //     onPressed: () => controller.onShareChannel(index),
                    //     child: Text('分享'.tr,
                    //         style: const TextStyle(
                    //             color: Colors.white, fontSize: 14)),
                    //   ),
                    // ),
                    sizeWidth16,
                  ],
                ),
              ),
              Divider(
                  indent: 44,
                  height: Get.theme.dividerTheme.thickness,
                  color: Get.theme.dividerTheme.color),
            ],
          ),
        ),
      ),
    );
  }
}
