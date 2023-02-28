import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/view/text_chat/items/image_item.dart';
import 'package:im/pages/home/view/text_chat/items/video_item_web.dart';
import 'package:im/utils/cos_file_cache_index.dart';
import 'package:im/utils/utils.dart';
import 'package:tun_editor/models/documents/nodes/embed.dart';

import '../message_extension.dart';

class GalleryItem {
  final String id;
  final String resource;
  final String filePath;
  final String url;
  final String holderUrl;
  final double thumbWidth;
  final double thumbHeight;
  final String identifier;
  final bool isImage;
  final MessageEntity message;
  final bool isInView; // 是否显示在页面中，来判断是否需要显示hero动画

  GalleryItem({
    this.id,
    this.resource,
    this.filePath,
    this.url,
    this.holderUrl,
    this.thumbWidth,
    this.thumbHeight,
    this.identifier,
    this.isImage = true,
    this.message,
    this.isInView = true,
  });

  static List<GalleryItem> initWith(MessageEntity msg, {String quoteL1}) {
    if (msg.content.runtimeType == ImageEntity) {
      final image = msg.content as ImageEntity;
      String filePath = image?.asset?.filePath ?? image?.localFilePath ?? "";
      filePath = File(filePath).existsSync()
          ? filePath
          : CosUploadFileIndexCache.cachePath(image.url) ?? '';
      final identify = image?.asset?.identifier ?? image?.localIdentify ?? "";
      return [
        GalleryItem(
            id: quoteL1 != null ? 'Topic_${msg.heroTag}' : msg.heroTag,
            url: image.url ?? '',
            identifier: identify,
            holderUrl:
                fetchCdnThumbUrl(image.url, 1.5 * ImageItem.sizeConstraint),
            // ignore: avoid_redundant_argument_values
            filePath: kIsWeb ? null : filePath,
            message: msg)
      ];
    } else if (msg.content.runtimeType == VideoEntity) {
      final video = msg.content as VideoEntity;
      if (video.url.noValue) return [];
      final filePath = CosUploadFileIndexCache.cachePath(video.url);
      return [
        GalleryItem(
            id: quoteL1 != null ? 'Topic_${msg.heroTag}' : msg.heroTag,
            url: video.url,
            // ignore: avoid_redundant_argument_values
            filePath: kIsWeb ? null : filePath,
            isImage: false,
            identifier: video?.asset?.identifier ?? video.localIdentify,
            holderUrl: fetchCdnThumbUrl(
                video.thumbUrl, 1.5 * VideoItem.sizeConstraint),
            thumbWidth: video.thumbWidth * 1.0,
            thumbHeight: video.thumbHeight * 1.0,
            message: msg)
      ];
    } else if (msg.content.runtimeType == RichTextEntity) {
      final content = msg.content as RichTextEntity;
      return content.document.toDelta().toList().fold([], (previousValue, o) {
        if (o.isEmbed) {
          final media = Embeddable.fromJson(o.value);
          if (media is ImageEmbed) {
            final url = media.source;
            return [
              ...previousValue,
              GalleryItem(
                  id: quoteL1 != null ? 'Topic_${msg.heroTag}' : msg.heroTag,
                  url: url ?? '',
                  holderUrl:
                      fetchCdnThumbUrl(url, 1.5 * ImageItem.sizeConstraint),
                  message: msg)
            ];
          } else if (media is VideoEmbed) {
            final url = media.source;
            final thumbUrl = media.thumbUrl;
            final width = double.tryParse(media.width.toString()) ?? 0;
            final height = double.tryParse(media.height.toString()) ?? 0;
            return [
              ...previousValue,
              GalleryItem(
                  id: quoteL1 != null ? 'Topic_${msg.heroTag}' : msg.heroTag,
                  url: url ?? '',
                  holderUrl: fetchCdnThumbUrl(
                      thumbUrl, 1.5 * VideoItem.sizeConstraint),
                  isImage: false,
                  thumbWidth: width,
                  thumbHeight: height,
                  message: msg)
            ];
          } else {
            return previousValue;
          }
        }
        return previousValue;
      });
    } else {
      return [];
    }
  }
}
