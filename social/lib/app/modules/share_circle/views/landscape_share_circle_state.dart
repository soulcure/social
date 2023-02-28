import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/share_circle/controllers/share_circle_controller.dart';
import 'package:im/app/modules/share_circle/views/base_share_circle_state.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/channel_icon.dart';
import 'package:im/widgets/check_square_box.dart';
import 'package:im/widgets/land_pop_app_bar.dart';
import 'package:im/widgets/share_link_popup/share_type.dart';

import '../../../../icon_font.dart';

class LandScapeShareCircleState extends BaseShareCircleState {
  LandScapeShareCircleState(ShareBean shareBean) : super(shareBean);

  @override
  Widget build(BuildContext context) {
    return shareBean.isLandFromCircleDetail
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: Get.theme.backgroundColor,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8), topRight: Radius.circular(8))),
            child: _buildWidget,
          )
        : popWrap(
            horizontal: 16,
            child: _buildWidget,
          );
  }

  Widget get _buildWidget {
    return GetBuilder<ShareCircleController>(
      init: ShareCircleController(shareBean),
      builder: (controller) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LandPopAppBar(title: '分享至频道'.tr),
            _buildShareChannel(controller),
            _buildBottom(controller),
          ],
        );
      },
    );
  }

  Widget _buildShareChannel(ShareCircleController controller) => ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 570.0 - 56 - 64,
          minHeight: 360.0 - 56 - 64,
        ),
        child: Scrollbar(
          child: ListView.builder(
            shrinkWrap: true,
            itemBuilder: (_, index) => _buildItem(controller, index),
            itemCount: controller.channelValue.length,
          ),
        ),
      );

  Widget _buildItem(ShareCircleController controller, index) {
    final channel = controller.channels[index];
    final isPrivate = PermissionUtils.isPrivateChannel(
        PermissionModel.getPermission(channel.guildId), channel.id);
    return GestureDetector(
      onTap: () => controller.onOnItemClick(index),
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            AbsorbPointer(
              absorbing: controller.selectedChannels.length >= 9 &&
                  controller.channelValue[index] == false,
              child: Obx(() => AnimatedContainer(
                    duration: const Duration(milliseconds: 20),
                    child: CheckSquareBox(
                      value: controller.select == index,
                      onChanged: (v) {
                        controller.onOnItemClick(v ? index : -1);
                      },
                    ),
                  )),
            ),
            sizeWidth12,
            ChannelIcon(
              ChatChannelType.guildText,
              private: isPrivate,
              size: 16,
              color: Get.theme.disabledColor,
            ),
            sizeWidth8,
            Text(
              controller.channels[index].name,
              style: Get.textTheme.headline5.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottom(ShareCircleController controller) {
    return SizedBox(
      height: 64,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          InkWell(
            onTap: () {
              CopyLinkShareAction(controller.shareUrl).shareAction();
              Get.back();
            },
            child: Row(
              children: [
                Icon(
                  IconFont.buffChannelLink2,
                  color: Get.theme.toggleableActiveColor,
                  size: 23,
                ),
                sizeWidth8,
                Text(
                  '复制链接'.tr,
                  style: TextStyle(
                    color: Get.theme.toggleableActiveColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          MaterialButton(
            height: 36,
            minWidth: 88,
            color: Get.theme.primaryColor,
            textTheme: ButtonTextTheme.normal,
            padding: EdgeInsets.zero,
            textColor: Get.theme.backgroundColor,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(3))),
            onPressed: () => controller.onShareChannel(controller.select),
            child: Text('分享'.tr,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
