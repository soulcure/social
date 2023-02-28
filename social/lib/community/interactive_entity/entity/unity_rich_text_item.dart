import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart'
    hide Text, DefaultStyles, DefaultTextBlockStyle;
import 'package:get/get.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/home/view/text_chat/items/text_item.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/over_flow_container.dart';
import 'package:im/widgets/poly_text/poly_text.dart';
import 'package:im/widgets/user_info/realtime_nick_name.dart';

class UnityRichTextItem extends StatefulWidget {
  final MessageEntity message;
  final List<MessageEntity> messageList;
  final IsUnFoldTextItemCallback isUnFold;
  final UnFoldTextItemCallback onUnFold;
  final String searchKey; //消息搜索的关键字key

  UnityRichTextItem({
    @required this.message,
    this.isUnFold,
    this.onUnFold,
    this.messageList = const [],
    this.searchKey,
  }) : super(key: ValueKey(message?.messageId?.toString()));

  @override
  _UnityRichTextItemState createState() => _UnityRichTextItemState();
}

class _UnityRichTextItemState extends State<UnityRichTextItem> {
  // double _maxContentHeight;
  final trimLineFeedRegExp = RegExp(r"^\n+|\n+$");

  TextStyle _bodyStyle;
  QuillController _quillController;
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
    _bodyStyle ??= Theme.of(context)
        .textTheme
        .bodyText2
        .copyWith(height: 1.25, fontSize: 17);

    final title = (widget.message.content as RichTextEntity).title;
    embedIndex.clear();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((title ?? '').isNotEmpty) ...[
          Text(
            title ?? '',
            style: _bodyStyle,
          ),
          sizeHeight8,
        ],
        OverFlowContainer(child: AbsorbPointer(child: _buildDocument())),
      ],
    );
  }

  Widget _buildDocument() {
    return PolyText(
      key: ValueKey(_quillController.hashCode),
      document: _quillController.document,
      baseStyle: Get.textTheme.bodyText2,
      quoteVerticalSpacing: 8,
      codeVerticalSpacing: 8,
      embedBuilder: embedBuilder,
      mentionBuilder: mentionBuilder,
    );
  }

  InlineSpan mentionBuilder(Embed embed) {
    // final channel = Db.channelBox.get(value);
    // if(node.value is )
    if (embed.value is MentionEmbed) {
      final value = embed.value as MentionEmbed;
      if (TextEntity.atPattern.hasMatch(value.id)) {
        return _buildAt(value);
      } else if (TextEntity.channelLinkPattern.hasMatch(value.id)) {
        return _buildChannel(value);
      } else {
        return TextSpan(text: embed.value.toString());
      }
    } else {
      return TextSpan(text: embed.value.toString());
    }
  }

  // todo 这一整个方法在用 exetndedText 重构后全部删掉
  InlineSpan _buildAt(MentionEmbed embed) {
    var text = embed.value;
    final textStyle = DefaultTextStyle.of(context).style;
    Color textColor;
    Color bgColor;
    Widget child;
    // TODO 使用适配器统一新旧富文本的 UI
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
        prefix: "@",
        suffix: bgColor == null ? " " : "",
        textScaleFactor: 1,
        style: textStyle.copyWith(color: textColor),
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
          textColor = Theme.of(context).textTheme.bodyText2.color;

        if (id == ChatTargetsModel.instance.selectedChatTarget.id ||
            Db.userInfoBox.get(Global.user.id).roles.contains(id)) {
          bgColor = primaryColor.withOpacity(0.2);
          textColor = primaryColor;
        }
      } catch (e) {
        text = "@该角色已删除".tr;
      }
    }

    child ??= Text(
      text,
      textScaleFactor: 1,
      style: textStyle.copyWith(color: textColor),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    /// @自己 有文字背景
    if (bgColor != null) {
      child = IntrinsicWidth(
          child: ParsedTextExtension.buildPrimaryColorBox(child));
    }

    /// 如果没有 builder，一个文本 @同一个人两次会报错，如果采用代码 listen 一次的方式可能解决这个问题
    return WidgetSpan(
        baseline: TextBaseline.alphabetic,
        alignment: PlaceholderAlignment.baseline,
        child: Builder(builder: (context) => child));
  }

  TextSpan _buildChannel(MentionEmbed embed) {
    final match = TextEntity.channelLinkPattern.firstMatch(embed.id);
    final id = match.group(1);
    final channel = Db.channelBox.get(id);
    return TextSpan(
      text: " #${channel?.name ?? "尚未加入该频道".tr} ",
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
        child = Text(
          '[图片]',
          style: _bodyStyle,
        );
        break;
      case 'video':
        child = Text(
          '[视频]',
          style: _bodyStyle,
        );
        break;
      case 'divider':
        child = sizedBox;
        break;
      default:
        child = sizedBox;
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  Document ignoreEmptyLineAtEnd(Document doc) {
    // 删除document尾部换行
    final originDoc = Document.fromDelta(doc.toDelta());
    final originDelta = originDoc.toDelta();
    final lastOperation = originDelta.last;
    if (lastOperation.value is String &&
        // h1、h2、h3有对应的attributes，需加判断
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

    /// 去掉文字的attr
    final newJson = originDoc.toDelta().toJson();
    for (final json in newJson) {
      final insert = json['insert'];
      final attributes = json['attributes'];
      if (insert != null && insert is String && attributes != null) {
        if (attributes is Map &&
            (attributes.containsKey('at') ||
                attributes.containsKey('channel'))) {
          continue;
        }
        json['attributes'] = null;
      }
    }
    final newDoc = Document.fromJson(newJson);

    return newDoc;
  }
}
