import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:im/core/config.dart' as app_config;
import 'package:im/themes/const.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/cached_image_refresher.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';

class ContainerImage extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final double quality;
  final String url;
  final BoxFit fit;
  final int thumbHeight;
  final int thumbWidth;
  final PlaceholderWidgetBuilder placeHolder;
  final ProgressIndicatorBuilder progressIndicatorBuilder;
  final BaseCacheManager cacheManager;

  static int get defaultThumbSize => 445;

  const ContainerImage(
    this.url, {
    Key key,
    this.fit,
    this.width,
    this.height,
    this.thumbHeight = -1,
    this.thumbWidth = -1,
    this.radius = 0.0,
    this.quality = 1.5,
    this.cacheManager,
    this.placeHolder,
    this.progressIndicatorBuilder,
  }) : super(key: key);

  @override
  _ContainerImageState createState() => _ContainerImageState();

  static String getThumbUrl(String url,
      {int thumbWidth = -1, int thumbHeight = -1}) {
    if (url.endsWith('gif')) return url;
    if (thumbHeight > 0 && thumbWidth > 0) {
      return '$url?imageMogr2${app_config.Config.webpPath}/thumbnail/${thumbWidth}x$thumbHeight';
    } else if (thumbHeight > 0) {
      return '$url?imageMogr2${app_config.Config.webpPath}/thumbnail/x$thumbHeight';
    } else if (thumbWidth > 0) {
      return '$url?imageMogr2${app_config.Config.webpPath}/thumbnail/${thumbWidth}x';
    } else {
      return '$url?imageMogr2${app_config.Config.webpPath}/thumbnail/${defaultThumbSize}x$defaultThumbSize';
    }
  }
}

class _ContainerImageState extends State<ContainerImage> {
  String url;
  bool hasError = false;
  bool isImgCached = false;

  @override
  void initState() {
    url = widget.url;
    if (!_errorUrls.contains(url))
      url = transformToThumb(url);
    else
      hasError = true;

    isCached();
    super.initState();
  }

  Future isCached() async {
    isImgCached = await isResCached(
        widget.cacheManager ?? CustomCacheManager.instance, url);
    if (mounted && isImgCached) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasSize = widget.width != null || widget.height != null;
    if (hasSize) {
      return buildBody(widget.width, widget.height);
    } else {
      return LayoutBuilder(builder: (ctx, constraints) {
        return buildBody(constraints.maxWidth, constraints.maxHeight);
      });
    }
  }

  Widget buildBody(double width, double height) {
    if (hasError)
      return buildResizeImage(width, height);
    else
      return buildSizedBox(widget.width ?? width, widget.height ?? height);
  }

  Widget buildSizedBox(double width, double height) {
    int rH = ContainerImage.defaultThumbSize;
    int rW = ContainerImage.defaultThumbSize;
    if (widget.thumbHeight > 0) rH = widget.thumbHeight;
    if (widget.thumbWidth > 0) rW = widget.thumbWidth;

    ///使用decoration展示的图片需要设置一个宽高，否则无法展示图片。
    ///外层再套用一个父容器，是为了处理图片大小自适应的一个情况，参考聊天列表里的根据高度自适应和表情包tab里的根据size自适应
    return SizedBox(
      width: width,
      height: height,
      child: CachedImageRefresher(
        url: url,
        cacheManager: widget.cacheManager,
        onConnectWidget: (file, ctx) async {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(widget.radius)),
              image: DecorationImage(
                  image: (rW != null)
                      ? ResizeImage(FileProviderBuilder(file).provider,
                          width: rW)
                      : ((rH != null)
                          ? ResizeImage(FileProviderBuilder(file).provider,
                              height: rH)
                          : FileProviderBuilder(file).provider),
                  fit: widget.fit ?? BoxFit.contain),
            ),
          );
        },
        child: SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(widget.radius)),
            clipBehavior: Clip.hardEdge,
            child: ImageWidget.fromCachedNet(
              CachedImageBuilder(
                  imageUrl: url,
                  cacheManager:
                      widget.cacheManager ?? CustomCacheManager.instance,
                  fit: widget.fit ?? BoxFit.contain,
                  placeholder: widget.placeHolder,
                  progressIndicatorBuilder: widget.progressIndicatorBuilder,
                  fadeInDuration: isImgCached
                      ? const Duration()
                      : const Duration(milliseconds: 500),
                  memCacheWidth: rW,
                  memCacheHeight: rW == null ? rH : null,
                  errorWidget: (ctx, url, error) {
                    if (error is SocketException &&
                        error.osError.errorCode == 7) {
                      return sizedBox;
                    }
                    hasError = true;

                    this.url = widget.url;
                    _errorUrls.add(widget.url);
                    // 图片太大，cdn转缩略图会失败，错误码：HttpExceptionWithStatus/400
                    // 这个时候使用原链接再渲染请求一次。
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                      if (mounted) setState(() {});
                    });
                    return sizedBox;
                  }),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildResizeImage(double width, double height) => ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(widget.radius)),
        clipBehavior: Clip.hardEdge,
        child: ResizedImage(
          url,
          width: width,
          height: height,
          quality: widget.quality,
          fit: widget.fit,
          radius: widget.radius,
          cacheManager: widget.cacheManager,
        ),
      );

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant ContainerImage oldWidget) {
    if (!_errorUrls.contains(widget.url))
      url = hasError ? widget.url : transformToThumb(widget.url);
    super.didUpdateWidget(oldWidget);
  }

  String transformToThumb(String url) {
    if (url.endsWith('gif')) return url;
    if (widget.thumbHeight > 0 && widget.thumbWidth > 0) {
      return '$url?imageMogr2${app_config.Config.webpPath}/thumbnail/${widget.thumbWidth}x${widget.thumbHeight}';
    } else if (widget.thumbHeight > 0) {
      return '$url?imageMogr2${app_config.Config.webpPath}/thumbnail/x${widget.thumbHeight}';
    } else if (widget.thumbWidth > 0) {
      return '$url?imageMogr2${app_config.Config.webpPath}/thumbnail/${widget.thumbWidth}x';
    } else {
      return '$url?imageMogr2${app_config.Config.webpPath}/thumbnail/${ContainerImage.defaultThumbSize}x${ContainerImage.defaultThumbSize}';
    }
  }
}

