import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/check_permission.dart';
import 'package:im/pages/home/view/gallery/gallery.dart';
import 'package:im/pages/home/view/gallery/photo_view.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_io.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/editor/editor.dart'
    as editor;
import 'package:im/pages/home/view/text_chat/rich_editor/factory/abstract_rich_text_factory.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/utils/show_rich_editor_tooltip.dart';
import 'package:im/web/widgets/web_video_player/web_video_player.dart';
import 'package:im/widgets/custom/custom_page_route_builder.dart';
import 'package:im/widgets/dialog/show_web_image_dialog.dart';
import 'package:im/widgets/round_image.dart';
import 'package:im/widgets/video_play_button.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tun_editor/tun_editor_toolbar.dart';
import 'package:tuple/tuple.dart';

import 'circle_reply_cache.dart';
// const double _pagePadding = 18;

Future showLandscapeCircleReplyPopup(BuildContext context,
    {@required String guildId,
    @required String channelId,
    MessageEntity reply,
    String hintText = '说点什么...',
    String commentId,
    OnReplySend onReplySend}) async {
  final res = await showWebRichEditorTooltip<bool>(context, builder: (c, done) {
    return RichEditor(
      guildId: guildId,
      channelId: channelId,
      commentId: commentId,
      hintText: hintText,
      reply: reply,
      onReplySend: onReplySend,
      closeEditor: done,
    );
  });
  try {
    final richEditorModel = Get.find<RichEditorModel>();
    richEditorModel.closeEditor?.call(false);
    richEditorModel.dispose();
    await Get.delete<RichEditorModel>();
  } catch (e, s) {
    logger.severe(e, s);
  }
  return res;
}

class RichEditor extends StatefulWidget {
  // 重新编辑富文本消息需要传此参数
  final MessageEntity originMessage;
  final String hintText;
  final OnReplySend onReplySend;
  final String guildId;
  final String channelId;
  final String commentId;

  // 是否是回复某条消息
  final MessageEntity reply;

  final Function closeEditor; // final bool isClosed;
  const RichEditor({
    @required this.guildId,
    @required this.channelId,
    this.reply,
    this.originMessage,
    this.hintText,
    this.onReplySend,
    this.commentId,
    this.closeEditor,
  });

  @override
  RichEditorState createState() => RichEditorState();
}

