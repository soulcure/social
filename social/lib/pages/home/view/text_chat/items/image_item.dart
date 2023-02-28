import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/widgets/send_image/send_image_dialog.dart';
import 'package:im/widgets/image.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:path/path.dart' as p;

class ImageItem extends StatelessWidget {
  final MessageEntity message;
  final String quoteL1;
  final bool needRetry;
  static const sizeConstraint = 225.0;

  const ImageItem(this.message, {this.quoteL1, this.needRetry = false});

  @override
  Widget build(BuildContext context) {
    return Container(
        foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: CustomColor(context).backgroundColor1,
              width: 0.5,
            )),
        child: _buildImage(context));
  }

  Widget _buildImage(BuildContext context) {
    try {
      final data = message.content as ImageEntity;

      final size =
          getImageSize(data?.width?.toDouble(), data?.height?.toDouble());
      final width = size.item1?.toDouble(), height = size.item2?.toDouble();
      final fit = size.item3;
      if (OrientationUtil.landscape) {
        String url;
        if (data.localFilePath != null &&
            data.localFilePath.isNotEmpty &&
            pickFileCache.contains(data.localFilePath)) {
          url = data.localFilePath;
        } else if (data.url.startsWith("http")) {
          url = fetchCdnThumbUrl(data.url, 1.5 * sizeConstraint);
        } else {
          url = data.url;
        }
        return _getImage(context, width, height, fit, url: url);
      } else {
        if (_checkCanLoadLocalMedia(data)) {
          // 刚压缩上传完成（直接加载本地图片）
          return _getLocalMediaWidget(context, width, height, fit, data);
        } else if (data?.url?.isNotEmpty ?? false) {
          // 加载网络图片
          if (data.url.startsWith('http')) {
            // 正常的网络图片
            final url = fetchCdnThumbUrl(data.url, 1.5 * sizeConstraint);
            return _getImage(context, width, height, fit, url: url);
          } else if ((Global.deviceInfo?.thumbDir ?? "").isEmpty) {
            // 送审不通过的图片&并且thumbDir没初始化好,一般不会有这种情况.
            return _buildBackgroundWidget(width ?? 120, height ?? 225);
          } else {
            // 送审不通过的图片
            final oriUrl = data.url;
            final dir = Global.deviceInfo.thumbDir;
            final path = p.join(dir, oriUrl);
            data.asset ??= Asset('', path, '', 0, 0, '');
            return _getImage(context, width, height, fit, filePath: path);
          }
        } else if (_checkCanLoadPhotoAlbumMedia(data)) {
          // 正在压缩中(加载相册缩略图)
          return _getPhotoAlbumMediaWidget(context, width, height, fit, data);
        } else {
          return _buildBackgroundWidget(width ?? 120, height ?? 225);
        }
      }
    } catch (e, s) {
      logger.severe("图片加载出错:", e, s);
      return _buildBackgroundWidget(120, 225);
    }
  }

  Widget _buildBackgroundWidget(double width, double height,
      {Widget child = const SizedBox(),
      Color color = const Color.fromARGB(0xff, 0xf0, 0xf1, 0xf2)}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  bool _checkCanLoadPhotoAlbumMedia(ImageEntity data) {
    final identifier = data?.localIdentify ?? data?.asset?.identifier ?? "";
    final fileType = data?.fileType ?? data?.asset?.fileType ?? "";
    return identifier.hasValue && fileType.hasValue;
  }

  Widget _getPhotoAlbumMediaWidget(BuildContext context, double width,
      double height, BoxFit fit, ImageEntity data) {
    final identifier = data?.localIdentify ?? data?.asset?.identifier ?? "";
    final fileType = data?.fileType ?? data?.asset?.fileType ?? "";
    return FutureBuilder(
      future:
          MultiImagePicker.fetchMediaThumbData(identifier, fileType: fileType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return _getImage(context, width, height, fit,
              thumbData: snapshot.data, url: data.url);
        } else {
          return _buildBackgroundWidget(width, height);
        }
      },
    );
  }

  bool _checkCanLoadLocalMedia(ImageEntity data) {
    final filePath = data?.localFilePath ?? "";
    return filePath.isNotEmpty && File(filePath).existsSync();
  }

  Widget _getLocalMediaWidget(BuildContext context, double width, double height,
      BoxFit fit, ImageEntity data) {
    final filePath = data?.localFilePath ?? "";
    if (filePath.isNotEmpty && File(filePath).existsSync()) {
      return _getImage(context, width, height, fit,
          url: data.url, filePath: filePath);
    } else {
      return _buildBackgroundWidget(width, height);
    }
  }

  Widget _getImage(
    BuildContext context,
    double width,
    double height,
    BoxFit fit, {
    String url,
    Uint8List thumbData,
    String filePath,
  }) {
    try {
      Widget child;
      if (filePath.hasValue) {
        final devicePixelRatio = Get.pixelRatio;
        child = _getRectImage(
          width,
          height,
          fit,
          ResizeImage(
            FileImage(
              File(filePath),
            ),
            width: (width * devicePixelRatio).toInt(),
            height: (height * devicePixelRatio).toInt(),
          ),
        );
      } else if (thumbData != null) {
        child = _getRectImage(width, height, fit, MemoryImage(thumbData));
      } else if (url?.toLowerCase()?.endsWith("gif") ?? false) {
        child = NetworkImageWithPlaceholder(
          url,
          fit: fit,
          width: width,
          height: height,
          retryOriginUrl: needRetry ? url : null,
        );
      } else if (url.hasValue) {
        child = NetworkImageWithPlaceholder(url,
            fit: fit,
            width: width,
            height: height,
            retryOriginUrl: needRetry ? url : null,
            imageBuilder: (context, imageProvider) =>
                _getRectImage(width, height, fit, imageProvider));
      } else {
        child = _buildBackgroundWidget(width ?? 120, height ?? 225,
            child: const CircularProgressIndicator());
      }

      return _buildBackgroundWidget(width, height,
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            clipBehavior: Clip.hardEdge,
            child: child,
          ));
    } catch (e) {
      return const SizedBox();
    }
  }

  Widget _getRectImage(
      double width, double height, BoxFit fit, ImageProvider image) {
    return SizedBox(
      width: width,
      height: height,
      child: Image(image: image, fit: fit),
    );
  }
}
