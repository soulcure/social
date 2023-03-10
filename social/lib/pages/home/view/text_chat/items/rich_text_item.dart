import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:flutter_quill/flutter_quill.dart'
    hide Text, DefaultStyles, DefaultTextBlockStyle;
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/view/gallery/gallery.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/home/view/text_chat/items/text_item.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/cos_file_cache_index.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/utils/image_operator_collection/provider_builder.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/widgets/web_video_player/web_video_player.dart';
import 'package:im/widgets/dialog/show_web_image_dialog.dart';
import 'package:im/widgets/image.dart';
import 'package:im/widgets/over_flow_container.dart';
import 'package:im/widgets/poly_text/poly_text.dart';
import 'package:im/widgets/user_info/realtime_nick_name.dart';
import 'package:im/widgets/video_play_button.dart';

import '../../../../../global.dart';

class RichTextItem extends StatefulWidget {
  final MessageEntity message;
  final List<MessageEntity> messageList;
  final IsUnFoldTextItemCallback isUnFold;
  final UnFoldTextItemCallback onUnFold;
  final String searchKey; //????????????????????????key

  RichTextItem({
    @required this.message,
    this.isUnFold,
    this.onUnFold,
    this.messageList = const [],
    this.searchKey,
  }) : super(key: ValueKey(message?.messageId?.toString()));

  @override
  RichTextItemState createState() => RichTextItemState();
}

class RichTextItemState extends State<RichTextItem> {
  final trimLineFeedRegExp = RegExp(r"^\n+|\n+$");
  TextStyle _titleStyle;
  TextStyle _bodyStyle;
  QuillController _quillController;
  int _mediaIndex;
  Document _document;
  Map<int, int> embedIndex = {};

