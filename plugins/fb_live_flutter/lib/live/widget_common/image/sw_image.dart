import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/material.dart';

import '../../utils/func/utils_class.dart';

class SwImage extends StatelessWidget {
  final String? image;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit? fit;
  final String? package;
  final BorderRadius? borderRadius;
  final ClickEventCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const SwImage(
    this.image, {
    this.width,
    this.height,
    this.color,
    this.fit,
    this.package,
    this.borderRadius,
    this.onTap,
    this.margin,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    try {
      if (!strNoEmpty(image)) {
        imageWidget = const DefImageView();
      } else if (isNetWorkImg(image!)) {
        imageWidget = CachedNetworkImage(
          imageUrl: image!,
          width: width,
          height: height,
          fit: fit,
          color: color,
          placeholder: (context, url) {
            return const DefImageView();
          },
          errorWidget: (context, url, error) {
            return const DefImageView();
          },
        );
      } else if (isAssetsImg(image!)) {
        imageWidget = Image.asset(
          image!,
          width: width,
          height: height,
          fit: fit,
          package: package,
          color: color,
        );
      } else if (File(image!).existsSync()) {
        imageWidget = Image.file(
          File(image!),
          width: width,
          height: height,
          fit: fit,
          color: color,
        );
      } else if (!strNoEmpty(image)) {
        imageWidget = const DefImageView();
      } else {
        imageWidget = Image.memory(
          image!.codeUnits as Uint8List,
          width: width,
          height: height,
          fit: fit,
          color: color,
        );
      }
    } catch (e) {
      imageWidget = const DefImageView();
    }
    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius, child: imageWidget);
    }
    if (onTap != null) {
      imageWidget = ClickEvent(
        onTap: onTap,
        child: imageWidget,
      );
    }
    if (margin != null) {
      imageWidget = Container(margin: margin, child: imageWidget);
    }

    return imageWidget;
  }
}

ImageProvider swImageProvider(String? image) {
  ImageProvider imageProvider;

  if (!strNoEmpty(image)) {
    imageProvider = fbApi.getFanbookIcon();
  } else if (isNetWorkImg(image!)) {
    imageProvider = CachedNetworkImageProvider(image);
  } else if (isAssetsImg(image)) {
    imageProvider = AssetImage(image);
  } else if (File(image).existsSync()) {
    imageProvider = FileImage(File(image));
  } else {
    imageProvider = MemoryImage(image.codeUnits as Uint8List);
  }
  return imageProvider;
}

/// 同步改一下[11.6]
class DefImageView extends StatelessWidget {
  final double? width;
  final double? height;

  const DefImageView({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xffe1dfe1),
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: const Text(
        '',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
