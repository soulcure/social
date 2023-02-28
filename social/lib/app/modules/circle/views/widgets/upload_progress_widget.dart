import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/modules/circle/models/upload_status_model.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/circle/content/circle_post_image_item.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/custom_cache_manager.dart';

class UploadProgressWidget extends StatefulWidget {
  const UploadProgressWidget({Key key}) : super(key: key);

  @override
  _UploadProgressWidgetState createState() => _UploadProgressWidgetState();
}

class _UploadProgressWidgetState extends State<UploadProgressWidget> {
  final circleController = Get.find<CircleController>();

  Widget resourceBackgroundWidget() {
    Widget imageWidget(CirclePostImageItem asset) {
      if (asset == null) return sizedBox;

      final bool isNetworkUrl = (asset?.url?.startsWith('http://') ?? false) ||
          (asset?.url?.startsWith('https://') ?? false);

      // 安卓端经常会返回0，导致异常
      final itemHeight = asset.height == 0 ? 40 : asset.height;
      final itemWidth = asset.width == 0 ? 40 : asset.width;

      final height = (Get.pixelRatio * 40).toInt();
      final width = (height * (itemWidth / itemHeight)).toInt();

      if (isNetworkUrl) {
        final thumbUrl = asset.type == 'video' ? asset.thumbUrl : asset.url;
        return ContainerImage(
          thumbUrl,
          thumbWidth:
              (Get.size.width * MediaQuery.of(context).devicePixelRatio).ceil(),
          fit: BoxFit.fitWidth,
          placeHolder: (context, url) =>
              const Center(child: CupertinoActivityIndicator()),
          cacheManager: CircleCachedManager.instance,
        );
      } else {
        final imageName = asset.type == 'video' ? asset.thumbName : asset.name;
        final path = '${Global.deviceInfo.mediaDir}$imageName';
        return Image.file(
          File(path),
          fit: BoxFit.fitWidth,
          cacheHeight: height,
          cacheWidth: width,
        );
      }
    }

    return ValueListenableBuilder<Box>(
        valueListenable:
            Db.circleDraftBox.listenable(keys: [circleController.channelId]),
        builder: (context, box, child) {
          final CirclePostInfoDataModel model =
              box.get(circleController.channelId);
          final asset = CirclePostInfoDataModel.getMediaList(
                  model.contentV2, model.content, model.postType)
              .map((e) => CirclePostImageItem.fromJson(e))
              .toList()
              .first;
          return imageWidget(asset);
        });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UploadStatusController>(
        init: UploadStatusController.to,
        builder: (controller) {
          final status = controller.cache[circleController.channelId];
          if (status == null) return sizedBox;
          return Container(
            height: 58,
            color: appThemeData.backgroundColor,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      sizeWidth16,
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: resourceBackgroundWidget(),
                              ),
                              Positioned.fill(
                                  child: Container(
                                color: Colors.black.withOpacity(0.2),
                              )),
                              Positioned(
                                  top: 12,
                                  left: 0,
                                  right: 0,
                                  child: Text(
                                    '${status.progress ?? 0}%',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  )),
                            ],
                          ),
                        ),
                      ),
                      sizeWidth12,
                      Expanded(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            !status.isUploadFail ? '正在上传中' : '动态发布失败，已保存至草稿',
                            style: appThemeData.textTheme.bodyText2.copyWith(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          sizeHeight4,
                          Text(
                            !status.isUploadFail
                                ? '分享有趣的图片视频，收获更多赞'
                                : '请点击重试，或重新编辑发布',
                            style: appThemeData.textTheme.bodyText1
                                .copyWith(fontSize: 12),
                          ),
                        ],
                      )),
                      if (status.isUploadFail) ...[
                        IconButton(
                            onPressed: () => CircleController.sendDynamic(
                                channelId: circleController.channelId,
                                guildId: circleController.guildId),
                            icon: Icon(
                              IconFont.buffWebviewRefresh,
                              size: 20,
                              color: appThemeData.primaryColor,
                            )),
                        const SizedBox(height: 10, child: VerticalDivider()),
                        IconButton(
                            onPressed: () {
                              UploadStatusController.to.updateProgress(
                                  circleController.channelId,
                                  progress: 100);
                            },
                            icon: const Icon(
                              IconFont.buffNavBarCloseItem,
                              size: 20,
                            )),
                      ]
                      // close
                    ],
                  ),
                ),
                LinearProgressIndicator(
                  value: (status.progress ?? 0).toDouble() / 100,
                  minHeight: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(appThemeData.primaryColor),
                )
              ],
            ),
          );
        });
  }
}
