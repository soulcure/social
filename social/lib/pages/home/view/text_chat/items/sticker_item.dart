import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:im/api/entity/sticker_bean.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/image_operator_collection/image_builder.dart';
import 'package:im/utils/image_operator_collection/image_widget.dart';
import 'package:im/utils/image_operator_collection/status_widget.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/texture_image.dart';
import 'package:tuple/tuple.dart';

import '../../../../../routes.dart';

class StickerItem extends StatefulWidget {
  final StickerEntity entity;

  const StickerItem({Key key, this.entity}) : super(key: key);

  @override
  _StickerItemState createState() => _StickerItemState();
}

class _StickerItemState extends State<StickerItem> {
  int _key = 0;

  @override
  Widget build(BuildContext context) {
    // 26 = 122/225*48
    final size = getImageSize(widget.entity.width, widget.entity.height,
        maxSizeConstraint: 122, minSizeConstraint: 26);
    final w = size.item1?.toDouble(), h = size.item2?.toDouble();
    final fit = size.item3;
    return GestureDetector(
      onTap: () {
        Routes.pushStickPage(
            context,
            StickerBean(widget.entity.url, widget.entity.name,
                width: w, height: h));
      },
      child: Container(
          alignment: Alignment.centerLeft,
          width: w,
          height: h,
          child: _imageWidget(w, h, fit: fit)),
    );
  }

  Widget _imageWidget(double w, double h, {BoxFit fit = BoxFit.contain}) {
    final url = spliceGif(widget.entity?.url);
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final memW = (w * devicePixelRatio).toInt();
    final memH = (h * devicePixelRatio).toInt();

    if (UniversalPlatform.isMobileDevice && TextureImage.useTexture) {
      return TextureImage(
        url,
        key: ValueKey("$url$_key"),
        width: w * devicePixelRatio,
        height: h * devicePixelRatio,
        progressCallBack: (progress) {
          return buildProgressLoading(context, url, progress * 100);
        },
        errorCallBack: (error) {
          return Container(
            width: w,
            height: h,
            color: Theme.of(context).scaffoldBackgroundColor,
            child: imageLoadFailedWidget(context,
                maxWidth: memW, maxHeigth: memH, reload: () async {
              _key = _key + 1;
              refresh();
            }),
          );
        },
      );
    } else {
      return ImageWidget.fromCachedNet(
        CachedImageBuilder(
            key: ValueKey(_key),
            imageUrl: url,
            fit: fit,
            width: w,
            height: h,
            memCacheHeight: memH,
            memCacheWidth: memW,
            progressIndicatorBuilder: (ctx, url, progress) {
              return Container(
                width: w,
                height: h,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: buildDownloadProgressLoading(context, url, progress),
              );
            },
            errorWidget: (ctx, url, error) {
              return Container(
                width: w,
                height: h,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: imageLoadFailedWidget(context, maxWidth: w, maxHeigth: h,
                    reload: () async {
                  await evictImage(url, memW, memH);
                  _key = _key + 1;
                  refresh();
                }),
              );
            }),
      );
    }
  }

  void refresh() {
    if (mounted) setState(() {});
  }
}

class StickerPage extends StatelessWidget {
  final StickerBean bean;

  const StickerPage({Key key, this.bean}) : super(key: key);

  Widget _landscapeBody() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: ContainerImage(
        spliceGif(bean?.avatar),
        fit: BoxFit.contain,
        width: 180,
        height: 180,
      ),
    );
  }

  /// 计算在限定大小区域contain显示图片的大小
  Size _containSize(num maxW, num maxH, num factW, num factH) {
    var width = factW;
    var height = factH;
    if (width > maxW && height > maxH) {
      final r = min(maxH / height, maxW / width);
      width = width * r;
      height = height * r;
    } else if (width > maxW) {
      final r = maxW / width;
      width = width * r;
      height = height * r;
    } else if (height > maxH) {
      final r = maxH / height;
      width = width * r;
      height = height * r;
    }
    return Size(width, height);
  }

  @override
  Widget build(BuildContext context) {
    if (OrientationUtil.landscape) return _landscapeBody();

    final url = spliceGif(bean?.avatar);
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final imgSize = _containSize(
        MediaQuery.of(context).size.width - 2 * 38.0,
        225.0,
        2 * devicePixelRatio * (bean?.width ?? 225),
        2 * devicePixelRatio * (bean?.height ?? 225));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: SizedBox(
                height: 44,
                child: CustomAppbar(
                  elevation: 0.5,
                ),
              ),
            ),
          ),
          Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.only(left: 38, right: 38),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 225),
                    child: TextureImage.useTexture
                        ? TextureImage(
                            url,
                            width: imgSize.width,
                            height: imgSize.height,
                          )
                        : ContainerImage(
                            url,
                            width: imgSize.width,
                            height: imgSize.height,
                          ),
                  ),
                  sizeHeight16,
                  Text(
                    bean?.name ?? '',
                    style:
                        const TextStyle(fontSize: 17, color: Color(0xff1F2125)),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String spliceGif(String gif) {
  return gif ?? '';
}

Tuple3 getImageSize(double width, double height,
    {BoxFit defaultFit,
    double maxSizeConstraint = 112.5,
    double minSizeConstraint = 1.0}) {
  double w = width ?? 120;
  w = w > 0 ? w : 120;
  double h = height ?? 120;
  h = h > 0 ? h : 120;
  BoxFit fit = defaultFit ?? BoxFit.contain;
  if (w / h > (maxSizeConstraint / minSizeConstraint)) {
    // 横线长图
    w = maxSizeConstraint;
    h = minSizeConstraint;
    fit = BoxFit.fitHeight;
  } else if (h / w > (maxSizeConstraint / minSizeConstraint)) {
    // 纵向长图
    w = minSizeConstraint;
    h = maxSizeConstraint;
    fit = BoxFit.fitWidth;
  } else if (w > maxSizeConstraint || h > maxSizeConstraint) {
    final s = min(maxSizeConstraint / w, maxSizeConstraint / h);
    w = w * s;
    h = h * s;
  } else if (w < minSizeConstraint || h < minSizeConstraint) {
    final s = max(minSizeConstraint / w, minSizeConstraint / h);
    w = w * s;
    h = h * s;
  }
  return Tuple3(w, h, fit);
}

MediaData getSize(double width, double height,
    {double maxSize = 112.5, bool limitHeight = true}) {
  double w = width ?? 120;
  w = w > 0 ? w : 120;
  double h = height ?? 120;
  h = h > 0 ? h : 120;
  final radio = limitHeight ? (w / h) : (h / w);
  if (limitHeight) {
    if (maxSize > h) {
      return MediaData(w, h);
    } else {
      return MediaData(radio * maxSize, maxSize);
    }
  } else {
    if (maxSize > w) {
      return MediaData(w, h);
    } else {
      return MediaData(maxSize, radio * maxSize);
    }
  }
}

class MediaData {
  double width;
  double height;

  MediaData(this.width, this.height);
}
