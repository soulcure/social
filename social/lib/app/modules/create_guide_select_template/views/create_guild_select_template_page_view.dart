import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:im/app/modules/create_guide_select_template/controllers/create_guild_select_template_page_controller.dart';
import 'package:im/app/modules/create_guide_select_template/views/create_guild_template_preview.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/const.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/image_operator_collection/image_builder.dart';
import 'package:im/utils/image_operator_collection/image_widget.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/svg_tip_widget.dart';
import 'package:websafe_svg/websafe_svg.dart';

class CreateGuildSelectTemplatePageView
    extends GetView<CreateGuildSelectTemplatePageController> {
  @override
  Widget build(BuildContext context) {
    final theme = Get.theme;
    return Scaffold(
      backgroundColor: appThemeData.scaffoldBackgroundColor,
      appBar: FbAppBar.custom(
        '创建我的服务器'.tr,
        backgroundColor: Colors.white.withAlpha(0),
      ),
      body: GestureDetector(
        onTap: () {
          controller.focusNode.unfocus();
          controller.updateServerName();
        },
        child: GetBuilder<CreateGuildSelectTemplatePageController>(
            builder: (controller) {
          return Column(
            children: [
              Expanded(child: _buildBody(theme, context)),
              if (!controller.loadError)
                KeyboardVisibilityBuilder(
                  builder: (_, isKeyboardVisible) {
                    if (!isKeyboardVisible)
                      return _nextButton(context);
                    else
                      return sizedBox;
                  },
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, BuildContext context) {
    if (!controller.loadError)
      return ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: <Widget>[
          IgnorePointer(
            ignoring: controller.loadError,
            child: _buildServerCard(context),
          ),
          if (controller.loadError)
            _buildErrorWidget(context)
          else
            _buildTemplateList(),
        ],
      );
    else
      return _buildErrorWidget(context);
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: SvgTipWidget(
              svgName: SvgIcons.noNetState,
              desc: '加载失败，请重试'.tr,
            ),
          ),
          FadeButton(
            onTap: () => controller.loadData(reload: true, context: context),
            decoration: BoxDecoration(
              color: appThemeData.primaryColor,
              borderRadius: BorderRadius.circular(5),
            ),
            width: 180,
            height: 36,
            child: Text(
              '重新加载'.tr,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Container _buildTemplateList() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeData.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: appThemeData.dividerColor.withOpacity(.05),
            offset: const Offset(0, 1),
            blurRadius: 20,
          )
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '服务器用于'.tr,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500, height: 1.25),
            ),
          ),
          sizeHeight16,
          SizedBox(
            height: 126,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              separatorBuilder: (_, __) => const SizedBox(width: 12.5),
              itemBuilder: (context, index) => buildItem(index),
              itemCount: controller.itemList.length,
            ),
          ),
        ],
      ),
    );
  }

  /// 下一步
  Widget _nextButton(BuildContext context) {
    return GetBuilder<CreateGuildSelectTemplatePageController>(
      id: 'createButton',
      builder: (controller) => FadeButton(
        onTap: () {
          if (controller.confirmEnable) controller.createServer(context);
        },
        width: Get.width,
        height: Get.mediaQuery.padding.bottom + 60,
        padding: EdgeInsets.only(bottom: Get.mediaQuery.padding.bottom),
        backgroundColor: appThemeData.backgroundColor,
        child: Text(
          "下一步".tr,
          style: TextStyle(
              color: controller.confirmEnable
                  ? appThemeData.primaryColor
                  : appThemeData.primaryColor.withOpacity(.35),
              fontWeight: FontWeight.w500,
              height: 1.25),
        ),
      ),
    );
  }

  Widget buildItem(int index) {
    final bool choice = index == controller.usedForChoice;
    final color = choice ? Colors.white : appThemeData.disabledColor;

    return GestureDetector(
      onTap: () => controller.choiceUsedFor(index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 95,
          padding: const EdgeInsets.only(top: 32),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: choice
                ? controller.itemList[index].themeColor
                : appThemeData.scaffoldBackgroundColor,
          ),
          child: Column(
            children: [
              WebsafeSvg.network(
                controller.itemList[index].serverIcon,
                color: color,
                height: 24,
                width: 24,
              ),
              sizeHeight16,
              Text(
                controller.itemList[index].teamName,
                style: TextStyle(color: color, fontSize: 14),
              ),
              const Spacer(),
              if (choice)
                GestureDetector(
                  onTap: () {
                    const preview = CreateGuildTemplatePreview();
                    showBottomModal(
                      Get.context,
                      builder: (_, __) => preview,
                      backgroundColor: appThemeData.scaffoldBackgroundColor,
                      footerBuilder: (_, __) => preview.confirmButton,
                      bottomInset: false,
                    );
                  },
                  child: Container(
                    height: 28,
                    color: const Color(0x1A1F2126),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "预览模版".tr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget guildBgFromFileOrNet(
      {@required File file, @required String url}) {
    if (file != null) {
      return ImageWidget.fromFile(
        FileImageBuilder(file, fit: BoxFit.cover),
      );
    } else if (url.hasValue) {
      return ImageWidget.fromCachedNet(
        CachedImageBuilder(
          imageUrl: url,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return sizedBox;
    }
  }

  Widget _buildServerCard(BuildContext context) {
    return Container(
      height: 344,
      margin: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ///卡片背景
          Container(
            decoration: BoxDecoration(
              color: appThemeData.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: appThemeData.dividerColor.withOpacity(.05),
                  offset: const Offset(0, 1),
                  blurRadius: 20,
                )
              ],
            ),
          ),

          ///顶部背景图
          Align(
            alignment: Alignment.topCenter,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => controller.setBanner(context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 156,
                        width: double.infinity,
                        child: guildBgFromFileOrNet(
                          file: controller.bgImageFromFile,
                          url: controller.bgImageFromNet,
                        ),
                      ),
                    ),
                    if (controller.serverName.hasValue)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Text(
                          controller.serverName ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (controller.bgImageFromFile == null &&
              !controller.serverName.hasValue)
            Positioned(
              top: 57,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => controller.setBanner(context),
                child: Text(
                  '轻触设置服务器封面'.tr,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              color: appThemeData.backgroundColor,
              borderRadius: BorderRadius.circular(27),
            ),
          ),

          ///头像
          () {
            return Container(
              width: 112,
              height: 112,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: appThemeData.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: (controller.avatar == null &&
                        !controller.serverName.hasValue)
                    ? Border.all(color: appThemeData.dividerColor, width: .5)
                    : null,
              ),
              child: () {
                if (controller.avatar != null) {
                  ///如果用户有上传头像
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ImageWidget.fromFile(
                      FileImageBuilder(
                        controller.avatar,
                        fit: BoxFit.cover,
                        cacheHeight: (112 * Get.pixelRatio).toInt(),
                        cacheWidth: (112 * Get.pixelRatio).toInt(),
                      ),
                    ),
                  );
                } else if (controller.inputController.text.trim().hasValue) {
                  ///如果用户没有用上传头像但是设置了服务器名
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: RepaintBoundary(
                      key: controller.autoGenAvatarKey,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(12),
                        color: controller.templateThemeColor,
                        child: SizedBox(
                          child: Text(
                            controller.serverName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return SizedBox(
                    width: 75,
                    child: Text(
                      '轻触设置服务器头像'.tr,
                      style: TextStyle(
                          color: appThemeData.disabledColor.withOpacity(.65),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.25),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
              }(),
            );
          }(),

          ///相机图标
          SizedBox(
            width: 116,
            height: 116,
            child: Align(
              alignment: Alignment.bottomRight,
              child: SizedBox(
                width: 28,
                height: 28,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Get.theme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        IconFont.buffOtherPhoto,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          ///头像区域手势检测
          GestureDetector(
            onTap: () => controller.setAvatar(context),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(width: 116, height: 116),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: CreateServerInput(controller),
            ),
          ),
        ],
      ),
    );
  }
}

class CreateServerInput extends StatelessWidget {
  const CreateServerInput(this.controller, {Key key}) : super(key: key);
  final CreateGuildSelectTemplatePageController controller;

  @override
  Widget build(BuildContext context) {
    final inputController = controller.inputController;
    final focusNode = controller.focusNode;
    final text = inputController.text.trim();
    return GestureDetector(
      onTap: focusNode.requestFocus,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
            border: Border.all(
                color: appThemeData.dividerColor.withOpacity(.35), width: .5),
            borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration.collapsed(
                  hintText: '输入服务器名称'.tr,
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: appThemeData.disabledColor.withOpacity(.75),
                    height: 1.25,
                  ),
                ),
                controller: inputController,
                focusNode: focusNode,
                onChanged: (_) {
                  controller.updateServerName();
                },
              ),
            ),
            if (text.isNotEmpty && controller.focusNode.hasFocus)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  inputController.clear();
                  controller.updateServerName();
                },
                child: Container(
                  padding: const EdgeInsets.only(left: 3),
                  alignment: Alignment.center,
                  child: Icon(
                    IconFont.buffClose,
                    size: 16,
                    color: appThemeData.dividerColor.withOpacity(.75),
                  ),
                ),
              ),
            if (controller.focusNode.hasFocus ||
                text.characters.length > maxUserServerLength)
              Container(
                width: 42,
                alignment: Alignment.centerRight,
                child: RichText(
                  text: TextSpan(
                    text: '${text.characters.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: text.characters.length > maxUserServerLength
                          ? Theme.of(context).errorColor
                          : appThemeData.dividerColor.withOpacity(.75),
                    ),
                    children: [
                      TextSpan(
                        text: '/$maxUserServerLength',
                        style: TextStyle(
                            fontSize: 14,
                            color: appThemeData.dividerColor.withOpacity(.75)),
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