///保存所有有问题的url
final Set<String> _errorUrls = {};

class ResizedImage extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final double quality;
  final String url;
  final BoxFit fit;
  final BaseCacheManager cacheManager;

  const ResizedImage(
    this.url, {
    Key key,
    this.fit,
    this.width,
    this.height,
    this.radius = 0.0,
    this.quality,
    this.cacheManager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasSize = width != null || height != null;
    if (hasSize)
      return buildSizedBox(width, height, context);
    else
      return LayoutBuilder(builder: (ctx, constraints) {
        return buildSizedBox(
            constraints.maxWidth, constraints.maxHeight, context);
      });
  }

  Widget buildSizedBox(double width, double height, BuildContext context) {
    int rH;
    int rW;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    if (height != null)
      rH = (height.toInt() * (quality ?? devicePixelRatio)).toInt();
    if (width != null)
      rW = (width.toInt() * (quality ?? devicePixelRatio)).toInt();

    return SizedBox(
      width: width,
      height: height,
      child: CachedImageRefresher(
        url: url,
        cacheManager: cacheManager,
        onConnectWidget: (file, ctx) async {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(radius)),
              image: DecorationImage(
                image: ResizeImage(FileProviderBuilder(file).provider,
                    width: rW, height: rH),
                fit: fit ?? BoxFit.contain,
              ),
            ),
          );
        },
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(radius)),
          ),
          child: Image(
            image: ResizeImage(
                CachedProviderBuilder(url,
                        cacheManager:
                            cacheManager ?? CustomCacheManager.instance)
                    .provider,
                width: rW,
                height: rH),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CupertinoActivityIndicator());
            },
            fit: fit ?? BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class ResizedLoadingImage extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final double quality;
  final String url;
  final BoxFit fit;
  final Widget loadingWidget;
  final BaseCacheManager cacheManager;

  const ResizedLoadingImage(
    this.url, {
    Key key,
    this.fit,
    this.width,
    this.height,
    this.radius = 0.0,
    this.quality,
    this.loadingWidget,
    this.cacheManager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasSize = width != null || height != null;
    if (hasSize)
      return buildSizedBox(width, height, context);
    else
      return LayoutBuilder(builder: (ctx, constraints) {
        return buildSizedBox(
            constraints.maxWidth, constraints.maxHeight, context);
      });
  }

  Widget buildSizedBox(double width, double height, BuildContext context) {
    int rH;
    int rW;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    if (height != null)
      rH = (height.toInt() * (quality ?? devicePixelRatio)).toInt();
    if (width != null)
      rW = (width.toInt() * (quality ?? devicePixelRatio)).toInt();
    final isHeightBigger =
        (height ?? double.infinity) > (width ?? double.infinity);
    final result = isHeightBigger
        ? ResizeImage(
            CachedProviderBuilder(url,
                    cacheManager: cacheManager ?? CustomCacheManager.instance)
                .provider,
            width: rW,
            allowUpscaling: true)
        : ResizeImage(
            CachedProviderBuilder(url,
                    cacheManager: cacheManager ?? CustomCacheManager.instance)
                .provider,
            height: rH,
            allowUpscaling: true);
    final child = LoadingImage(
      image: result,
      fit: fit ?? BoxFit.contain,
      loadingWidget: loadingWidget ?? sizedBox,
    );
    final hasRadius = radius != null && radius != 0.0;
    return SizedBox(
        width: width,
        height: height,
        child: hasRadius
            ? ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(radius)),
                child: child)
            : child);
  }
}

class LoadingImage extends StatelessWidget {
  final double width;

  final double height;

  final BoxFit fit;

  final ImageProvider image;

  final AlignmentGeometry alignment;

  final ImageRepeat repeat;

  final bool matchTextDirection;

  final Widget loadingWidget;

  final Widget errorWidget;

  const LoadingImage({
    Key key,
    this.width,
    this.height,
    this.fit,
    this.image,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    this.loadingWidget,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _image(
      image: image,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame == null)
          return loadingWidget ??
              const Center(
                child: CircularProgressIndicator(),
              );
        return child;
      },
      errorBuilder: (ctx, error, trace) => errorWidget ?? sizedBox,
    );
  }

  Image _image({
    @required ImageProvider image,
    ImageErrorWidgetBuilder errorBuilder,
    ImageFrameBuilder frameBuilder,
  }) {
    assert(image != null);
    return Image(
      image: image,
      errorBuilder: errorBuilder,
      frameBuilder: frameBuilder,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );
  }
}
