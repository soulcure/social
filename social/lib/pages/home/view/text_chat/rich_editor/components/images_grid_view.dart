import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/circle/circle_post_entity.dart';
import 'package:im/pages/circle/content/circle_post_image_item.dart';
import 'package:im/pages/circle/model/circle_dynamic_data_controller.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/svg_icons.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/utils.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:websafe_svg/websafe_svg.dart';

class ImagesGridView extends StatefulWidget {
  const ImagesGridView({Key key}) : super(key: key);

  @override
  _ImagesGridViewState createState() => _ImagesGridViewState();
}

class _ImagesGridViewState extends State<ImagesGridView> {
  final circleDynamicData = Get.find<CircleDynamicDataController>();

  @override
  Widget build(BuildContext context) {
    //图片九宫格
    return (circleDynamicData.circleType !=
                CirclePostType.CirclePostTypeImage &&
            circleDynamicData.circleType != CirclePostType.CirclePostTypeVideo)
        ? SliverToBoxAdapter(
            child: Container(),
          )
        : SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: GetBuilder<CircleDynamicDataController>(
              id: circleDynamicData.circleGridIdentifier,
              builder: (c) {
                return c.circleType == CirclePostType.CirclePostTypeImage
                    ? imageGrid()
                    : videoBox();
              },
            ),
          );
  }

  Widget _loadingWidget(CirclePostImageItem item) {
    if (item?.thumbData?.isEmpty ?? true) {
      return Container();
    }
    return Image.memory(
      item.thumbData,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget imageContentBox(CirclePostImageItem item) {
    if (item.isAdd) {
      return _addAssetWidget();
    }
    // else if (item?.url?.isEmpty ?? true) {
    //   return _loadingWidget(item);
    // }

    return Stack(
      children: [
        GestureDetector(
          onTapUp: (e) {
            //这里的手势是为了避免用户点击九宫格图片，会弹出键盘的问题。
          },
          child: imageWidget(item),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              circleDynamicData.removeAssetItem(item);
            },
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: WebsafeSvg.asset(SvgIcons.svgTabClose,
                  color: Colors.white, width: 12, height: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget videoContentBox(CirclePostImageItem item) {
    if (item.isAdd) {
      return _addAssetWidget();
    }
    // else if (item?.url?.isEmpty ?? true) {
    //   return _loadingWidget(item);
    // }

    return Stack(
      children: [
        imageWidget(item),
        // circleVideoPlay
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              circleDynamicData.removeAssetItem(item);
            },
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: WebsafeSvg.asset(SvgIcons.svgTabClose,
                  color: Colors.white, width: 12, height: 12),
            ),
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.all(
                Radius.circular(2.5),
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                // WebsafeSvg.asset(SvgIcons.circleCamera_icon,
                //     width: 12, height: 12, color: Colors.white),
                // const SizedBox(width: 4),
                Text(
                  // item.asset.duration.toInt().toString(),
                  timeFormatted(item.duration.toInt()),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  SliverToBoxAdapter videoBox() {
    if (circleDynamicData.assetList.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(),
      );
    }
    final CirclePostImageItem item = circleDynamicData.assetList.first;
    return SliverToBoxAdapter(
      child: Row(
        children: [
          SizedBox(
            width: 220,
            height: 293,
            child: videoContentBox(item),
          ),
        ],
      ),
    );
  }

  Widget _addAssetWidget() {
    return GestureDetector(
      onTap: () {
        circleDynamicData.pickImages(isAdd: true);
      },
      child: DottedBorder(
        dashPattern: const [6, 4],
        color: const Color(0xa58F959E),
        child: const SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Icon(
            IconFont.buffAdd,
            color: Color(0xff8F959E),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget imageWidget(CirclePostImageItem item) {
    final bool isNetworkUrl = (item?.url?.startsWith('http://') ?? false) ||
        (item?.url?.startsWith('https://') ?? false);
    if (isNetworkUrl) {
      final thumbUrl = item.type == 'video' ? item.thumbUrl : item.url;
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: ContainerImage(
          thumbUrl,
          thumbWidth:
              (Get.size.width * MediaQuery.of(context).devicePixelRatio).ceil(),
          fit: BoxFit.cover,
          cacheManager: CircleCachedManager.instance,
        ),
      );
    } else if (item?.url?.isEmpty ?? true) {
      return _loadingWidget(item);
    }

    final imageName = item.type == 'video' ? item.thumbName : item.name;
    final imageCheckName = (item.checkPath.hasValue ?? false)
        ? item.checkPath.substring(item.checkPath.lastIndexOf('/') + 1)
        : imageName;

    String path = '${Global.deviceInfo.thumbDir}$imageCheckName';
    if (!File(path).existsSync()) {
      path = '${Global.deviceInfo.thumbDir}$imageName';
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget buildItem(CirclePostImageItem item) {
    ///每一个子Item的样式
    return Container(
      key: ValueKey(item.itemKey),
      child: imageContentBox(item),
    );
  }

  Widget imageGrid() {
    List<Widget> addItem = [];
    final List<Widget> buildItems = [];
    for (int i = 0; i < circleDynamicData.assetList.length; i++) {
      final CirclePostImageItem item = circleDynamicData.assetList[i];
      if (item.isAdd) {
        addItem = [_addAssetWidget()];
      } else {
        buildItems.add(buildItem(item));
      }
    }

    return ReorderableSliverGridView(
      crossAxisCount: 3,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          final element = circleDynamicData.assetList[oldIndex];
          circleDynamicData.removeAssetItemWithIndex(oldIndex, isUpdate: false);
          circleDynamicData.insertAssetItem(element, newIndex, isUpdate: false);
        });
      },
      footer: addItem,
      children: buildItems,
    );
  }
}
