import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/image_builder.dart';
import 'package:im/utils/image_operator_collection/image_widget.dart';
import 'package:im/widgets/avatar.dart';

import '../../../../../themes/const.dart';
import '../../../../../utils/utils.dart';

class LiveCard extends StatelessWidget {
  final LiveCardInfo cardInfo;
  final LiveCardStatus status;

  LiveCard({Key key, this.status, this.cardInfo}) : super(key: key);

  // 接口定义： 1-等待直播（等待直播）2-正在直播（直播中）3-直播结束（直播结束）4-直播回放
  // 前面加个默认的直播结束
  final liveStatusDesc = [
    '直播结束'.tr,
    '等待直播'.tr,
    '正在直播'.tr,
    '直播已结束'.tr,
    '直播回放'.tr,
  ];

  @override
  Widget build(BuildContext context) {
    final disableColor = Theme.of(context).disabledColor;
    // final borderColor = disableColor.withOpacity(0.25);
    // final bgColor = disableColor.withOpacity(0.15);
    const bgColor = Color(0xFFF5F5F8);
    // const borderColor = bgColor;
    final failedColor = disableColor.withOpacity(0.65);

    const nameStyle = TextStyle(
      color: Color(0xFF1A1A1A),
      fontSize: 15,
      height: 1.2,
      fontWeight: FontWeight.bold,
    );
    const titleStyle =
        TextStyle(color: Colors.white, fontSize: 14, height: 1.21);
    final disableStyle = TextStyle(color: disableColor, fontSize: 14);

    const double outerRadius = 7;

    if (status == LiveCardStatus.loading) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 181.5, maxHeight: 273),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(outerRadius),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 236,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  child: Container(
                    color: bgColor,
                    child: Center(
                      child: DefaultTheme.defaultLoadingIndicator(),
                    ),
                  ),
                ),
              ),
              Container(
                height: 35,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    sizeWidth12,
                    ClipOval(
                      child: Container(width: 20, height: 20, color: bgColor),
                    ),
                    sizeWidth6,
                    Container(width: 62, height: 18, color: bgColor)
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (status == LiveCardStatus.success) {
      int status = cardInfo?.status ?? 0;
      status = (status >= liveStatusDesc.length) ? 0 : status;
      final statusDesc = liveStatusDesc[status];
      final isOverStatus = status == 3;

      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 181.5, maxHeight: 273),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(outerRadius),
          ),
          child: Column(
            children: [
              // 封面logo
              SizedBox(
                width: 179.5,
                height: 236,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      LayoutBuilder(
                        builder: (context, c) {
                          final rawUrl = cardInfo.roomCover ?? '';
                          final pr = MediaQuery.of(context).devicePixelRatio;
                          final imageUrl = rawUrl.isEmpty
                              ? ''
                              : fetchCdnThumbUrl(
                                  cardInfo.roomCover, pr * c.maxWidth);
                          return Container(
                            foregroundDecoration: BoxDecoration(
                                border: Border.all(
                                    color: appThemeData.dividerColor)),
                            child: ImageWidget.fromCachedNet(
                              CachedImageBuilder(
                                imageUrl: imageUrl,
                                cacheManager: CustomCacheManager.instance,
                                fit: BoxFit.cover,
                                // memCacheWidth: (c.maxWidth * pr).toInt(),
                                // memCacheHeight: (c.maxHeight * pr).toInt(),
                              ),
                            ),
                          );
                        },
                      ),
                      // 直播结束状态的蒙层
                      Offstage(
                        offstage: !isOverStatus,
                        child: Container(color: const Color(0x80000000)),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Offstage(
                          offstage: isOverStatus,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            height: 20,
                            decoration: BoxDecoration(
                              color: CustomColor.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  IconFont.buffChatLive,
                                  size: 11,
                                  color: Colors.white,
                                ),
                                sizeWidth3,
                                Text(
                                  // cardInfo.living ? '直播中'.tr : '回放'.tr,
                                  statusDesc,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 6.5,
                        right: 12,
                        child: Text(
                          cardInfo.roomTitle,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                      ),
                      Offstage(
                        offstage: !isOverStatus,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                IconFont.buffChatLive,
                                size: 17,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5.5),
                              Text(
                                statusDesc,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    height: 1.21),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Container(
                height: 35,
                decoration: const BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(6),
                  ),
                ),
                child: Row(
                  children: [
                    sizeWidth12,
                    Avatar(
                      url: cardInfo.anchorAvatar,
                      radius: 20 / 2,
                      showBorder: false,
                    ),
                    sizeWidth6,
                    Expanded(
                      child: Text(
                        cardInfo.anchorNick,
                        style: nameStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      width: 181.5,
      height: 273,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(outerRadius),
        color: Colors.white,
      ),
      child: Column(
        children: [
          const SizedBox(height: 94),
          Icon(IconFont.buffImgLoadFail, color: failedColor, size: 32),
          sizeHeight16,
          Text('直播间解析失败'.tr, style: disableStyle),
        ],
      ),
    );
  }
}

class LiveCardInfo {
  String roomCover;
  String roomTitle;
  String anchorAvatar;
  String anchorNick;
  int status;

  LiveCardInfo({
    this.roomCover,
    this.roomTitle,
    this.anchorAvatar,
    this.anchorNick,
    this.status,
  });
}

enum LiveCardStatus {
  loading,
  success,
  failed,
}
