// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/utils/confirm_dialog/confirm_dialog.dart';
import 'package:im/web/utils/image_picker/image_picker.dart';
import 'package:im/web/utils/web_toast.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

import '../ui_fake.dart' if (dart.library.html) 'dart:ui' as ui;
import 'send_image_dialog.dart';

Future<Asset> showSendImageDialog(
    BuildContext context, FileInfo fileInfo) async {
  const imageType =
      'bmp,jpeg,jpg,png,tif,tiff,gif,pcx,tga,exif,fpx,svg,psd,cdr,pcd,dxf,ufo,eps,ai,raw,WMF,webp,'
      'BMP,JPEG,JPG,PNG,TIF,TIFF,GIF,PCX,TGA,EXIF,FPX,SVG,PSD,CDR,PCD,DXF,UFO,EPS,AI,RAW,WMF,WEBP';
  final extendType =
      fileInfo.fileName.substring(fileInfo.fileName.lastIndexOf('.') + 1);
  final isImage = imageType.contains(extendType);
  if (isImage && fileInfo.size > 8 * 1024 * 1024) {
    showWebToast('发送图片不能超过8M\n如果需要发送更大的视频图片，请下载App');
    return null;
  } else if (!isImage && fileInfo.size > 8 * 1024 * 1024) {
    showWebToast('发送视频不能超过8M\n如果需要发送更大的视频图片，请下载App');
    return null;
  }
  final fileBytes = await fileInfo.pickedFile.readAsBytes();
  webSendImageCache[fileInfo.fileName] = fileBytes;
  return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return SendImageDialog(
          isImage: isImage,
          fileInfo: fileInfo,
          isGif: extendType == 'gif',
        );
      });
}

class SendImageDialog extends StatefulWidget {
  final bool isImage;
  final bool isGif;
  final FileInfo fileInfo;

  const SendImageDialog({
    this.isImage,
    this.fileInfo,
    this.isGif,
  });
  @override
  _SendImageDialogState createState() => _SendImageDialogState();
}

class _SendImageDialogState extends State<SendImageDialog> {
  static int index = 0;
  VideoElement _videoElement;
  ImageElement _imageElement;

  Widget _sourceWidget = const SizedBox();
  bool _sendBtnEnable = true;