class RichEditorState extends State<RichEditor> {
  // QuillController _controller;
  FocusNode _editorFocusNode;
  bool _needSaveDocInMem = true;
  RichEditorModel _model;
  final ValueNotifier<bool> _disableConfirm = ValueNotifier(true);
  final ValueNotifier<bool> _confirmLoading = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _loadDocument().then((map) {
      setState(() {
        _model = AbstractRichTextFactory.instance.createEditorModel(
          channel: ChatChannel(
            guildId: widget.guildId,
            id: widget.channelId,
            type: ChatChannelType.guildCircle,
          ),
          needTitle: false,
          titlePlaceholder: '无标题'.tr,
          editorPlaceholder: '说点什么...'.tr,
          defaultDoc: map['document'],
          toolbarItems: [ToolbarMenu.emoji, ToolbarMenu.at],
          onSend: () => _sendDoc(context),
        );
      });
      _model.closeEditor = widget.closeEditor;
      _model.addListener(() {
        if (_model.hasListeners) {
          _model.closeEditor();
        }
      });
      // _model.tabIndex.value = null;
      _model.editorController.document.changes.listen((event) {
        if (event.item3 == ChangeSource.REMOTE) return;
        final changeList = event.item2.toList();
        bool isAt = false;
        try {
          isAt = Document.fromDelta(event.item1)
              .collectStyle(max(_model.editorController.selection.end, 0), 0)
              .containsKey(Attribute.at.key);
        } catch (e) {
          // logger.severe('富文本 collectStyle', e);
        }
        if (changeList.any((element) => element.isDelete) && isAt) {
          onDelete(event);
        } else if (changeList.any((element) => element.isInsert)) {
          onInsert(event);
        }
        setDisableConfirm();
      });
      Get.put(_model);
      // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      //   _editorFocusNode.requestFocus();
      //   _model.editorController.updateSelection(TextSelection.collapsed(
      //       offset: _model.editorController.document.length));
      // });
    });
  }

  void onDelete(Tuple3<Delta, Delta, ChangeSource> event) {
    final changeList = event.item2.toList();
    final delPosition = changeList.first.length;
    final int oIndex =
        RichEditorUtils.getOperationIndex(event.item1, delPosition);
    final lenBeforeOperation =
        RichEditorUtils.getLenBeforeOperation(event.item1, oIndex);
    if (oIndex != -1) {
      final Delta change = Delta()
        ..retain(lenBeforeOperation)
        ..delete(event.item1.elementAt(oIndex).length - 1);
      final nextOperation =
          RichEditorUtils.getNextOperation(event.item1, oIndex);
      // 是否嵌入节点
      final isEmbedObject = nextOperation != null && nextOperation.isEmbed;
      final isLast = RichEditorUtils.isLastOperation(event.item1, oIndex);
      // 特殊情况需插入换行符
      if (isLast || isEmbedObject) {
        change.insert('\n');
      }
      _model.editorController.document.compose(change, ChangeSource.REMOTE);
      _model.editorController.updateSelection(
          TextSelection.collapsed(offset: lenBeforeOperation),
          ChangeSource.LOCAL);
    }
  }

  void onInsert(Tuple3<Delta, Delta, ChangeSource> event) {
    final changeList = event.item2.toList();
    final after = _model.editorController.document.toDelta();
    final oIndex = RichEditorUtils.getOperationIndex(
        after, _model.editorController.selection.end - 1);
    if (oIndex == -1) return;
    // 在@和#中间插入字符
    final current = after.elementAt(oIndex);
    if (current.isAt || current.isChannel) {
      final start = RichEditorUtils.getLenBeforeOperation(after, oIndex);
      _model.editorController.formatText(
        start,
        after.elementAt(oIndex).length,
        current.isAt ? AtAttribute(null) : ChannelAttribute(null),
      );
      return;
    }
    final o = changeList.firstWhere((element) => element.isInsert,
        orElse: () => null);
    if (o?.value == '@') {
      _model.isAtFromInput = true;
      toolbarCallback.showAtList(context, _model);
    }
  }

  void setDisableConfirm() {
    _disableConfirm.value = _model.editorController.document.isContentEmpty;
  }

  @override
  void dispose() {
    if (_needSaveDocInMem)
      CircleReplyCache().putCache(
          widget.commentId, _model.editorController.document.encode());
    _editorFocusNode?.dispose();
    // _model?.dispose();
    // widget.closeEditor?.call(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_model?.editorController == null)
      return const Center(child: CircularProgressIndicator());

    final shouldShowTitle = widget.hintText?.isNotEmpty ?? false;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        (FocusScope.of(context).hasFocus ? 0 : getBottomViewInset());
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Material(
        color: Theme.of(context).backgroundColor,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sizeHeight16,
                  if (shouldShowTitle) _buildTitle(),
                  Expanded(
                    child: editor.RichEditor(_model),
                  ),
                  if (OrientationUtil.landscape) _footer()
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final theme = Theme.of(context);
    final color2 = theme.textTheme.bodyText1.color;
    final hintText = widget.hintText;
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Text(
          hintText,
          style: TextStyle(color: color2, fontSize: 14),
        ));
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
      final deltaList = _model.editorController.document.toDelta().toList();

      final str = _model.editorController.document
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
      // await RichEditorUtils.uploadFileInDoc(_model.editorController.document);
      // printDoc();
      final passed = await CheckUtil.startCheck(TextCheckItem(
          str, TextChannelType.FB_CIRCLE_POST_COMMENT,
          checkType: CheckType.circle));
      if (!passed) return;

      widget.onReplySend?.call(_model.editorController.document);
      _needSaveDocInMem = false;
      _model.editorController
        ..document.replace(0, _model.editorController.document.length - 1, '')
        ..updateSelection(
            const TextSelection.collapsed(offset: 0), ChangeSource.LOCAL);

      // 发送成功返回true
      Get.find<RichEditorModel>().closeEditor.call(true);
    } catch (e, s) {
      logger.severe('富文本发送失败', e, s);
    } finally {
      Loading.hide();
      _needSaveDocInMem = true;
    }
  }

  Future<Map<String, dynamic>> pickImages(
      String identify, List<String> selectAssets, bool thumb) async {
    try {
      final result = await MultiImagePicker.pickImages(
          defaultAsset: identify,
          thumbType: thumb ? FBMediaThumbType.thumb : FBMediaThumbType.origin,
          selectedAssets: selectAssets,
          doneButtonText: '确定'.tr,
          cupertinoOptions: CupertinoOptions(
              takePhotoIcon: "chat",
              selectionStrokeColor:
                  "#${Theme.of(context).primaryColor.value.toRadixString(16)}",
              selectionFillColor:
                  "#${Theme.of(context).primaryColor.value.toRadixString(16)}"),
          materialOptions: MaterialOptions(
            allViewTitle: "所有图片".tr,
            selectCircleStrokeColor:
                "#${Theme.of(context).primaryColor.value.toRadixString(16)}",
          ));
      final List<String> identifiers = [];
      for (final item in result['identifiers']) {
        identifiers.add(item.toString());
      }
      unawaited(
          insertImage((result['identifiers'] as List).cast<String>(), !thumb));
      return null;
    } on Exception catch (e) {
      if (e is PlatformException) {
        if (e.code == "PERMISSION_PERMANENTLY_DENIED") {
          await checkSystemPermissions(
            context: context,
            permissions: [
              if (UniversalPlatform.isIOS) Permission.photos,
              if (UniversalPlatform.isAndroid) Permission.storage,
            ],
          );
        } else if (e.code == "CANCELLED") {
          final List<Map<String, String>> selectMedias = [];
          final assets = e.details['assets'];
          final thumb = e.details['thumb'];
          for (var i = 0; i < assets.length; i++) {
            final item = assets[i];
            final identify = item['identify'] as String;
            final fileType = item['fileType'] as String;
            final media = {'identify': identify, 'fileType': fileType};
            selectMedias.add(media);
          }
          return {"assets": selectMedias, "thumb": thumb};
        }
      }
    }
    return null;
  }

  Future<void> insertImage(List<String> assets, bool isOrigin) async {
    Loading.show(context);
    List<Asset> assetList;
    try {
      assetList = await MultiImagePicker.requestMediaData(
          thumb: !isOrigin, selectedAssets: assets);
      Loading.hide();
    } catch (e) {
      logger.severe('富文本获取媒体失败', e);
      Loading.hide();
    }
    assetList.forEach((e) async {
      if (e?.filePath != null && e.fileType.startsWith('image/'))
        _model.editorController.document.insert(
            _model.editorController.selection.end,
            ImageEmbed(
                source: e.filePath,
                width: e.originalWidth,
                height: e.originalHeight,
                checkPath: e.checkPath));
      if (e?.filePath != null && e.fileType.startsWith('video'))
        _model.editorController.document.insert(
            _model.editorController.selection.end,
            VideoEmbed(
              source: e.filePath,
              width: e.originalWidth,
              height: e.originalHeight,
              fileType: e.fileType,
              duration: e.duration == null ? 0 : e.duration.toInt(),
              thumbUrl: e.thumbFilePath,
              thumbName: e.thumbName,
            ));
      _model.editorController.updateSelection(
          TextSelection.collapsed(
              offset: _model.editorController.selection.end + 2),
          ChangeSource.LOCAL);
      // 最后一张换行
      if (e == assetList.last) {
        _model.editorController
          ..document.insert(_model.editorController.selection.end, '\n')
          ..updateSelection(
              TextSelection.collapsed(
                  offset: _model.editorController.selection.end + 1),
              ChangeSource.LOCAL)
          // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
          ..notifyListeners();
      }
    });
  }

  void printDoc() {
    print(jsonEncode(_model.editorController.document));
  }

  String getFilename(String filePath) {
    final index = filePath.lastIndexOf('/');
    return index > -1 ? filePath.substring(index + 1, filePath.length) : '';
  }

  Future<bool> _onWillPop() async {
    if (Loading.visible) {
      return false;
    }
    return true;
  }

  Widget _footer() {
    final _theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(
            width: 88,
            height: 32,
            child: ValueListenableBuilder<bool>(
                valueListenable: _disableConfirm,
                builder: (context, disableConfirm, child) {
                  return TextButton(
                      onPressed: disableConfirm
                          ? null
                          : () async {
                                try {
                                  _confirmLoading.value = true;
                                  await _sendDoc(context);
                                  _confirmLoading.value = false;
                                } catch (e) {
                                  _confirmLoading.value = false;
                                }
                              } ??
                              () => Navigator.of(context).pop(true),
                      child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: disableConfirm
                                ? const Color(0xFF6179f2).withOpacity(0.4)
                                : _theme.primaryColor,
                          ),
                          alignment: Alignment.center,
                          child: ValueListenableBuilder(
                            valueListenable: _confirmLoading,
                            builder: (context, loading, child) {
                              return loading
                                  ? const SizedBox(
                                      height: 15,
                                      width: 15,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          backgroundColor: Colors.white),
                                    )
                                  : Text(
                                      '确定',
                                      style: _theme.textTheme.bodyText2
                                          .copyWith(color: Colors.white),
                                    );
                            },
                          )));
                }),
          ),
        ],
      ),
    );
  }
}

