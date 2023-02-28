import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart' as buff_permission;
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/show_circle_reply_popup.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/gallery/gallery.dart';
import 'package:im/pages/home/view/gallery/photo_view.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_io.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/editor/editor_tun.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/factory/abstract_rich_text_factory.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model_tun.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/widgets/web_video_player/web_video_player.dart';
import 'package:im/widgets/custom/custom_page_route_builder.dart';
import 'package:im/widgets/dialog/show_web_image_dialog.dart';
import 'package:im/widgets/round_image.dart';
import 'package:im/widgets/video_play_button.dart';
import 'package:oktoast/oktoast.dart';
import 'package:tun_editor/tun_editor_toolbar.dart';
import 'package:tuple/tuple.dart';

import 'circle_reply_cache.dart';

// const double _pagePadding = 18;

Future showPortraitCircleReplyPopup(BuildContext context,
    {@required String guildId,
    @required String channelId,
    MessageEntity reply,
    String hintText = '说点什么...',
    String commentId,
    OnReplySend onReplySend}) {
  return Get.to(
    CircleReplyPage(
      guildId: guildId,
      channelId: channelId,
      commentId: commentId,
      reply: reply,
      hintText: hintText,
      onReplySend: onReplySend,
    ),
    preventDuplicates: false,
    fullscreenDialog: true,
  );
}

class CircleReplyPage extends StatefulWidget {
  final String guildId;
  final String channelId;
  final String hintText;
  final OnReplySend onReplySend;
  final String commentId;

  // 是否是回复某条消息
  final MessageEntity reply;

  // final bool isClosed;
  const CircleReplyPage({
    this.guildId,
    this.channelId,
    this.reply,
    this.hintText,
    this.onReplySend,
    this.commentId,
  });

  @override
  CircleReplyPageState createState() => CircleReplyPageState();
}

class CircleReplyPageState extends State<CircleReplyPage> {
  bool _canAt = false;
  bool _needSaveDocInMem = true;
  RichTunEditorModel _model;

  @override
  void initState() {
    super.initState();
    if (TextChannelController.dmChannel != null &&
        TextChannelController.dmChannel.type == ChatChannelType.dm) {
      _canAt = false;
    } else {
      final guildPermission = PermissionModel.getPermission(
          ChatTargetsModel.instance.selectedChatTarget.id);
      final hasAtPermission = PermissionUtils.oneOf(
          guildPermission, [buff_permission.Permission.MENTION_EVERYONE],
          channelId: GlobalState.selectedChannel.value?.id);
      _canAt = hasAtPermission;
    }
    _loadDocument().then((map) {
      setState(() {
        _model = RichTunEditorModel(
          channel: ChatChannel(
            guildId: widget.guildId,
            id: widget.channelId,
            type: ChatChannelType.guildCircle,
          ),
          needTitle: false,
          editorPlaceholder: '写点什么...'.tr,
          defaultDoc: map['document'],
          defaultTitle: map['title'],
          toolbarItems: [
            ToolbarMenu.emoji,
            ToolbarMenu.at,
          ],
          onSend: () => _sendDoc(context),
        );
        _model.editorController.document.changes.listen((event) {
          if (event.item3 == ChangeSource.REMOTE) return;
          final changeList = event.item2.toList();
          if (changeList.any((element) => element.isInsert)) {
            onInsert(event);
          }
        });
        Get.put(_model);
      });
    });
  }

  void onInsert(Tuple3<Delta, Delta, ChangeSource> event) {
    final changeList = event.item2.toList();
    final o = changeList.firstWhere((element) => element.isInsert,
        orElse: () => null);
    if (o?.value == '@') {
      if (!_canAt) return;
      delay(() {
        _model.editorFocusNode.unfocus();
        toolbarCallback.showAtList(context, _model, fromInput: true);
      }, 200);
    }
  }

