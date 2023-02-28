import 'dart:html';

// ignore: avoid_web_libraries_in_flutter
// import 'dart:html';

import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/image_picker/image_picker.dart';
import 'package:im/utils/utils.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

import '../ui_fake.dart' if (dart.library.html) 'dart:ui' as ui;

Future<Asset> showSendImageDialog(
    BuildContext context, FileInfo fileInfo) async {
  final fileBytes = await fileInfo.pickedFile.readAsBytes();
  const imageType =
      'bmp,jpeg,jpg,png,tif,tiff,gif,pcx,tga,exif,fpx,svg,psd,cdr,pcd,dxf,ufo,eps,ai,raw,WMF,webp';
  final extendType =
      fileInfo.fileName.substring(fileInfo.fileName.lastIndexOf('.') + 1);
  final isImage = imageType.contains(extendType);
  Image image;
  if (isImage) {
    image = Image.memory(fileBytes);
  }
  return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return SendImageDialog(
          image: image,
          fileInfo: fileInfo,
        );
      });
}

class SendImageDialog extends StatefulWidget {
  final Image image;
  final FileInfo fileInfo;

  const SendImageDialog({
    this.image,
    this.fileInfo,
  });
  @override
  _SendImageDialogState createState() => _SendImageDialogState();
}

class _SendImageDialogState extends State<SendImageDialog> {
  static int index = 0;
  VideoElement _videoElement;
  Widget _sourceWidget = const SizedBox();

  @override
  void initState() {
    if (widget.image != null) {
      _sourceWidget = widget.image;
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

      _sourceWidget = Stack(
        children: [
          HtmlElementView(viewType: 'sendImage-videoPlayer-$index'),
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
    }
    super.initState();
  }

  @override
  void dispose() {
    if (widget.image == null) {
      _videoElement?.removeAttribute('src');
      _videoElement?.load();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    return Center(
      child: Container(
        width: 420,
        height: 400,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), color: Colors.white),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.image != null ? '发送图片'.tr : '发送视频'.tr,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText2
                      .copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 80,
                ),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: FlatButton(
                      padding: const EdgeInsets.all(0),
                      onPressed: Get.back,
                      child: Icon(
                        IconFont.buffTabClose,
                        size: 16,
                        color: _theme.textTheme.bodyText1.color,
                      )),
                )
              ],
            ),
            Container(
              width: 372,
              height: 238,
              decoration: BoxDecoration(
                  border:
                      Border.all(color: Theme.of(context).dividerTheme.color)),
              child: Column(
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
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        .copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 28,
            ),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                SizedBox(
                  width: 100,
                  height: 32,
                  child: FlatButton(
                      onPressed: () async {
                        if (widget.image != null) {
                          final identifier = widget.fileInfo.pickedFile.path
                              .substring(widget.fileInfo.pickedFile.path
                                      .lastIndexOf('/') +
                                  1);
                          final imageInfo = await getImageInfo(
                              widget.fileInfo.pickedFile.path);
                          final asset = Asset(
                              identifier,
                              widget.fileInfo.pickedFile.path,
                              widget.fileInfo.fileName,
                              imageInfo.image.width * 1.0,
                              imageInfo.image.height * 1.0,
                              'image');
                          Navigator.of(context).pop(asset);
                        } else {
                          final identifier = widget.fileInfo.pickedFile.path
                              .substring(widget.fileInfo.pickedFile.path
                                      .lastIndexOf('/') +
                                  1);
                          final canvas = CanvasElement()
                            ..width = _videoElement.videoWidth
                            ..height = _videoElement.videoHeight;
                          canvas.context2D.drawImageToRect(
                              _videoElement,
                              Rectangle(0, 0, _videoElement.videoWidth,
                                  _videoElement.videoHeight));
                          final blob = await canvas.toBlob();
                          final thumbFilePath =
                              Url.createObjectUrlFromBlob(blob);
                          final thumbName = '$identifier.png';
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
                      },
                      padding: const EdgeInsets.all(0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _theme.primaryColor,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '发送'.tr,
                          style: _theme.textTheme.bodyText2
                              .copyWith(color: Colors.white),
                        ),
                      )),
                ),
                sizeWidth16,
                SizedBox(
                  width: 100,
                  height: 32,
                  child: FlatButton(
                      onPressed: Get.back,
                      padding: const EdgeInsets.all(0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Theme.of(context).dividerTheme.color),
                          color: _theme.backgroundColor,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '取消'.tr,
                          style: _theme.textTheme.bodyText2,
                        ),
                      )),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