  @override
  void initState() {
    _document = ignoreEmptyLineAtEnd(
        (widget.message.content as RichTextEntity).document);
    _quillController = QuillController(
        selection: const TextSelection.collapsed(offset: 0),
        document: _document);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _titleStyle ??= Theme.of(context)
        .textTheme
        .bodyText2
        .copyWith(fontSize: 17, fontWeight: FontWeight.w600);
    _bodyStyle ??= Theme.of(context)
        .textTheme
        .bodyText2
        .copyWith(height: 1.25, fontSize: 17);

    final isCircleMessage = widget.message.isCircleMessage;
    final userInfo = Db.userInfoBox.get(widget.message.userId);
    final title = (widget.message.content as RichTextEntity).title;
    final needPadding = widget.message.quoteL1 == null;
    _mediaIndex = 0;
    embedIndex.clear();
    final padding = isCircleMessage
        ? const EdgeInsets.fromLTRB(0, 2, 0, 0)
        : (!needPadding ? EdgeInsets.zero : const EdgeInsets.all(12));
    return Container(
      padding: padding,
      decoration: !needPadding
          ? null
          : ShapeDecoration(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: userInfo.isBot && widget.message.replyMarkup == null
                    ? BorderSide(
                        color: CustomColor(context).globalBackgroundColor3)
                    : BorderSide.none,
              ),
              color: userInfo.isBot || isCircleMessage
                  ? Colors.transparent
                  : appThemeData.scaffoldBackgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((title ?? '').isNotEmpty) ...[
            if (widget.searchKey.hasValue)
              ParsedText(
                text: title ?? '',
                style: _titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                regexOptions: const RegexOptions(caseSensitive: false),
                parse: [
                  ParsedTextExtension.matchSearchKey(context, widget.searchKey,
                      _titleStyle.copyWith(color: Get.theme.primaryColor)),
                ],
              )
            else
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
          OverFlowContainer(child: _buildDocument()),
        ],
      ),
    );
  }

  /// ????????????????????????????????????17
  Widget _buildDocument() {
    return PolyText(
      key: ValueKey(_quillController.hashCode),
      document: _quillController.document,
      baseStyle: Get.textTheme.bodyText2.copyWith(fontSize: 17),
      quoteVerticalSpacing: 8,
      codeVerticalSpacing: 8,
      embedBuilder: embedBuilder,
      mentionBuilder: (embed) =>
          mentionBuilder(embed, guildId: widget.message.guildId),
    );
  }

  // TODO [widgetSpanAlignment] ????????? PolyText ????????????????????????????????? IntristicWidth???????????? baseline ???????????????
  // ???????????? PolyText ?????????????????????????????????????????????
  static InlineSpan mentionBuilder(Embed embed,
      {@required String guildId,
      PlaceholderAlignment widgetSpanAlignment =
          PlaceholderAlignment.baseline}) {
    // final channel = Db.channelBox.get(value);
    // if(node.value is )
    if (embed.value is MentionEmbed) {
      final value = embed.value as MentionEmbed;
      if (TextEntity.atPattern.hasMatch(value.id)) {
        return _buildAt(value,
            guildId: guildId, widgetSpanAlignment: widgetSpanAlignment);
      } else if (TextEntity.channelLinkPattern.hasMatch(value.id)) {
        return _buildChannel(value);
      } else {
        return TextSpan(text: embed.value.toString());
      }
    } else {
      return TextSpan(text: embed.value.toString());
    }
  }

  // todo ???????????????????????? exetndedText ?????????????????????
  static InlineSpan _buildAt(MentionEmbed embed,
      {@required String guildId, PlaceholderAlignment widgetSpanAlignment}) {
    var text = embed.value;
    Color textColor;
    Color bgColor;
    Widget child;
    // TODO ??????????????????????????????????????? UI
    final match = TextEntity.atPattern.firstMatch(embed.id);
    final id = match.group(2);
    final isRole = match.group(1) == "&";
    if (!isRole) {
      if (id == Global.user.id) {
        textColor = primaryColor;
        bgColor = primaryColor.withOpacity(0.15);
      } else {
        textColor = primaryColor;
      }

      child = RealtimeNickname(
        userId: id,
        guildId: guildId,
        showNameRule: ShowNameRule.remarkAndGuild,
        prefix: "@",
        suffix: bgColor == null ? " " : "",
        textScaleFactor: 1,
        style: TextStyle(color: textColor),
        tapToShowUserInfo: true,
      );
    } else {
      try {
        final role = PermissionModel.getPermission(
                ChatTargetsModel.instance.selectedChatTarget.id)
            .roles
            .firstWhere((element) => element.id == id);

        text = "@${role.name}";

        if (role.color != 0)
          textColor = Color(role.color);
        else
          textColor = Get.textTheme.bodyText2.color;

        if (id == ChatTargetsModel.instance.selectedChatTarget.id ||
            Db.userInfoBox.get(Global.user.id).roles.contains(id)) {
          bgColor = primaryColor.withOpacity(0.2);
          textColor = primaryColor;
        }
      } catch (e) {
        text = "@??????????????????".tr;
      }
    }

    child ??= Text(
      text,
      textScaleFactor: 1,
      style: TextStyle(color: textColor),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    /// @?????? ???????????????
    if (bgColor != null) {
      child = IntrinsicWidth(
          child: ParsedTextExtension.buildPrimaryColorBox(child));
    }

    /// ???????????? builder??????????????? @???????????????????????????????????????????????? listen ???????????????????????????????????????
    return WidgetSpan(
        baseline: TextBaseline.alphabetic,
        alignment: widgetSpanAlignment,
        child: Builder(builder: (context) => child));
  }

  static TextSpan _buildChannel(MentionEmbed embed) {
    final match = TextEntity.channelLinkPattern.firstMatch(embed.id);
    final id = match.group(1);
    final channel = Db.channelBox.get(id);
    return TextSpan(
      text: " #${channel?.name ?? "?????????????????????".tr} ",
      style: TextStyle(color: primaryColor),
      recognizer: TapGestureRecognizer()
        ..onTap = () => ParsedTextExtension.onChannelTap(id),
    );
  }

  Widget embedBuilder(BuildContext context, Embed node) {
    final type = node.value.type;
    Widget child;
    switch (type) {
      case 'image':
        child = _buildImage(context, node.value as ImageEmbed);
        break;
      case 'video':
        child = _buildVideo(context, node.value as VideoEmbed);
        break;
      case 'divider':
        child = const Divider(height: 20, thickness: 1);
        break;
      default:
        child = const SizedBox();
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

// ????????????????????????
  Widget _buildImage(BuildContext context, ImageEmbed embed) {
    final size = getImageSize(embed.width, embed.height);
    int tempIndex;
    if (embedIndex.containsKey(embed.hashCode)) {
      tempIndex = embedIndex[embed.hashCode];
    } else {
      tempIndex = _mediaIndex;
      embedIndex[embed.hashCode] = tempIndex;
      _mediaIndex++;
    }

    final isCircleMessage = widget.message.isCircleMessage;
    Widget _image() {
      if (embed.source == null || embed.source.isEmpty)
        return const SizedBox.shrink();

      final isGif = embed.source.toString().toLowerCase().endsWith('gif');
      final radio = MediaQuery.of(context).devicePixelRatio;
      final w = size.item1 ?? 0;
      final h = size.item2 ?? 0;
      final rw = isGif ? w : w * radio;
      final rh = isGif ? h : h * radio;
      // ???????????????????????????????????????????????????
      String localUrl = CosUploadFileIndexCache.cachePath(embed.source);
      if (localUrl == null &&
          isCircleMessage &&
          embed.source.startsWith(Global.deviceInfo.thumbDir)) {
        // ??????????????????: ????????????????????????????????????????????????????????????????????????http??????
        localUrl = embed.source;
      }
      if (localUrl != null) {
        return SizedBox(
            width: w.toDouble(),
            height: h.toDouble(),
            child:
                Image(image: FileImage(File(localUrl)), fit: BoxFit.contain));
      }
      if (isGif) {
        // ??????imageBuilder??????gif,???android??????cpu??????10%
        // https://idreamsky.feishu.cn/docs/doccn1n3nWgVxElxVrFsSgDpCac#FXZOSb
        return NetworkImageWithPlaceholder(
          embed.source,
          width: w.toDouble(),
          height: h.toDouble(),
          fit: BoxFit.contain,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      }
      return NetworkImageWithPlaceholder(embed.source,
          width: w.toDouble(),
          height: h.toDouble(),
          fit: BoxFit.contain,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          imageBuilder: (context, imageProvider) {
        return Image(
            image: ResizeImage(imageProvider,
                width: rw.toInt(), height: rh.toInt()),
            fit: BoxFit.contain);
      });
    }

    return GestureDetector(
      onTap: () {
        if (OrientationUtil.portrait)
          showGallery(
            ModalRoute.of(context).settings.name,
            widget.message,
            quoteL1: widget.message.quoteL1,
            messages: widget.messageList,
            offset: tempIndex,
            isNeedLocation: !isCircleMessage,
          );
        else
          showWebImageDialog(
            context,
            url: embed.source,
            width: embed.width,
            height: embed.height,
          );
      },
      child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          foregroundDecoration: BoxDecoration(
            border: Border.all(
              color: appThemeData.dividerColor.withOpacity(0.2),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            clipBehavior: Clip.hardEdge,
            child: _image(),
          )),
    );
  }

  Widget _buildVideo(BuildContext context, VideoEmbed embed) {
    int tempIndex;
    if (embedIndex.containsKey(embed.hashCode)) {
      tempIndex = embedIndex[embed.hashCode];
    } else {
      tempIndex = _mediaIndex;
      embedIndex[embed.hashCode] = tempIndex;
      _mediaIndex++;
    }
    final size = getImageSize(
      embed.width,
      embed.height,
    );
    final thumbUrl = embed.thumbUrl;
    final duration = embed.duration;
    final url = embed.source;
    if (kIsWeb) {
      return Container(
          width: max(size.item1.toDouble(), 210),
          height: size.item2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: WebVideoPlayer(
            videoUrl: url,
            thumbUrl: thumbUrl,
            duration: duration,
            padding: size.item1 < 210 ? (210 - size.item1.toDouble()) / 2 : 0,
          ));
    }
    return GestureDetector(
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
          borderRadius: 4,
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
  }

  Document ignoreEmptyLineAtEnd(Document doc) {
    // ??????document????????????
    final originDoc = Document.fromDelta(doc.toDelta());
    final originDelta = originDoc.toDelta();
    final lastOperation = originDelta.last;
    if (lastOperation.value is String &&
        // h1???h2???h3????????????attributes???????????????
        (lastOperation.attributes?.isEmpty ?? true)) {
      final matchNewLine = RegExp(r'\n+$').allMatches(lastOperation.value);
      if (matchNewLine.isNotEmpty) {
        final match = matchNewLine.single;
        final deleteNum = match.end - match.start - 1;
        final newDelta = Delta()
          ..retain(originDoc.length - deleteNum)
          ..delete(deleteNum);
        if (newDelta.length == 2)
          originDoc.compose(newDelta, ChangeSource.REMOTE);
      }
    }
    return originDoc;
  }
}
