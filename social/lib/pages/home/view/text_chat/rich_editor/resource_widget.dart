import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/controllers/circle_publish_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/circle/content/circle_post_image_item.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:reorderables/reorderables.dart';

class ResourceWidget extends StatefulWidget {
  @override
  _ResourceWidgetState createState() => _ResourceWidgetState();
}

// RichTunEditorModel / CirclePublishController
class _ResourceWidgetState extends State<ResourceWidget> {
  final controller = Get.find<CirclePublishController>();

  Widget _addAssetWidget() {
    return GestureDetector(
      onTap: controller.pickImages,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: appThemeData.dividerColor.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Icon(
            IconFont.buffAdd,
            color: appThemeData.iconTheme.color.withOpacity(0.4),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget imageWidget(
    CirclePostImageItem item, {
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
  }) {
    final bool isNetworkUrl = (item?.url?.startsWith('http://') ?? false) ||
        (item?.url?.startsWith('https://') ?? false);

    // 安卓端经常会返回0，导致异常
    final itemHeight = item.height == 0 ? 90 : item.height;
    final itemWidth = item.width == 0 ? 90 : item.width;

    final height = (Get.pixelRatio * 90).toInt();
    final width = (height * (itemWidth / itemHeight)).toInt();

    if (isNetworkUrl) {
      final thumbUrl = item.type == 'video' ? item.thumbUrl : item.url;
      return ContainerImage(
        thumbUrl,
        width: width.toDouble(),
        height: height.toDouble(),
        fit: fit,
        placeHolder: (context, url) =>
            const Center(child: CupertinoActivityIndicator()),
        cacheManager: CircleCachedManager.instance,
      );
    } else if (item?.thumbData?.isNotEmpty ?? false) {
      return Image.memory(
        item.thumbData,
        fit: BoxFit.cover,
        cacheHeight: height,
        cacheWidth: width,
      );
    } else {
      final imageName = item.type == 'video' ? item.thumbName : item.name;
      final path = '${Global.deviceInfo.mediaDir}$imageName';
      if (item.type == 'video') {
        return videoThumbWidget(imagePath: path, customCover: item.customCover);
      } else {
        return Image.file(
          File(path),
          fit: fit,
          alignment: alignment,
          cacheHeight: height,
          cacheWidth: width,
        );
      }
    }
  }

  Widget videoThumbWidget({String imagePath, bool customCover}) {
    ///未获取到真实图片比例时先返回SizedBox避免图片闪动
    if (controller.videoThumbAspectRadio == 0) return const SizedBox();
    final imageFile = File(imagePath);
    final imageWidget = AspectRatio(
      aspectRatio: controller.videoThumbAspectRadio,
      child: Image.file(imageFile, fit: BoxFit.cover),
    );
    final thumbWidget = ClipRect(
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: imageWidget,
      ),
    );
    final mask = Positioned.fill(
      child: Container(color: Colors.black.withOpacity(0.3)),
    );
    final descWidget = Positioned.fill(
      child: GestureDetector(
        onTap: controller.pickVideoCover,
        behavior: HitTestBehavior.translucent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              IconFont.buffRoundAdd,
              color: Colors.white,
            ),
            const SizedBox(height: 9),
            Text(
              '添加封面'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        if (customCover) imageWidget else ...[thumbWidget, mask, descWidget]
      ],
    );
  }

  Widget imageContentBox(CirclePostImageItem item) {
    if (item.isAdd) {
      return _addAssetWidget();
    }
    return GestureDetector(
      onTap: () => controller.editAssetItem(item),
      child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: appThemeData.dividerColor.withOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
              // 内圆角需要比外圆角一点点，大概是边框粗度，才能够让背景和边框吻合
              borderRadius: BorderRadius.circular(4),
              child: imageWidget(item))),
    );
  }

  Widget imageListWidget() {
    final assetList = List.from(controller.assetList ?? []);
    if (assetList.length < 9 && controller.editedData == null) {
      assetList.add(CirclePostImageItem(isAdd: true));
    }
    return SingleChildScrollView(
      child: Container(
        height: 108,
        width: Get.width,
        color: appThemeData.scaffoldBackgroundColor,
        child: ReorderableRow(
          crossAxisAlignment: CrossAxisAlignment.start,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          onReorder: controller.swapAsset,
          draggingWidgetOpacity: 0,
          buildDraggableFeedback: (context, constraints, widget) {
            return Material(child: widget);
          },
          children: assetList
              .map((e) => Container(
                  height: 90,
                  width: 90,
                  key: ValueKey(e.hashCode),
                  margin: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                  decoration: BoxDecoration(
                      color: appThemeData.backgroundColor,
                      border: Border.all(color: appThemeData.dividerColor),
                      borderRadius: BorderRadius.circular(8)),
                  child: imageContentBox(e)))
              .toList(),
        ),
      ),
    );
  }

  Widget videoWidget() {
    Widget _button({Function onTap, IconData icon, String text}) {
      return SizedBox(
        height: 28,
        width: 89,
        child: TextButton(
          style: ButtonStyle(
              padding: MaterialStateProperty.all(EdgeInsets.zero),
              backgroundColor: MaterialStateProperty.all(
                  appThemeData.dividerColor.withOpacity(0.2))),
          onPressed: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: appThemeData.textTheme.bodyText2.color,
                size: 16,
              ),
              sizeWidth8,
              Text(
                text.tr,
                style: appThemeData.textTheme.bodyText2.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: appThemeData.scaffoldBackgroundColor,
      padding: const EdgeInsets.only(bottom: 8),
      width: Global.mediaInfo.size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 0, 12),
            height: 156,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: imageWidget(
                controller.assetList.first,
                fit: BoxFit.fitHeight,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
          if (controller.editedData == null)
            Row(
              children: [
                sizeWidth16,
                _button(
                  onTap: controller.reEditorVideo,
                  icon: IconFont.buffCircleVideoPreview,
                  text: '预览视频',
                ),
                sizeWidth8,
                if (controller.assetList.first.customCover)
                  _button(
                    onTap: controller.pickVideoCover,
                    icon: IconFont.buffTabImage,
                    text: '修改封面',
                  ),
              ],
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CirclePublishController>(
        id: CirclePublishController.resourceId,
        builder: (controller) {
          if (controller.isImage)
            return imageListWidget();
          else
            return videoWidget();
        });
  }
}
