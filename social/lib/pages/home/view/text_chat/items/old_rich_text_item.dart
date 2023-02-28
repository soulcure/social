import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:flutter_quill/flutter_quill.dart' as fq;
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/view/gallery/gallery.dart';
import 'package:im/pages/home/view/text_chat/items/text_item.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/pages/home/view/text_chat_constraints.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/widgets/web_video_player/web_video_player.dart';
import 'package:im/widgets/dialog/show_web_image_dialog.dart';
import 'package:im/widgets/image.dart';
import 'package:im/widgets/video_play_button.dart';

import 'components/parsed_text_extension.dart';

/// 旧版本的富文本，机器人有很多发错了格式，旧版本确能解析
/// 新版本的富文本修正了错误，导致错误的旧数据不能解析
/// 为了兼容旧版本，分离除了这个 Item
class OldRichTextItem extends StatefulWidget {
  final MessageEntity message;
  final List<MessageEntity> messageList;
  final IsUnFoldTextItemCallback isUnFold;
  final UnFoldTextItemCallback onUnFold;

  OldRichTextItem(
      {@required this.message,
      this.isUnFold,
      this.onUnFold,
      this.messageList = const []})
      : super(key: ValueKey(message?.messageId?.toString()));

  @override
  _OldRichTextItemState createState() => _OldRichTextItemState();
}

class _OldRichTextItemState extends State<OldRichTextItem> {
  double _maxContentHeight;
  final trimLineFeedRegExp = RegExp(r"^\n+|\n+$");
  int _mediaIndex = 0;
  TextStyle _titleStyle;
  TextStyle _bodyStyle;
  List<fq.Operation> _operationList;
  bool _needPadding;
  String _lastContent;

