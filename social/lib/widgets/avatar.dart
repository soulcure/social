import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/texture_image.dart';

class Avatar extends StatelessWidget {
  final String url;
  final double radius;
  final File file;
  final Key widgetKey;
  final BaseCacheManager cacheManager;
  final double size;
  final bool showBorder;
  final bool useTexture;

  const Avatar({
    this.url,
    this.file,
    this.radius = 15,
    this.widgetKey,
    this.cacheManager,
    this.size,
    this.showBorder,
    this.useTexture = true,
  });

  @override
  Widget build(BuildContext context) {
    if (UniversalPlatform.isMobileDevice &&
        useTexture &&
        TextureImage.useTexture) {
      return TextureAvatar(
          url: url,
          file: file,
          radius: radius,
          widgetKey: widgetKey,
          cacheManager: cacheManager,
          size: size,
          showBorder: showBorder);
    } else {
      return FlutterAvatar(
          url: url,
          file: file,
          radius: radius,
          widgetKey: widgetKey,
          cacheManager: cacheManager,
          size: size,
          showBorder: showBorder);
    }
  }
}

class TextureAvatar extends StatelessWidget {
  final String url;
  final double radius;
  final File file;
  final Key widgetKey;
  final BaseCacheManager cacheManager;
  final double size;
  final bool showBorder;

  const TextureAvatar({
    this.url,
    this.file,
    this.radius = 15,
    this.widgetKey,
    this.cacheManager,
    this.size,
    this.showBorder,
  });

  // : assert((file == null && url != null && url != '') || (file != null),
  //       'file and url cannot be empty at the same time');
  @override
  Widget build(BuildContext context) {
    final _size = size ?? radius * 2;
    final borderColor = Theme.of(context).disabledColor.withOpacity(0.3);
    final _showBorder = showBorder ?? true;
    final foregroundDecoration = BoxDecoration(
      border: _showBorder ? Border.all(color: borderColor, width: 0.5) : null,
      shape: BoxShape.circle,
    );
    const innerDecoration = BoxDecoration(
      color: Color(0xFFf0f1f2),
      shape: BoxShape.circle,
    );
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    if (file == null && (url == null || url == ''))
      return Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor,
          shape: BoxShape.circle,
        ),
      );
    if (file != null)
      return Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
          shape: BoxShape.circle,
        ),
        foregroundDecoration: foregroundDecoration,
      );
    return Container(
      width: _size,
      height: _size,
      decoration: innerDecoration,
      foregroundDecoration: foregroundDecoration,
      child: TextureImage(url,
          key: widgetKey,
          width: _size * devicePixelRatio,
          height: _size * devicePixelRatio,
          radius: radius * devicePixelRatio),
    );
  }
}

/// ????????????
class FlutterAvatar extends StatelessWidget {
  final String url;
  final double radius;
  final File file;
  final Key widgetKey;
  final BaseCacheManager cacheManager;
  final double size;
  final bool showBorder;

  const FlutterAvatar({
    this.url,
    this.file,
    this.radius = 15,
    this.widgetKey,
    this.cacheManager,
    this.size,
    this.showBorder,
  });

  // : assert((file == null && url != null && url != '') || (file != null),
  //       'file and url cannot be empty at the same time');
  @override
  Widget build(BuildContext context) {
    final _size = size ?? radius * 2;
    final borderColor = appThemeData.dividerColor.withOpacity(0.2);
    final _showBorder = showBorder ?? true;
    final foregroundDecoration = BoxDecoration(
      border: _showBorder ? Border.all(color: borderColor, width: 0.5) : null,
      shape: BoxShape.circle,
    );
    if (file == null && (url == null || url == ''))
      return Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor,
          shape: BoxShape.circle,
        ),
      );
    if (file != null)
      return Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
          shape: BoxShape.circle,
        ),
        foregroundDecoration: foregroundDecoration,
      );
    return Container(
      width: _size,
      height: _size,
      key: widgetKey,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFf0f1f2),
        shape: BoxShape.circle,
      ),
      foregroundDecoration: foregroundDecoration,
      child: ContainerImage(
        url,
        radius: radius,
        width: _size,
        height: _size,
        thumbHeight: 225,
        fit: BoxFit.cover,
        cacheManager: cacheManager,
      ),
    );
  }
}