Widget buildRichText(
  String content,
  BuildContext context, {
  TextStyle style,
  int maxLines,
  TextOverflow textOverflow,
  EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(0, 0, 0, 16),
}) {
  final document = Document.fromJson(jsonDecode(content));
  final list = RichEditorUtils.formatDelta(document.toDelta()).toList();
  return buildRichWithList(list, context,
      style: style,
      padding: padding,
      maxLines: maxLines,
      textOverflow: textOverflow);
}

// TextSpan buildRichTextSpan(String content, BuildContext context,
//     {TextStyle style,
//     List<String> imageList,
//     int maxLines,
//     TextOverflow textOverflow}) {
//   final document = Document.fromJson(jsonDecode(content));
//   final list = RichEditorUtils.formatDelta(document.toDelta()).toList();
//   return buildRichSpanWithList(list, context,
//       style: style, maxLines: maxLines, textOverflow: textOverflow);
// }

Widget buildRichWithList(
  List<Operation> list,
  BuildContext context, {
  TextStyle style,
  List<IndexMedia> imageList,
  int maxLines,
  TextOverflow textOverflow,
  EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(0, 0, 0, 16),
}) {
  final List<InlineSpan> children = List.generate(list.length, (index) {
    final cur = list[index];
    return WidgetSpan(
        child: _buildDeltaItem(
      cur,
      context,
      style: style,
      imageList: imageList,
      maxLines: maxLines,
      padding: padding,
      index: index,
      textOverflow: textOverflow,
    ));
  });
  children.add(const TextSpan(
      text: '')); //TODO flutter的bug，WidgetSpan的列表，最后得+一个TextSpan，不然会卡死
  return Text.rich(TextSpan(children: children));
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

List<MatchText> getParseList(BuildContext context, {TextStyle style}) => [
      ParsedTextExtension.matchCusEmoText(context, style.fontSize),
      ParsedTextExtension.matchURLText(context),
      ParsedTextExtension.matchChannelLink(context),
      ParsedTextExtension.matchAtText(context, textStyle: style),
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
    style ??= Theme.of(context).textTheme.bodyText2.copyWith(
          height: 1.25,
          fontSize: OrientationUtil.portrait ? 17 : 14,
        );
    child = value.isEmpty
        ? sizedBox
        : ParsedText(
            style: style,

            /// 加上一个不可打印字符，否则如果只有 emoji 字符的 Text，底部会被截掉一部分
            text: '$value$nullChar',
            parse: [
              ParsedTextExtension.matchCusEmoText(context, style.fontSize),
              ParsedTextExtension.matchURLText(context),
              ParsedTextExtension.matchChannelLink(context),
              ParsedTextExtension.matchAtText(context, textStyle: style),
            ],
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
                    placeholder: (ctx, image) {
                      double _width;
                      double _height;
                      if (w <= showWidth) {
                        _width = realSize.item1;
                        _height = realSize.item2;
                      } else {
                        _width = constrains.maxWidth;
                        _height = (realSize.item2 / realSize.item1) *
                            constrains.maxWidth;
                      }
                      return Container(
                        width: _width,
                        height: _height,
                        color: theme.scaffoldBackgroundColor,
                        child: const Center(
                          child: CupertinoActivityIndicator(),
                        ),
                      );
                    },
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

typedef OnReplySend = void Function(Document doc);
