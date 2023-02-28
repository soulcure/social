import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:im/utils/custom_cache_manager.dart';

abstract class ImageBuilder {
  Widget get buildWidget;
}

class CachedImageBuilder extends ImageBuilder {
  final Key key;
  final BaseCacheManager cacheManager;
  final String imageUrl;
  final ImageWidgetBuilder imageBuilder;
  final PlaceholderWidgetBuilder placeholder;
  final ProgressIndicatorBuilder progressIndicatorBuilder;
  final LoadingErrorWidgetBuilder errorWidget;
  final Duration placeholderFadeInDuration;
  final Duration fadeOutDuration;
  final Curve fadeOutCurve;
  final Duration fadeInDuration;
  final Curve fadeInCurve;
  final double width;
  final double height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final bool matchTextDirection;
  final Map<String, String> httpHeaders;
  final bool useOldImageOnUrlChange;
  final Color color;
  final BlendMode colorBlendMode;
  final FilterQuality filterQuality;
  final int memCacheWidth;
  final int memCacheHeight;

  CachedImageBuilder({
    this.key,
    @required this.imageUrl,
    this.imageBuilder,
    this.placeholder,
    this.progressIndicatorBuilder,
    this.errorWidget,
    this.placeholderFadeInDuration,
    this.fadeOutDuration = const Duration(milliseconds: 1000),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.httpHeaders,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    this.cacheManager,
    this.useOldImageOnUrlChange = false,
    this.color,
    this.colorBlendMode,
    this.filterQuality = FilterQuality.low,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget get buildWidget => CachedNetworkImage(
        imageUrl: imageUrl,
        key: key,
        httpHeaders: httpHeaders,
        imageBuilder: imageBuilder,
        placeholder: placeholder,
        progressIndicatorBuilder: progressIndicatorBuilder,
        errorWidget: errorWidget,
        fadeOutDuration: fadeOutDuration,
        fadeOutCurve: fadeOutCurve,
        fadeInDuration: fadeInDuration,
        fadeInCurve: fadeInCurve,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        matchTextDirection: matchTextDirection,
        cacheManager: cacheManager ?? CustomCacheManager.instance,
        useOldImageOnUrlChange: useOldImageOnUrlChange,
        color: color,
        filterQuality: filterQuality,
        colorBlendMode: colorBlendMode,
        placeholderFadeInDuration: placeholderFadeInDuration,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
      );
}

abstract class _SystemImageBuilder extends ImageBuilder {
  final ImageFrameBuilder frameBuilder;
  final ImageLoadingBuilder loadingBuilder;
  final ImageErrorWidgetBuilder errorBuilder;
  final double width;
  final double height;
  final Color color;
  final FilterQuality filterQuality;
  final BlendMode colorBlendMode;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final Rect centerSlice;
  final bool matchTextDirection;
  final bool gaplessPlayback;
  final String semanticLabel;
  final bool excludeFromSemantics;
  final bool isAntiAlias;
  final Key key;
  final double scale;
  final int cacheWidth;
  final int cacheHeight;

  _SystemImageBuilder(
      {this.frameBuilder,
      this.key,
      this.scale,
      this.cacheWidth,
      this.cacheHeight,
      this.loadingBuilder,
      this.errorBuilder,
      this.width,
      this.height,
      this.color,
      this.filterQuality,
      this.colorBlendMode,
      this.fit,
      this.alignment,
      this.repeat,
      this.centerSlice,
      this.matchTextDirection,
      this.gaplessPlayback,
      this.semanticLabel,
      this.excludeFromSemantics,
      this.isAntiAlias});
}

class NetworkImageBuilder extends _SystemImageBuilder {
  final String src;
  final Map<String, String> headers;

  NetworkImageBuilder(
    this.src, {
    Key key,
    this.headers,
    double scale = 1.0,
    int cacheWidth,
    int cacheHeight,
    ImageFrameBuilder frameBuilder,
    ImageLoadingBuilder loadingBuilder,
    ImageErrorWidgetBuilder errorBuilder,
    String semanticLabel,
    bool excludeFromSemantics = false,
    double width,
    double height,
    Color color,
    BlendMode colorBlendMode,
    BoxFit fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    FilterQuality filterQuality = FilterQuality.low,
    bool isAntiAlias = false,
  }) : super(
          key: key,
          scale: scale,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          frameBuilder: frameBuilder,
          loadingBuilder: loadingBuilder,
          errorBuilder: errorBuilder,
          width: width,
          height: height,
          color: color,
          filterQuality: filterQuality,
          colorBlendMode: colorBlendMode,
          fit: fit,
          alignment: alignment,
          repeat: repeat,
          centerSlice: centerSlice,
          matchTextDirection: matchTextDirection,
          gaplessPlayback: gaplessPlayback,
          semanticLabel: semanticLabel,
          excludeFromSemantics: excludeFromSemantics,
          isAntiAlias: isAntiAlias,
        );

  @override
  Widget get buildWidget => Image.network(
        src,
        key: key,
        scale: scale,
        frameBuilder: frameBuilder,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder,
        semanticLabel: semanticLabel,
        excludeFromSemantics: excludeFromSemantics,
        width: width,
        height: height,
        color: color,
        colorBlendMode: colorBlendMode,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        centerSlice: centerSlice,
        matchTextDirection: matchTextDirection,
        gaplessPlayback: gaplessPlayback,
        filterQuality: filterQuality,
        isAntiAlias: isAntiAlias,
        headers: headers,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
      );
}

class AssetImageBuilder extends _SystemImageBuilder {
  final String name;
  final AssetBundle bundle;
  final String package;

  AssetImageBuilder(
    this.name, {
    Key key,
    this.bundle,
    this.package,
    double scale = 1.0,
    int cacheWidth,
    int cacheHeight,
    ImageFrameBuilder frameBuilder,
    ImageErrorWidgetBuilder errorBuilder,
    String semanticLabel,
    bool excludeFromSemantics = false,
    double width,
    double height,
    Color color,
    BlendMode colorBlendMode,
    BoxFit fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    FilterQuality filterQuality = FilterQuality.low,
    bool isAntiAlias = false,
  }) : super(
          key: key,
          scale: scale,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          frameBuilder: frameBuilder,
          errorBuilder: errorBuilder,
          width: width,
          height: height,
          color: color,
          filterQuality: filterQuality,
          colorBlendMode: colorBlendMode,
          fit: fit,
          alignment: alignment,
          repeat: repeat,
          centerSlice: centerSlice,
          matchTextDirection: matchTextDirection,
          gaplessPlayback: gaplessPlayback,
          semanticLabel: semanticLabel,
          excludeFromSemantics: excludeFromSemantics,
          isAntiAlias: isAntiAlias,
        );

  @override
  Widget get buildWidget => Image.asset(
        name,
        key: key,
        scale: scale,
        frameBuilder: frameBuilder,
        errorBuilder: errorBuilder,
        semanticLabel: semanticLabel,
        excludeFromSemantics: excludeFromSemantics,
        width: width,
        height: height,
        color: color,
        colorBlendMode: colorBlendMode,
        fit: fit,
        package: package,
        alignment: alignment,
        repeat: repeat,
        centerSlice: centerSlice,
        matchTextDirection: matchTextDirection,
        gaplessPlayback: gaplessPlayback,
        filterQuality: filterQuality,
        isAntiAlias: isAntiAlias,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
      );
}

class FileImageBuilder extends _SystemImageBuilder {
  final File file;

  FileImageBuilder(
    this.file, {
    Key key,
    double scale = 1.0,
    int cacheWidth,
    int cacheHeight,
    ImageFrameBuilder frameBuilder,
    ImageErrorWidgetBuilder errorBuilder,
    String semanticLabel,
    bool excludeFromSemantics = false,
    double width,
    double height,
    Color color,
    BlendMode colorBlendMode,
    BoxFit fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    bool isAntiAlias = false,
    FilterQuality filterQuality = FilterQuality.low,
  }) : super(
          key: key,
          scale: scale,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          frameBuilder: frameBuilder,
          errorBuilder: errorBuilder,
          width: width,
          height: height,
          color: color,
          filterQuality: filterQuality,
          colorBlendMode: colorBlendMode,
          fit: fit,
          alignment: alignment,
          repeat: repeat,
          centerSlice: centerSlice,
          matchTextDirection: matchTextDirection,
          gaplessPlayback: gaplessPlayback,
          semanticLabel: semanticLabel,
          excludeFromSemantics: excludeFromSemantics,
          isAntiAlias: isAntiAlias,
        );

  @override
  Widget get buildWidget => Image.file(
        file,
        key: key,
        scale: scale,
        frameBuilder: frameBuilder,
        errorBuilder: errorBuilder,
        semanticLabel: semanticLabel,
        excludeFromSemantics: excludeFromSemantics,
        width: width,
        height: height,
        color: color,
        colorBlendMode: colorBlendMode,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        centerSlice: centerSlice,
        matchTextDirection: matchTextDirection,
        gaplessPlayback: gaplessPlayback,
        filterQuality: filterQuality,
        isAntiAlias: isAntiAlias,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
      );

  FileImageBuilder.fromCachedBuilder(CachedImageBuilder imageBuilder, this.file)
      : super(
          key: imageBuilder.key,
          cacheWidth: imageBuilder.memCacheWidth,
          cacheHeight: imageBuilder.memCacheHeight,
          width: imageBuilder.width,
          height: imageBuilder.height,
          color: imageBuilder.color,
          filterQuality: imageBuilder.filterQuality,
          colorBlendMode: imageBuilder.colorBlendMode,
          fit: imageBuilder.fit,
          alignment: imageBuilder.alignment,
          repeat: imageBuilder.repeat,
          matchTextDirection: imageBuilder.matchTextDirection,
          scale: 1,
          gaplessPlayback: false,
          excludeFromSemantics: false,
          isAntiAlias: false,
        );
}

class MemoryImageBuilder extends _SystemImageBuilder {
  final Uint8List bytes;

  MemoryImageBuilder(
    this.bytes, {
    Key key,
    double scale = 1.0,
    int cacheWidth,
    int cacheHeight,
    ImageFrameBuilder frameBuilder,
    ImageErrorWidgetBuilder errorBuilder,
    String semanticLabel,
    bool excludeFromSemantics = false,
    double width,
    double height,
    Color color,
    BlendMode colorBlendMode,
    BoxFit fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    bool isAntiAlias = false,
    FilterQuality filterQuality = FilterQuality.low,
  }) : super(
          key: key,
          scale: scale,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          frameBuilder: frameBuilder,
          errorBuilder: errorBuilder,
          width: width,
          height: height,
          color: color,
          filterQuality: filterQuality,
          colorBlendMode: colorBlendMode,
          fit: fit,
          alignment: alignment,
          repeat: repeat,
          centerSlice: centerSlice,
          matchTextDirection: matchTextDirection,
          gaplessPlayback: gaplessPlayback,
          semanticLabel: semanticLabel,
          excludeFromSemantics: excludeFromSemantics,
          isAntiAlias: isAntiAlias,
        );

  @override
  Widget get buildWidget => Image.memory(
        bytes,
        key: key,
        scale: scale,
        frameBuilder: frameBuilder,
        errorBuilder: errorBuilder,
        semanticLabel: semanticLabel,
        excludeFromSemantics: excludeFromSemantics,
        width: width,
        height: height,
        color: color,
        colorBlendMode: colorBlendMode,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        centerSlice: centerSlice,
        matchTextDirection: matchTextDirection,
        gaplessPlayback: gaplessPlayback,
        filterQuality: filterQuality,
        isAntiAlias: isAntiAlias,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
      );
}
