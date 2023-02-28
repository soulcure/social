import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/video_play_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

class VideoItem extends StatelessWidget {
  final MessageEntity message;
  static const sizeConstraint = 225.0;
  final String quoteL1;

  const VideoItem(this.message, {this.quoteL1});

  @override
  Widget build(BuildContext context) {
    final data = message.content as VideoEntity;

    final url = data.thumbUrl.startsWith("http")
        ? fetchCdnThumbUrl(data.thumbUrl, 1.5 * sizeConstraint)
        : data.thumbUrl;

    double width, height;
    width = data.thumbWidth > 0
        ? data.thumbWidth.toDouble()
        : data.width.toDouble();
    height = data.thumbHeight > 0
        ? data.thumbHeight.toDouble()
        : data.height.toDouble();

    return _getBody(
        url, width > 0 ? width : 125, height > 0 ? height : 225, context, data,
        videoUrl: data.url);
  }

  Widget _getBody(String url, double width, double height, BuildContext context,
      VideoEntity data,
      {String videoUrl}) {
    final size = getImageSize(width, height, defaultFit: BoxFit.cover);
    final duration = data.duration == null ? 0 : data.duration?.toInt();
    return SizedBox(
      width: size.item1,
      height: size.item2,
      child: VideoWidget(
        borderRadius: 4,
        duration: duration,
        url: videoUrl,
        child: _getVideo(context, url, size.item1, size.item2, size.item3),
      ),
    );
  }

  Widget _getVideo(BuildContext context, String url, double width,
      double height, BoxFit fit) {
    final data = message.content as VideoEntity;
    ImageProvider image;
    Widget child;
    if (url == null || url.isEmpty) {
      final identify = data.asset?.identifier ?? data.localIdentify ?? "";
      final fileType = data.asset?.fileType ?? data.fileType ?? "";
      if (MultiImagePicker.containCacheData(identify)) {
        final thumbData = MultiImagePicker.fetchCacheThumbData(identify);
        image = MemoryImage(thumbData);
        child = _getRectImage(width, height, fit, image);
      } else {
        child = FutureBuilder(
          future: MultiImagePicker.fetchMediaThumbData(identify,
              fileType: fileType),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              final image = MemoryImage(snapshot.data);
              return _getRectImage(width, height, fit, image);
            } else {
              return SizedBox(width: width, height: height);
            }
          },
        );
      }
    } else if (url.startsWith("http")) {
      image =
          CachedProviderBuilder(url, cacheManager: CustomCacheManager.instance)
              .provider;
      child = _getRectImage(width, height, fit, image);
    } else if (url.startsWith("blob:http")) {
      child = FutureBuilder(
        future: PickedFile(url).readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            final image = MemoryImage(snapshot.data);
            return _getRectImage(width, height, fit, image);
          } else {
            return SizedBox(width: width, height: height);
          }
        },
      );
    } else {
      image = FileImage(File(url));
      child = _getRectImage(width, height, fit, image);
    }

    return child;
  }

  Widget _getRectImage(
      double width, double height, BoxFit fit, ImageProvider image) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        image: DecorationImage(image: image, fit: fit),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
