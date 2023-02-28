import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/widgets/loading/circular_progress_indicator.dart';

import '../custom_cache_manager.dart';
import 'provider_builder.dart';

///图片加载时的进度展示
Widget buildDownloadProgressLoading(
    BuildContext context, String url, DownloadProgress downloadProgress) {
  final double value = (downloadProgress?.progress ?? 0.0) * 100;
  return buildProgressLoading(context, url, value);
}

Widget buildProgressLoading(BuildContext context, String url, double progress) {
  final showValue = progress.ceil();
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgress(
          size: 16,
          primaryColor: Theme.of(context).primaryColor,
          strokeWidth: 2,
        ),
        sizeHeight8,
        if (showValue != 0)
          Text(
            '$showValue%',
            style:
                TextStyle(color: Theme.of(context).disabledColor, fontSize: 13),
          )
      ],
    ),
  );
}

///图片上传时候展示的loading框,[progress]为0～100
Widget imageUploadingWidget(BuildContext context, int progress) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      sizeHeight8,
      Text(
        '$progress%',
        style:
            TextStyle(color: CustomColor(context).disableColor, fontSize: 13),
      )
    ],
  );
}

///视频上传时候展示的loading框,[progress]为0～100
Widget videoUploadingWidget(BuildContext context, int progress,
    {VoidCallback cancelCallback}) {
  final value = progress / 100;
  return Column(
    children: [
      GestureDetector(
        onTap: () => cancelCallback?.call(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.3),
          ),
          child: Stack(
            children: [
              const Center(
                  child: Icon(
                IconFont.buffNavBarCloseItem,
                color: Colors.white,
                size: 13,
              )),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: value,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  strokeWidth: 2,
                ),
              )
            ],
          ),
        ),
      ),
      sizeHeight8,
      Text(
        '$progress%',
        style: const TextStyle(color: Colors.white, fontSize: 13),
      )
    ],
  );
}

///图片加载失败后重新加载组件
Widget imageLoadFailedWidget(BuildContext context,
    {VoidCallback reload, num maxWidth = 48, num maxHeigth = 48}) {
  if (maxWidth <= 48 || maxHeigth <= 48) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: reload,
      child: Center(
        child: Icon(IconFont.buffImgLoadFail,
            size: min(24, maxWidth),
            color: const Color(0xFF8F959E).withOpacity(0.65)),
      ),
    );
  }

  return GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: reload,
    child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(IconFont.buffImgLoadFail,
          size: 24, color: const Color(0xFF8F959E).withOpacity(0.65)),
      sizeHeight8,
      Text(
        '点击重新加载'.tr,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: Color(0xff8F959E)),
      )
    ])),
  );
}

///重新加载cached_network_image前，去掉liveimages的缓存
Future evictImage(String url, int width, int height,
    {BaseCacheManager cacheManager}) async {
  final cacheProvider = CachedProviderBuilder(url,
          cacheManager: cacheManager ?? CustomCacheManager.instance)
      .provider;
  final provider = ResizeImage.resizeIfNeeded(
    width,
    height,
    cacheProvider,
  );
  return provider.evict();
}

///视频审核不通过展示组件
Widget videoRejectWidget(
  BuildContext context, {
  bool showBorder = false,
  double size = 60,
  double margin = 24,
  TextStyle testStyle,
  String message,
}) {
  final c1 = CustomColor(context).disableColor;
  return Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: showBorder ? BorderRadius.circular(8) : null,
        border: showBorder
            ? Border.all(
                color: CustomColor(context).backgroundColor1,
                width: 0.5,
              )
            : null),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          IconFont.buffVideoReject,
          color: CustomColor.red,
          size: size,
        ),
        SizedBox(
          height: margin,
        ),
        SizedBox(
          height: 40,
          child: Text(
            message ?? '视频包含违规内容'.tr,
            style: testStyle ?? TextStyle(color: c1, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class StatefulCallWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback initialCallback;
  final VoidCallback disposedCallback;

  const StatefulCallWidget({
    Key key,
    @required this.child,
    this.initialCallback,
    this.disposedCallback,
  }) : super(key: key);

  @override
  _StatefulCallWidgetState createState() => _StatefulCallWidgetState();
}

class _StatefulCallWidgetState extends State<StatefulCallWidget> {
  @override
  void initState() {
    super.initState();
    widget?.initialCallback?.call();
  }

  @override
  void dispose() {
    widget.disposedCallback?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
