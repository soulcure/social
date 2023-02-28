import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/embed_builder_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model_base.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/utils/utils.dart';

import '../model/editor_model_tun.dart';

class RichTunEditorEmbedBuilder extends EmbedBuilderBase {
  final Embed node;
  final RichTunEditorModel model;

  RichTunEditorEmbedBuilder(this.node, this.model);

  @override
  EmbedBuilderBase embedBuilder(Embed node, RichEditorModelBase model) {
    return RichTunEditorEmbedBuilder(node, model);
  }

  @override
  _RichTunEditorEmbedBuilderState createState() =>
      _RichTunEditorEmbedBuilderState();
}

class _RichTunEditorEmbedBuilderState extends State<RichTunEditorEmbedBuilder> {
  @override
  Widget build(BuildContext context) {
    return embedBuilder(context, widget.node);
  }
}

Widget embedBuilder(BuildContext context, Embed node) {
  final type = node.value.type;
  final data = node.value.data;
  Widget child;
  switch (type) {
    case 'image':
      child = _buildImage(context, data);
      break;
    case 'video':
      child = _buildVideo(context, data);
      break;
    case 'divider':
      child = const Divider(height: 10, thickness: 1, color: Color(0x4D8F959E));
      break;

    default:
      child = const SizedBox();
  }
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: child,
  );
}

// 富文本图片渲染器
Widget _buildImage(BuildContext context, Map json) {
  final source = json['source'];
  final imageSize = getImageSize(json['width'], json['height']);
  final width = imageSize.item1;
  final height = imageSize.item2;
  Widget child;
  if (source.startsWith('http')) {
    child = ImageWidget.fromCachedNet(CachedImageBuilder(
      cacheManager: CustomCacheManager.instance,
      imageUrl: source,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorWidget: (context, __, ___) => _errorWidget(context),
    ));
  } else {
    final filePath = '${Global.deviceInfo.thumbDir}$source';
    if (!File(filePath).existsSync()) {
      return _errorWidget(context);
    } else
      child = Image(
          image: ImageUtil().buildResizeProvider(
              context, FileImage(File(filePath)),
              imageHeight: height.toInt(), imageWidth: width.toInt()),
          fit: BoxFit.cover);
  }
  return Container(
    alignment: Alignment.centerLeft,
    width: width,
    height: height,
    child: child,
  );
}

Widget _buildVideo(BuildContext context, Map json) {
  final source = json['source'];
  final imageSize = getImageSize(json['width'], json['height']);
  final width = imageSize.item1;
  final height = imageSize.item2;
  final duration = json['duration'];
  String thumbUrl = json['thumbUrl'];
  if (!thumbUrl.startsWith('http')) {
    thumbUrl = '${Global.deviceInfo.thumbDir}$thumbUrl';
    if (!File(thumbUrl).existsSync()) {
      return _errorWidget(context);
    }
  }
  return Container(
    width: width,
    height: height,
    alignment: Alignment.centerLeft,
    child: Stack(
      children: [
        if (source.startsWith('http'))
          ImageWidget.fromCachedNet(CachedImageBuilder(
            cacheManager: CustomCacheManager.instance,
            imageUrl: thumbUrl,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorWidget: (context, __, ___) => _errorWidget(context),
          ))
        else
          Image(
              image: ImageUtil().buildResizeProvider(
                  context, FileImage(File(thumbUrl)),
                  imageHeight: height.toInt(), imageWidth: width.toInt()),
              fit: BoxFit.cover),
        Positioned(
          right: 5,
          bottom: 5,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color.fromRGBO(0, 0, 0, 0.4),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.videocam,
                  color: Colors.white,
                  size: 16,
                ),
                Text(
                  formatCountdownTime(duration),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
        )
      ],
    ),
  );
}

Widget _errorWidget(BuildContext context) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: CustomColor(context).disableColor.withOpacity(0.2),
    ),
    child: Icon(
      IconFont.buffCommonLost,
      size: 40,
      color: CustomColor(context).disableColor.withOpacity(0.5),
    ),
  );
}
