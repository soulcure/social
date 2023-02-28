import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;

import 'package:http/http.dart' as http show readBytes;
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/embed_builder_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/upload_progress.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model_base.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/cos_file_upload.dart';
import 'package:im/utils/utils.dart';

import '../model/editor_model.dart';

class RichEditorEmbedBuilder extends EmbedBuilderBase {
  final Embed node;
  final RichEditorModel model;
  RichEditorEmbedBuilder(this.node, this.model);

  @override
  EmbedBuilderBase embedBuilder(Embed node, RichEditorModelBase model) {
    return RichEditorEmbedBuilder(node, model);
  }

  @override
  _RichEditorEmbedBuilderState createState() => _RichEditorEmbedBuilderState();
}

class _RichEditorEmbedBuilderState extends State<RichEditorEmbedBuilder> {
  Future<List<String>> uploadFuture;
  @override
  void initState() {
    final type = widget.node.value.type;
    setState(() {
      if (type == 'image') {
        uploadFuture = _getImageFuture();
      } else if (type == 'video') {
        uploadFuture = _getVideoFuture();
      }
      uploadFuture?.then((urls) {
        final source = widget.node.value.data['source'];
        widget.model.addUploadCache(source, urls);
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return embedBuilder(context, widget.node);
  }

  Future<List<String>> _getImageFuture() async {
    final source = widget.node.value.data['source'];
    final filename = widget.node.value.data['name'];
    final bytes = await http.readBytes(Uri.parse(source));

    final passed = await CheckUtil.startCheck(
      ImageCheckItem.fromBytes(
        [U8ListWithPath(bytes, '')],
        ImageChannelType.FB_CIRCLE_POST_PIC,
        checkType: CheckType.circle,
      ),
    );
    if (!passed) {
      return ['$source reject'];
    }
    // final res = await uploadFileIfNotExist(
    //     bytes: bytes, filename: filename, onSendProgress: (count, total) {});
    final res = await CosFileUploadQueue.instance
        .onceForBytes(bytes, CosUploadFileType.unKnow, fileName: filename);
    return [res];
  }

  Future<List<String>> _getVideoFuture() async {
    final source = widget.node.value.data['source'];
    final thumbUrl = widget.node.value.data['thumbUrl'];
    final filename = widget.node.value.data['name'];
    final thumbName = widget.node.value.data['thumbName'];

    final thumbUrlBytes = await http.readBytes(Uri.parse(thumbUrl));
    final passed = await CheckUtil.startCheck(
      ImageCheckItem.fromBytes(
        [U8ListWithPath(thumbUrlBytes, '')],
        ImageChannelType.FB_CIRCLE_POST_PIC,
        checkType: CheckType.circle,
      ),
    );
    if (!passed) {
      return ['$thumbUrl reject'];
    }

    // final futures = [
    //   uploadFileIfNotExist(
    //       bytes: await http.readBytes(Uri.parse(source)),
    //       filename: filename,
    //       onSendProgress: (count, total) {}),
    //   uploadFileIfNotExist(
    //       bytes: thumbUrlBytes,
    //       filename: thumbName,
    //       onSendProgress: (count, total) {}),
    // ];
    final futures = [
      CosFileUploadQueue.instance.onceForBytes(
          await http.readBytes(Uri.parse(source)), CosUploadFileType.unKnow,
          fileName: filename),
      CosFileUploadQueue.instance.onceForBytes(
          thumbUrlBytes, CosUploadFileType.unKnow,
          fileName: thumbName),
    ];
    return Future.wait(futures);
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
        child =
            const Divider(height: 10, thickness: 1, color: Color(0x4D8F959E));
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
    return Container(
      width: width,
      height: height,
      alignment: Alignment.centerLeft,
      child: UploadProgress(
        future: uploadFuture,
        width: width,
        builder: (context) => Image.network(
          source,
          width: width,
          height: height,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildVideo(BuildContext context, Map json) {
    final imageSize = getImageSize(json['width'], json['height']);
    final width = imageSize.item1;
    final height = imageSize.item2;
    final duration = json['duration'];
    String thumbUrl = json['thumbUrl'];
    if (!thumbUrl.startsWith('http') && !thumbUrl.startsWith('blob')) {
      thumbUrl = '${Global.deviceInfo.thumbDir}$thumbUrl';
      if (!File(thumbUrl).existsSync()) {
        return _errorWidget(context);
      }
    }
    return Container(
      width: width,
      height: height,
      alignment: Alignment.centerLeft,
      child: UploadProgress(
          future: uploadFuture,
          width: width,
          builder: (context) {
            return Stack(
              children: [
                if (thumbUrl.startsWith('http') || thumbUrl.startsWith('blob'))
                  Image.network(
                    thumbUrl,
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                  )
                else
                  Image.file(
                    File(thumbUrl),
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                  ),
                Positioned(
                  right: 5,
                  bottom: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color.fromRGBO(0, 0, 0, 0.4),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.videocam,
                          color: Colors.white,
                          size: 16,
                        ),
                        Text(
                          formatCountdownTime(duration),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            );
          }),
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
}
