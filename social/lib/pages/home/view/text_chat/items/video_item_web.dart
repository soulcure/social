import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/widgets/send_image/send_image_dialog.dart';
import 'package:im/web/widgets/web_video_player/web_video_player.dart';
import 'package:im/widgets/cache_widget.dart';

class VideoItem extends StatelessWidget {
  final MessageEntity message;
  static const sizeConstraint = 225.0;
  final String quoteL1;
  const VideoItem(this.message, {this.quoteL1});

  @override
  Widget build(BuildContext context) {
    final data = message.content as VideoEntity;
    var url = data.thumbUrl.startsWith("http")
        ? fetchCdnThumbUrl(data.thumbUrl, 2 * sizeConstraint)
        : data.thumbUrl;

    if (pickFileCache.contains(data.localThumbPath)) {
      url = data.localThumbPath;
    }

    double width, height;
    width = data.thumbWidth > 0
        ? data.thumbWidth.toDouble()
        : data.width.toDouble();
    height = data.thumbHeight > 0
        ? data.thumbHeight.toDouble()
        : data.height.toDouble();

    final size = getImageSize(width, height,
        defaultFit: BoxFit.cover, maxSizeConstraint: 400);
    final duration = data.duration == null ? 0 : data.duration?.toInt();
    return SizedBox(
      width: max(size.item1, 210),
      height: size.item2,
      child: CacheWidget(
        cacheKey: data.url,
        builder: () => WebVideoPlayer(
          videoUrl: data.url ?? data.localPath,
          thumbUrl: url,
          duration: duration,
          messageId: message.messageId,
          quoteL1: quoteL1,
          padding: size.item1 < 210 ? (210 - size.item1) / 2 : 0,
        ),
      ),
    );
  }
}