  @override
  void initState() {
    if (widget.isImage) {
      _imageElement = ImageElement()
        ..src = widget.fileInfo.pickedFile.path
        ..width = 10
        ..height = 10;
      index++;
      ui.platformViewRegistry.registerViewFactory(
          'sendImage-videoPlayer-$index', (viewId) => _imageElement);
    } else {
      _videoElement = VideoElement()
        ..src = widget.fileInfo.pickedFile.path
        ..autoplay = false
        ..controls = false
        ..style.border = 'none';

      // Allows Safari iOS to play the video inline
      _videoElement.setAttribute('playsinline', 'true');

      index++;
      ui.platformViewRegistry.registerViewFactory(
          'sendImage-videoPlayer-$index', (viewId) => _videoElement);
    }

    _sourceWidget = Stack(
      children: [
        HtmlElementView(viewType: 'sendImage-videoPlayer-$index'),
        if (widget.isImage)
          Container(
            alignment: Alignment.center,
            color: Colors.white,
            child: Image.network(widget.fileInfo.pickedFile.path),
          ),
        if (!widget.isImage)
          Center(
              child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                gradient: const RadialGradient(
                  colors: [Color(0x40000000), Color(0x00000000)],
                ),
                borderRadius: BorderRadius.circular(42)),
            padding: const EdgeInsets.only(left: 6),
            child: const Icon(
              IconFont.buffAudioVisualPlay,
              color: Colors.white,
              size: 18,
            ),
          )),
      ],
    );

    super.initState();
  }

  @override
  void dispose() {
    if (widget.isImage == null) {
      _imageElement?.removeAttribute('src');
    } else {
      _videoElement?.removeAttribute('src');
      _videoElement?.load();
    }
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (!_sendBtnEnable) return;
    _sendBtnEnable = false;
    if (widget.isImage) {
      final bytes = webSendImageCache[widget.fileInfo.fileName];
      final imageSize = await getImageInfoByProvider(MemoryImage(bytes));
      String filePath = widget.fileInfo.pickedFile.path;
      if (!widget.isGif) {
        /// 压缩图片
        final canvas = CanvasElement()
          ..width = imageSize.image.width
          ..height = imageSize.image.height;
        canvas.context2D.drawImageToRect(_imageElement,
            Rectangle(0, 0, imageSize.image.width, imageSize.image.height));
        final base64 = await canvas.toDataUrl('image/jpeg', 0.6);
        final size = base64Decode(base64.substring(23));
        final Blob blob = Blob([size], 'image/jpeg');
        filePath = Url.createObjectUrlFromBlob(blob);
        webSendImageCache[widget.fileInfo.fileName] = size;

        /// 审核
        final checkBase64 = await canvas.toDataUrl('image/jpeg', 0.1);
        final checkSize = base64Decode(checkBase64.substring(23));
        checkImageCache[widget.fileInfo.fileName] = checkSize;
      } else {
        final canvas = CanvasElement()
          ..width = imageSize.image.width
          ..height = imageSize.image.height;
        canvas.context2D.drawImageToRect(_imageElement,
            Rectangle(0, 0, imageSize.image.width, imageSize.image.height));
        final base64 = await canvas.toDataUrl('image/jpeg', 0.1);
        final checkSize = base64Decode(base64.substring(23));
        checkImageCache[widget.fileInfo.fileName] = checkSize;
      }

      /// 发送
      final identifier = widget.fileInfo.pickedFile.path
          .substring(widget.fileInfo.pickedFile.path.lastIndexOf('/') + 1);
      pickFileCache.add(filePath);
      final asset = Asset(
          identifier,
          filePath,
          widget.fileInfo.fileName,
          imageSize.image.width.toDouble(),
          imageSize.image.height.toDouble(),
          'image');
      Navigator.of(context).pop(asset);
    } else {
      final identifier = widget.fileInfo.pickedFile.path
          .substring(widget.fileInfo.pickedFile.path.lastIndexOf('/') + 1);
      final canvas = CanvasElement()
        ..width = _videoElement.videoWidth
        ..height = _videoElement.videoHeight;
      canvas.context2D.drawImageToRect(_videoElement,
          Rectangle(0, 0, _videoElement.videoWidth, _videoElement.videoHeight));
      final blob = await canvas.toBlob();
      final thumbFilePath = Url.createObjectUrlFromBlob(blob);
      final thumbName = '$identifier.png';
      pickFileCache.add(thumbFilePath);
      final asset = Asset(
        identifier,
        widget.fileInfo.pickedFile.path,
        widget.fileInfo.fileName,
        _videoElement.videoWidth * 1.0,
        _videoElement.videoHeight * 1.0,
        'video',
        duration: _videoElement.duration,
        thumbFilePath: thumbFilePath,
        thumbName: thumbName,
        thumbHeight: _videoElement.videoHeight * 1.0,
        thumbWidth: _videoElement.videoWidth * 1.0,
      );
      Navigator.of(context).pop(asset);
    }
    _sendBtnEnable = true;
  }

  void _onCancel() {
    webSendImageCache[widget.fileInfo.fileName] = null;
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    return Center(
      child: WebConfirmDialog2(
        title: widget.isImage ? '发送图片'.tr : '发送视频'.tr,
        showCloseIcon: true,
        width: 450,
        body: Column(
          children: [
            sizeHeight24,
            SizedBox(
              width: 240,
              height: 140,
              child: _sourceWidget,
            ),
            const SizedBox(
              height: 14,
            ),
            Text(
              widget.fileInfo.fileName,
              style: Theme.of(context).textTheme.bodyText2,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            sizeHeight6,
            Text(
              filesize(widget.fileInfo.size),
              style:
                  Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 12),
            ),
            sizeHeight24,
          ],
        ),
        onConfirm: _onConfirm,
        onCancel: _onCancel,
      ),
    );
  }
}