  @override
  void dispose() {
    if (_needSaveDocInMem)
      CircleReplyCache().putCache(
          widget.commentId, _model.editorController.document.encode());
    _model.dispose();
    Get.delete<RichTunEditorModel>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_model == null) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTitle(),
            Expanded(child: RichTunEditor(_model)),
            if (OrientationUtil.portrait)
              AbstractRichTextFactory.instance
                  .createEditorToolbar(context, _model),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Container(
          height: 38,
          padding: const EdgeInsets.fromLTRB(0, 17, 17, 0),
          alignment: Alignment.bottomRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 24,
              maxWidth: 24,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(IconFont.buffChatTextShrink,
                  size: 18, color: CustomColor(context).disableColor),
              onPressed: () {
                Routes.pop(context);
              },
            ),
          )),
    );
  }

  Widget _buildTitle() {
    final theme = Theme.of(context);
    // final color1 = theme.scaffoldBackgroundColor;
    final color2 = theme.textTheme.bodyText1.color;
    final hintText = widget.hintText;
    if (widget.hintText?.isNotEmpty ?? false)
      return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            hintText,
            style: TextStyle(color: color2, fontSize: 14),
          ));
    return sizeHeight16;
  }

  Future<Map> _loadDocument() async {
    final memCacheDoc = CircleReplyCache().readCache(widget.commentId);
    Document document;
    try {
      document = Document.fromJson(jsonDecode(memCacheDoc));
    } catch (e) {
      document = RichEditorUtils.defaultDoc;
    }
    return {
      'document': document,
    };
  }

  Future<void> _sendDoc(BuildContext context) async {
    try {
      final _controller = _model.editorController;
      final deltaList = _controller.document.toDelta().toList();
      final str = _controller.document
          .toPlainText()
          .replaceAll(RegExp(r"\n+| |\u200B"), '');
      if (deltaList.where((element) => element.isEmbed).length > 20) {
        showToast('图片和视频一次最多只能发送20个'.tr);
        return;
      }
      if (str.runes.length > 5000) {
        showToast('内容长度超出限制'.tr);
        return;
      }
      Loading.show(context);
      FocusScope.of(context).unfocus();
      // await RichEditorUtils.uploadFileInDoc(_controller.document);
      // printDoc();
      final passed = await CheckUtil.startCheck(TextCheckItem(
          str, TextChannelType.FB_CIRCLE_POST_COMMENT,
          checkType: CheckType.circle));
      if (!passed) return;

      widget.onReplySend?.call(_controller.document);
      CircleReplyCache().removeCache(widget.commentId);
      _needSaveDocInMem = false;
      Routes.pop(context, true);
    } catch (e) {
      _needSaveDocInMem = true;
      logger.severe('富文本发送失败', e);
    } finally {
      Loading.hide();
    }
  }
}

Widget buildRichText(
  String content,
  BuildContext context, {
  TextStyle style,
  EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(0, 0, 0, 16),
  String guildId,
}) {
  final document = Document.fromJson(jsonDecode(content));
  final list = document.toDelta().toList();
  return buildRichWithList(list, context,
      style: style, padding: padding, guildId: guildId);
}

// TextSpan buildRichTextSpan(String content, BuildContext context,
//     {TextStyle style,
//     List<String> imageList,
//     int maxLines,
//     TextOverflow textOverflow}) {
//   final document = Document.fromJson(jsonDecode(content));
//   final list = document.toDelta().toList();
//   return buildRichSpanWithList(list, context,
//       style: style, maxLines: maxLines, textOverflow: textOverflow);
// }

Widget buildRichWithList(
  List<Operation> list,
  BuildContext context, {
  TextStyle style,
  List<IndexMedia> imageList,
  int maxLines,
  EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(0, 0, 0, 16),
  String guildId,
}) {
  String content = '';
  for (final e in list) {
    if (e.isMedia) break;
    if (e.key == Operation.insertKey && e.value is Map) {
      final embed = Embeddable.fromJson(e.value);
      if (embed.data is Map && embed.data['value'] is String) {
        content += embed.data['id'] ?? '';
      }
    } else {
      if (e.data is String) {
        content += e.data;
      }
    }
  }
  content = '${content.trim()}$nullChar';
  if (OrientationUtil.landscape) style = style.copyWith(height: 1);
  return ParsedText(
    strutStyle: const StrutStyle(height: 1),
    style: style ??
        Theme.of(context).textTheme.bodyText2.copyWith(
              height: 1.25,
              fontSize: OrientationUtil.portrait ? 17 : 14,
            ),
    text: content,
    maxLines: maxLines,
    parse: getParseList(context, style: style, guildId: guildId),
  );
}

