import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/create_guide_select_template/controllers/create_guild_select_template_page_controller.dart';
import 'package:im/app/modules/create_guide_select_template/views/create_guild_select_template_page_view.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/image_operator_collection/image_builder.dart';
import 'package:im/utils/image_operator_collection/image_widget.dart';
import 'package:im/widgets/channel_icon.dart';

class CreateGuildTemplatePreview extends StatefulWidget {
  const CreateGuildTemplatePreview({Key key}) : super(key: key);

  Widget get confirmButton => Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, 16 + Get.mediaQuery.padding.bottom),
          child: FadeButton(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(6),
            ),
            onTap: () {
              Get.back();
            },
            child: Text(
              "确定".tr,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      );

  @override
  State<CreateGuildTemplatePreview> createState() =>
      _CreateGuildTemplatePreviewState();
}

class _CreateGuildTemplatePreviewState
    extends State<CreateGuildTemplatePreview> {
  final ValueNotifier<double> _guildCardHeight = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            "预设频道".tr,
            style: appThemeData.textTheme.caption,
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildGuildIconList(),
              const SizedBox(width: 12),
              Expanded(
                child: buildGuildMenu(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "预设角色".tr,
            style: appThemeData.textTheme.caption,
          ),
          const SizedBox(height: 10),
          buildRoleInfo(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  ///预设角色介绍
  ClipRRect buildRoleInfo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white),
        child: GetBuilder<CreateGuildSelectTemplatePageController>(
            builder: (controller) {
          return ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            separatorBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Divider(
                color: appThemeData.dividerColor,
                height: .5,
              ),
            ),
            itemBuilder: (context, index) {
              final role = controller.selectTargetRoles[index];
              return roleItem(role.name, role.color, role.desc);
            },
            itemCount: controller.selectTargetRoles.length,
          );
        }),
      ),
    );
  }

  ///服务器预览右边的菜单
  Builder buildGuildMenu() {
    return Builder(builder: (context) {
      ///因为右边的频道列表是动态生成的，所以高度不能提前知道，所以在下一帧后才从context获取
      ///布局好的组件高度
      ServicesBinding.instance.addPostFrameCallback((timeStamp) {
        _guildCardHeight.value = context.findRenderObject().paintBounds.height;
      });
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.white),
          child: GetBuilder<CreateGuildSelectTemplatePageController>(
              builder: (controller) {
            return Column(
              children: [
                SizedBox(
                  height: 142,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CreateGuildSelectTemplatePageView.guildBgFromFileOrNet(
                        file: controller.bgImageFromFile,
                        url: controller.bgImageFromNet,
                      ),
                      Positioned(
                        top: 16,
                        left: 12,
                        child: Text(
                          controller.serverName,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCircleBar(),
                Divider(
                  color: appThemeData.dividerColor,
                  height: .5,
                ),
                ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.selectTargetChannels.length,
                  itemBuilder: (context, index) {
                    final channel = controller.selectTargetChannels[index];
                    if (channel.type == ChatChannelType.guildCategory) {
                      return groupItem(channel.name);
                    } else if (channel.type != ChatChannelType.guildCircle &&
                        channel.type != ChatChannelType.guildCircleTopic &&
                        channel.type != ChatChannelType.task) {
                      return channelItem(
                          channel.type, channel.name, channel.private);
                    } else {
                      return const SizedBox();
                    }
                  },
                ),
              ],
            );
          }),
        ),
      );
    });
  }

  Container _buildCircleBar() {
    return Container(
      color: Colors.white,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            IconFont.buffCircleOfFriends,
            color: appThemeData.primaryColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '圈子'.tr,
            style: TextStyle(
              color: appThemeData.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            "发现更多精彩".tr,
            style: TextStyle(
              color: appThemeData.dividerColor.withOpacity(1),
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
          Icon(
            IconFont.buffPayArrowNext,
            size: 12,
            color: appThemeData.dividerColor.withOpacity(.75),
          ),
        ],
      ),
    );
  }

  ///服务器图标列表
  ValueListenableBuilder<double> buildGuildIconList() {
    return ValueListenableBuilder<double>(
      ///因为图标列表的占位图标是预先已经生成了，但是需要和频道列表组件相同高度对齐
      ///所以在频道列表构建完知道高度之后再把高度应用到这里
      valueListenable: _guildCardHeight,
      builder: (context, value, child) {
        return SizedBox(width: 44, height: value, child: child);
      },
      child: Stack(
        children: [
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            separatorBuilder: (_, __) => sizeHeight10,
            itemBuilder: (_, index) {
              if (index == 0) {
                return guildIcon();
              } else
                return placeHoldIcon();
            },
            itemCount: 10,
          ),
          const Positioned(
            bottom: 0,
            child: SizedBox(
              width: 44,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromRGBO(245, 246, 250, 1),
                      Color.fromRGBO(245, 246, 250, 0),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  ///服务器图标
  Widget guildIcon() {
    return GetBuilder<CreateGuildSelectTemplatePageController>(
        builder: (controller) {
      return SizedBox(
        height: 44,
        width: 44,
        child: () {
          if (controller.avatar != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: ImageWidget.fromFile(
                FileImageBuilder(controller.avatar,
                    fit: BoxFit.cover,
                    cacheHeight: (44 * Get.pixelRatio).toInt(),
                    cacheWidth: (44 * Get.pixelRatio).toInt()),
              ),
            );
          } else {
            return Container(
              decoration: BoxDecoration(
                color: controller.templateThemeColor,
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(5),
              alignment: Alignment.center,
              child: Text(
                controller.serverName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            );
          }
        }(),
      );
    });
  }

  ///其余服务器占位图标
  Widget placeHoldIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: appThemeData.dividerColor,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  ///频道分组Item
  Widget groupItem(String title) {
    return Container(
      padding: const EdgeInsets.only(top: 14),
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 12),
          Icon(
            IconFont.buffDownArrow,
            color: appThemeData.disabledColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: appThemeData.disabledColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      ),
    );
  }

  ///频道Item
  Widget channelItem(ChatChannelType iconType, String title, bool private) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          sizeWidth12,
          Icon(
            ChannelIcon.getChannelTypeIcon(iconType, isPrivate: private),
            size: 16,
            color: appThemeData.disabledColor,
          ),
          sizeWidth8,
          Text(
            title,
            style: TextStyle(
              color: appThemeData.disabledColor,
              fontSize: 16,
            ),
          )
        ],
      ),
    );
  }

  ///角色列表项
  Widget roleItem(String name, Color color, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                height: 8,
                width: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(name)
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(
              color: appThemeData.dividerColor.withOpacity(1),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