  @override
  void initState() {
    _operationList = RichEditorUtils.formatDelta(
            (widget.message.content as RichTextEntity).document.toDelta())
        .toList();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant OldRichTextItem oldWidget) {
    /// 此处是为了更新UI的消息内容
    /// 防止多次渲染处理
    if (_lastContent != widget.message.content.toJson().toString()) {
      _operationList = RichEditorUtils.formatDelta(
              (widget.message.content as RichTextEntity).document.toDelta())
          .toList();
    }

    _lastContent = widget.message.content.toJson().toString();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    try {
      _maxContentHeight =
          max(TextChatConstraints.of(context).constraints.maxHeight * 0.7, 350);
    } catch (e) {
      _maxContentHeight = 350;
    }
    _titleStyle ??= Theme.of(context)
        .textTheme
        .bodyText2
        .copyWith(fontSize: 17, fontWeight: FontWeight.w600);
    _bodyStyle ??= Theme.of(context)
        .textTheme
        .bodyText2
        .copyWith(height: 1.25, fontSize: 17);

    final hasEmbedObject = _operationList.any((o) => o.isEmbed);
    final title = (widget.message.content as RichTextEntity).title;
    final userInfo = Db.userInfoBox.get(widget.message.userId);
    return LayoutBuilder(builder: (context, constraints) {
      final height = measureHeight(constraints.maxWidth);
      _mediaIndex = 0;
      final isOverflow = height > _maxContentHeight;
      if (widget.message.quoteL1 != null) {
        _needPadding = false;
      } else if (isOverflow) {
        _needPadding = true;
      } else {
        _needPadding = hasEmbedObject || isNotNullAndEmpty(title);
      }
      final isShrink =
          widget.isUnFold?.call(widget.message.messageId) != true && isOverflow;
      return Container(
        padding: !_needPadding
            ? EdgeInsets.zero
            : const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: !_needPadding
            ? null
            : ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: userInfo.isBot && widget.message.replyMarkup == null
                      ? BorderSide(
                          color: CustomColor(context).globalBackgroundColor3)
                      : BorderSide.none,
                ),
                color: userInfo.isBot
                    ? Colors.white
                    : CustomColor(context).globalBackgroundColor3,
              ),
        child: _buildShrinkWidget(
          isShrink: isShrink,
          userInfo: userInfo,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((title ?? '').isNotEmpty) ...[
                    Text(
                      title ?? '',
                      style: _titleStyle,
                    ),
                    sizeHeight8,
                    Divider(
                      color: CustomColor(context).disableColor.withOpacity(0.3),
                    ),
                    sizeHeight8,
                  ],
                  ..._operationList
                      .map((e) => _buildDeltaItem(e, _operationList))
                      .toList()
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDeltaItem(fq.Operation o, List<fq.Operation> deltaList) {
    Widget child;
    if (o.key == fq.Operation.insertKey) {
      if (!o.isEmbed) {
        String value = o.value as String;
        value = value.replaceAll(trimLineFeedRegExp, "");
        child = value.isEmpty
            ? const SizedBox()
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ParsedText(
                  style: _bodyStyle,

                  /// TODO(临时方案)：加上一个不可打印字符，否则如果只有 emoji 字符的 Text，底部会被截掉一部分
                  text: '$nullChar$value$nullChar',
                  parse: [
                    ParsedTextExtension.matchCusEmoText(
                        context, _bodyStyle.fontSize),
                    ParsedTextExtension.matchURLText(context),
                    ParsedTextExtension.matchChannelLink(context),
                    ParsedTextExtension.matchAtText(context),
                  ],
                ),
              );
      } else if (o.isImage) {
        final size = getImageSize(
            num.tryParse(o.value['width'].toString()) ?? 120,
            num.tryParse(o.value['height'].toString()) ?? 120);

        final tempIndex = _mediaIndex;
        _mediaIndex++;
        child = GestureDetector(
          onTap: () {
            if (OrientationUtil.portrait)
              showGallery(ModalRoute.of(context).settings.name, widget.message,
                  quoteL1: widget.message.quoteL1,
                  messages: widget.messageList,
                  offset: tempIndex);
            else
              showWebImageDialog(context,
                  url: RichEditorUtils.getEmbedAttribute(o, 'source'),
                  width: RichEditorUtils.getEmbedAttribute(o, 'width'),
                  height: RichEditorUtils.getEmbedAttribute(o, 'height'));
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: NetworkImageWithPlaceholder(o.value['source'] ?? '',
                width: size.item1,
                height: size.item2,
                fit: BoxFit.contain,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                imageBuilder: (context, imageProvider) {
              final url = o.value['source'] ?? '';
              if (url.toString().toLowerCase().endsWith('gif')) {
                return _getRectImage(size.item1.toDouble(),
                    size.item2.toDouble(), BoxFit.contain, imageProvider);
                // return Container(
                //   width: size.item1.toDouble(),
                //   height: size.item2.toDouble(),
                //   decoration: BoxDecoration(
                //     image: DecorationImage(
                //       image: imageProvider,
                //       fit: BoxFit.contain,
                //     ),
                //   ),
                // );
              } else {
                final radio = MediaQuery.of(context).devicePixelRatio;
                final w = ((size.item1 ?? 0) * radio).toInt();
                final h = ((size.item2 ?? 0) * radio).toInt();
                return _getRectImage(
                    size.item1.toDouble(),
                    size.item2.toDouble(),
                    BoxFit.contain,
                    ResizeImage(imageProvider, width: w, height: h));
                // return Container(
                //   width: size.item1.toDouble(),
                //   height: size.item2.toDouble(),
                //   decoration: BoxDecoration(
                //     image: DecorationImage(
                //       image: ResizeImage(imageProvider, width: w, height: h),
                //       fit: BoxFit.contain,
                //     ),
                //   ),
                // );
              }
            }),
          ),
        );
      } else if (o.isVideo) {
        final tempIndex = _mediaIndex;
        _mediaIndex++;
        final size = getImageSize(
            num.tryParse(o.value['width'].toString()) ?? 120,
            num.tryParse(o.value['height'].toString()) ?? 120);
        final thumbUrl = o.value['thumbUrl'];
        final duration = o.value['duration'];
        final url = o.value['source'];
        if (kIsWeb) {
          final url = o.value['source'];
          return Container(
              width: max(size.item1.toDouble(), 210),
              height: size.item2,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: WebVideoPlayer(
                videoUrl: url,
                thumbUrl: thumbUrl,
                duration: duration,
                padding:
                    size.item1 < 210 ? (210 - size.item1.toDouble()) / 2 : 0,
              ));
        }
        child = GestureDetector(
          onTap: () {
            showGallery(ModalRoute.of(context).settings.name, widget.message,
                quoteL1: widget.message.quoteL1,
                messages: widget.messageList,
                offset: tempIndex);
          },
          child: Container(
            width: size.item1.toDouble(),
            height: size.item2.toDouble(),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: VideoWidget(
              duration: duration ?? 0,
              borderRadius: 8,
              url: url,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: CachedProviderBuilder(thumbUrl,
                              cacheManager: CustomCacheManager.instance)
                          .provider,
                      fit: BoxFit.cover),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        );
      } else {
        child = const SizedBox();
      }
    }

    return child;
  }

  Widget _getRectImage(
      double width, double height, BoxFit fit, ImageProvider image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: width,
        height: height,
        child: Image(image: image, fit: fit),
      ),
    );
  }

  double measureHeight(double width) {
    double height = 0;
    // 上下边距
    height += 20;
    final title = (widget.message.content as RichTextEntity).title;
    if (isNotNullAndEmpty(title)) {
      // title边距
      height += 16;
    }
    final TextPainter painter = TextPainter(
        locale: Localizations.localeOf(context),
        textDirection: TextDirection.ltr,
        text: TextSpan(children: [
          TextSpan(text: title, style: _titleStyle),
          ...List<InlineSpan>.from(_operationList.map((o) {
            if (o.key == fq.Operation.insertKey) {
              if (!o.isEmbed) {
                height += 8;
                final value = o.value.replaceAll(trimLineFeedRegExp, "");
                return value.isEmpty
                    ? const TextSpan(text: "")
                    : TextSpan(style: _bodyStyle, text: value);
              } else if (o.isImage || o.isVideo) {
                final size = getImageSize(
                    num.tryParse(o.value['width'].toString()) ?? 120,
                    num.tryParse(o.value['height'].toString()) ?? 120);
                height += size.item2 + 8;
                return const TextSpan(text: "\n");
              } else {
                return const TextSpan(text: "");
              }
            }
          }))
        ]));
    painter.layout(maxWidth: width);
    return painter.height + height;
  }

  Widget _buildShrinkWidget(
      {@required Widget child, bool isShrink = false, UserInfo userInfo}) {
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    if (!isShrink) return child;
    return LimitedBox(
      maxHeight: _maxContentHeight,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          child,
          Positioned.fill(
            top: 255,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                gradient: LinearGradient(
                  colors: [
                    (userInfo.isBot ? Colors.white : scaffoldBackgroundColor)
                        .withAlpha(0),
                    (userInfo.isBot ? Colors.white : scaffoldBackgroundColor)
                        .withAlpha(125),
                    (userInfo.isBot ? Colors.white : scaffoldBackgroundColor)
                        .withAlpha(255),
                  ],
                  begin: const Alignment(0, -0.2),
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
                onTap: () {
                  widget.onUnFold?.call(widget.message.messageId);
                  setState(() {});
                },
                child: UnconstrainedBox(
                  child: Container(
                    height: 36,
                    width: 96,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      shape: const StadiumBorder(
                          side:
                              BorderSide(width: 0.5, color: Color(0xFFE0E2E6))),
                      color: Theme.of(context).backgroundColor,
                      shadows: const [
                        BoxShadow(
                            color: Color(0x1A6A7480),
                            offset: Offset(0, 1),
                            blurRadius: 8)
                      ],
                    ),
                    child: Text(
                      "查看全文".tr,
                      style: TextStyle(
                          color: Theme.of(context).primaryColor, fontSize: 14),
                    ),
                  ),
                )),
          )
        ],
      ),
    );
  }
}
