import 'dart:ui';

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/models/circle_post_data_type.dart';
import 'package:im/app/modules/circle/views/widgets/loading_indicator.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/list_extension.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../../svg_icons.dart';

class ImageVideo {
  String name;
  String source;
  double width;
  double height;
  String checkPath;
  String sType;
  bool bInline;

  //video
  String fileType;
  double duration;
  String thumbUrl;
  String thumbName;

  /// * 从图片中提取的主要颜色，用于图片背景显示
  Rx<Color> bgColor1 = Rx<Color>(null);
  Rx<Color> bgColor2 = Rx<Color>(null);

  /// * 根据类型获取图片地址
  String getSrcUrl() {
    return sType == CirclePostDataType.video ? thumbUrl : source;
  }

  ImageVideo(
      {this.name,
      this.source,
      this.width,
      this.height,
      this.checkPath,
      this.sType,
      this.bInline,
      this.fileType,
      this.duration,
      this.thumbUrl,
      this.thumbName});

  ImageVideo.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    source = json['source'];
    if (json['width'] is int) {
      width = (json['width'] as int).toDouble();
    } else {
      width = json['width'];
    }
    if (json['height'] is int) {
      height = (json['height'] as int).toDouble();
    } else {
      height = json['height'];
    }
    checkPath = json['checkPath'];
    sType = json['_type'];
    bInline = json['_inline'];
    fileType = json['fileType'];
    if (json['duration'] is int) {
      duration = (json['duration'] as int).toDouble();
    } else {
      duration = json['duration'];
    }
    thumbUrl = json['thumbUrl'];
    thumbName = json['thumbName'];
    // if (imageColorMap.containsKey(getSrcUrl())) {
    //   final tuple2 = imageColorMap[getSrcUrl()];
    //   bgColor1.value = tuple2?.item1;
    //   bgColor2.value = tuple2?.item2;
    // }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['source'] = source;
    data['width'] = width;
    data['height'] = height;
    data['checkPath'] = checkPath;
    data['_type'] = sType;
    data['_inline'] = bInline;

    data['fileType'] = fileType;
    data['duration'] = duration;
    data['thumbUrl'] = thumbUrl;
    data['thumbName'] = thumbName;

    return data;
  }
}

typedef OnLongPressImage = void Function(ImageVideo item);
typedef OnTapVideo = void Function(ImageVideo item);

///最大和最小的宽高比
const double _maxRatio = 2;
const double _minRatio = 3 / 4;

/// * 图片视频轮播View
// ignore: must_be_immutable
class ImageVideoSwipeView extends StatelessWidget {
  List<ImageVideo> imageVideoList;
  final OnLongPressImage onLongPressImage;
  final OnTapVideo onTapVideo;
  final double top;
  final double bottom;
  final CircleDetailController detailController;

  // view的宽
  double widgetWidth;

  // view的高
  double widgetHeight;

  ImageVideoSwipeView({
    Key key,
    this.onLongPressImage,
    this.onTapVideo,
    this.top = 0,
    this.bottom = 20,
    this.detailController,
  }) : super(key: key) {
    imageVideoList = detailController.imageVideoList;
    if (imageVideoList.hasValue && imageVideoList.length > 9) {
      //最多展示9张
      imageVideoList = imageVideoList.getRange(0, 9).toList();
    }
    if (imageVideoList.noValue) return;
    // 宽度为屏幕宽
    widgetWidth = Get.width;
    final maxHeightItem = imageVideoList.reduce((v1, v2) {
      if (v1.height == null || v1.height == 0) return v2;
      if (v2.height == null || v2.height == 0) return v1;
      // print('getChat swipeView: ${v1.width / v1.height} - ${v2.width / v2.height}');
      return v1.width / v1.height < v2.width / v2.height ? v1 : v2;
    });

    if (maxHeightItem.width == 0 || maxHeightItem.height == 0) {
      widgetHeight = widgetWidth / _minRatio;
    } else {
      final itemRatio = maxHeightItem.width / maxHeightItem.height;
      if (itemRatio >= _minRatio && itemRatio <= _maxRatio) {
        final itemWidth = maxHeightItem.width / Get.pixelRatio;
        final itemHeight = maxHeightItem.height / Get.pixelRatio;
        // 宽高比: 在最小和最大之间，等比缩放
        widgetHeight = itemHeight * (widgetWidth / itemWidth);
      } else if (itemRatio < _minRatio) {
        // 宽高比: 小于最小，按最小比计算高度
        widgetHeight = widgetWidth / _minRatio;
      } else if (itemRatio > _maxRatio) {
        // 宽高比: 大于最小，按最大比计算高度
        widgetHeight = widgetWidth / _maxRatio;
      }
    }
    if (widgetHeight == null || widgetHeight <= 0)
      widgetHeight = widgetWidth / _minRatio;
    //int和double转化精度丢失，+2进行补偿
    widgetHeight += 2;
  }