TextSpan buildRichSpanWithList(List<Operation> list, BuildContext context,
    {TextStyle style, int maxLines, TextOverflow textOverflow}) {
  return TextSpan(
      children: List.generate(list.length, (index) {
    final cur = list[index];
    return WidgetSpan(
        child: _buildDeltaItem(cur, context,
            style: style,
            maxLines: maxLines,
            textOverflow: textOverflow,
            index: index),
        alignment: PlaceholderAlignment.middle);
  }));
}

List<MatchText> getParseList(BuildContext context,
        {TextStyle style, String guildId}) =>
    [
      ParsedTextExtension.matchCusEmoText(context, style.fontSize),
      ParsedTextExtension.matchURLText(context),
      ParsedTextExtension.matchChannelLink(context),
      ParsedTextExtension.matchAtText(context,
          textStyle: style, guildId: guildId),
    ];

Widget _buildDeltaItem(Operation o, BuildContext context,
    {TextStyle style,
    List<IndexMedia> imageList,
    int maxLines,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(0, 0, 0, 16),
    TextOverflow textOverflow,
    int index = 0}) {
  final theme = Theme.of(context);
  Widget child = sizedBox;
  if (o.key != Operation.insertKey) return child;

  if (!o.isEmbed) {
    String value = o.value as String;
    while (value.startsWith('\n')) {
      try {
        value = value.substring(1, value.length);
      } catch (e) {
        logger.severe('富文本字符截取错误');
      }
    }
    while (value.endsWith('\n')) {
      try {
        value = value.substring(0, value.length - 1);
      } catch (e) {
        logger.severe('富文本字符截取错误');
      }
    }
    child = value.isEmpty
        ? sizedBox
        : ParsedText(
            style: style ??
                Theme.of(context).textTheme.bodyText2.copyWith(
                      height: 1.25,
                      fontSize: OrientationUtil.portrait ? 17 : 14,
                    ),

            /// 加上一个不可打印字符，否则如果只有 emoji 字符的 Text，底部会被截掉一部分
            text: '$value$nullChar',
            parse: getParseList(context, style: style),
            maxLines: maxLines,
            overflow: textOverflow ?? TextOverflow.clip,
          );
    child = Container(
      padding: padding,
      child: child,
    );
  } else if (o.isImage) {
    final url = RichEditorUtils.getEmbedAttribute(o, 'source');
    final w = RichEditorUtils.getEmbedAttribute(o, 'width')?.toDouble();
    final h = RichEditorUtils.getEmbedAttribute(o, 'height')?.toDouble();
    final realSize = getImageSize(w, h, maxSizeConstraint: 400);
    if (OrientationUtil.landscape)
      child = GestureDetector(
        onTap: () => showWebImageDialog(context, url: url, width: w, height: h),
        child: Container(
          width: double.infinity,
          height: realSize.item2,
          margin: const EdgeInsets.fromLTRB(0, 5, 0, 5),
          alignment: Alignment.centerLeft,
          child: Container(
            width: realSize.item1,
            height: realSize.item2,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: CustomColor(context).backgroundColor1,
                )),
            child: ImageWidget.fromCachedNet(CachedImageBuilder(
              imageUrl: url,
              placeholder: (ctx, image) => Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: theme.scaffoldBackgroundColor,
                  child: const Center(
                    child: CupertinoActivityIndicator(),
                  )),
              cacheManager: CircleCachedManager.instance,
            )),
          ),
        ),
      );
    else
      child = GestureDetector(
        onTap: () {
          int index = 0;

          for (final image in imageList) {
            if (image.url == url) {
              index = image.index;
              break;
            }
          }
          _showImageDialog(context, imageList, index);
        },
        child: Container(
          margin: padding,
          width: MediaQuery.of(context).size.width,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color:
                        CustomColor(context).backgroundColor1.withOpacity(0.2),
                  )),
              child: LayoutBuilder(builder: (context, constrains) {
                final showWidth = constrains.maxWidth *
                    MediaQuery.of(context).devicePixelRatio;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: ImageWidget.fromCachedNet(CachedImageBuilder(
                    imageUrl: url,
                    memCacheWidth: showWidth.toInt(),
                    cacheManager: CustomCacheManager.instance,
                    placeholder: (ctx, image) => Container(
                        width: constrains.maxWidth,
                        height: (realSize.item2 / realSize.item1) *
                            constrains.maxWidth,
                        color: theme.scaffoldBackgroundColor,
                        child: const Center(
                          child: CupertinoActivityIndicator(),
                        )),
                  )),
                );
              }),
            ),
          ),
        ),
      );
  } else if (o.isVideo) {
    final url = RichEditorUtils.getEmbedAttribute(o, 'source');
    final thumbUrl = RichEditorUtils.getEmbedAttribute(o, 'thumbUrl');
    final duration = RichEditorUtils.getEmbedAttribute(o, 'duration');
    final source = RichEditorUtils.getEmbedAttribute(o, 'source');
    final width = RichEditorUtils.getEmbedAttribute(o, 'width');
    final height = RichEditorUtils.getEmbedAttribute(o, 'height');
    final aspectRatio =
        (width != null && height != null && width != 0 && height != 0)
            ? width / height
            : (16 / 9);
    final realSize = getImageSize(width, height, maxSizeConstraint: 400);

    if (OrientationUtil.landscape)
      child = GestureDetector(
        onTap: () {
          showToast('按 [ESC] 即可退出全屏模式'.tr,
              textStyle: const TextStyle(fontSize: 20, color: Colors.white),
              position: ToastPosition.top);
          Navigator.push(
              context,
              CustomPageRouteBuilder(
                  (context, animation, secondaryAnimation) => WebVideoPlayer(
                        videoUrl: url,
                        thumbUrl: thumbUrl,
                        duration: duration,
                        messageId: url,
                        fullScreen: true,
                      )));
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
          width: double.infinity,
          height: realSize.item2,
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: realSize.item1,
            height: realSize.item2,
            child: WebVideoPlayer(
              videoUrl: url,
              thumbUrl: thumbUrl,
              messageId: '$index $url',
            ),
          ),
        ),
      );
    else
      child = GestureDetector(
        onTap: () {
          int index = 0;

          for (final image in imageList) {
            if (image.url == source) {
              index = image.index;
              break;
            }
          }
          _showImageDialog(context, imageList, index);
        },
        child: Container(
          margin: padding,
          width: MediaQuery.of(context).size.width,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: SizedBox(
                child: VideoWidget(
                  borderRadius: 8,
                  url: url,
                  backgroundColor: const Color.fromARGB(255, 0xf0, 0xf1, 0xf2),
                  duration: duration,
                  child: RoundImage(
                    url: thumbUrl,
                    placeholder: (context, url) =>
                        const Center(child: CupertinoActivityIndicator()),
                    cacheManager: CircleCachedManager.instance,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
  }

  return child;
}

String getAllText(List<Operation> list) {
  String result = '';
  for (var i = 0; i < list.length; ++i) {
    final o = list[i];
    if (o.key != Operation.insertKey) continue;
    if (!o.isEmbed) {
      String value = o.value as String;
      while (value.startsWith('\n')) {
        try {
          value = value.substring(1, value.length);
        } catch (e) {
          logger.severe('富文本字符截取错误');
        }
      }
      while (value.endsWith('\n')) {
        try {
          value = value.substring(0, value.length - 1);
        } catch (e) {
          logger.severe('富文本字符截取错误');
        }
      }
      result = result + value;
    }
    if (o.isAt) {
      if (o.value['mention'] != null) {
        result = result + o.value['mention']['value'] ?? '';
      }
    }
  }
  return result;
}

void _showImageDialog(
    BuildContext context, List<IndexMedia> images, int index) {
  showImageDialog(context,
      items: images
          .map((e) => GalleryItem(
                url: e.url,
                id: 'tag: $e',
                isImage: e.isImage,
                holderUrl: e.url,
              ))
          .toList(),
      index: index);
}

class IndexMedia {
  int index;
  String url;

  ///判断是图片还是视频
  bool isImage;

  IndexMedia(this.index, this.url, {this.isImage = true});
}