  @override
  Widget build(BuildContext context) {
    if (imageVideoList.noValue) return sizedBox;
    return Container(
      padding: EdgeInsets.only(top: top ?? 0, bottom: bottom ?? 20),
      //图片数量大于1，高度加上indicator的高度
      height: imageVideoList.length > 1 ? widgetHeight + 30 : widgetHeight,
      child: Stack(
        children: [
          NotificationListener(
            onNotification: (_) {
              ///禁止传递滚动事件给外层，防止详情页出现水平滚动条
              return true;
            },
            child: Swiper(
              allowImplicitScrolling: true,
              itemBuilder: (context, index) {
                final item = imageVideoList[index];
                if (item.sType == CirclePostDataType.video) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      onTapVideo(item);
                    },
                    child: _getVideoWidget(item),
                  );
                }
                final child = ContainerImage(
                  item.source,
                  width: widgetWidth,
                  height: widgetHeight,
                  thumbWidth: CircleController.circleThumbWidth,
                  fit: BoxFit.contain,
                  cacheManager: CircleCachedManager.instance,
                  placeHolder: (_, url) =>
                      const Center(child: CircleLoadingIndicator()),
                );
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: () {
                    onLongPressImage(item);
                  },
                  child: child,
                );
              },
              loop: false,
              index: detailController.imageIndex.value,
              itemCount: imageVideoList.length,
              pagination: imageVideoList.length > 1
                  ? SwiperPagination(
                      builder: DotSwiperPaginationBuilder(
                          size: 5,
                          activeSize: 5,
                          space: 2,
                          activeColor: appThemeData.primaryColor,
                          color: appThemeData.textTheme.headline2.color
                              .withOpacity(0.3)))
                  : null,
              // onTap: (index) {
              //   onClickItem?.call(
              //       imageVideoList, index, CircleController.circleThumbWidth);
              // },
              outer: imageVideoList.length > 1,
              onIndexChanged: (index) {
                detailController.imageIndex.value = index;
              },
            ),
          ),
          Positioned(
            bottom: 40,
            right: 10,
            child: _getPageIndexWidget(),
          ),
        ],
      ),
    );
  }

  /// * 页数指示器
  Widget _getPageIndexWidget() {
    if (imageVideoList.length <= 1) return sizedBox;
    return ObxValue((_) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: appThemeData.textTheme.bodyText2.color.withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          '${detailController.imageIndex.value + 1}/${imageVideoList.length}',
          style: appThemeData.textTheme.bodyText2.copyWith(
              color: appThemeData.backgroundColor, fontSize: 12, height: 1.25),
        ),
      );
    }, detailController.imageIndex);
  }

  /// * 单个视频
  Widget _getVideoWidget(ImageVideo item) {
    final child = Stack(
      children: [
        ContainerImage(
          item.thumbUrl,
          width: widgetWidth,
          height: widgetHeight,
          thumbWidth: CircleController.circleThumbWidth,
          fit: BoxFit.contain,
          cacheManager: CircleCachedManager.instance,
          placeHolder: (_, url) =>
              const Center(child: CupertinoActivityIndicator()),
        ),
        Center(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: WebsafeSvg.asset(SvgIcons.circleVideoPlay,
                width: 25, height: 32),
          ),
        ),
      ],
    );
    return child;
  }
}
