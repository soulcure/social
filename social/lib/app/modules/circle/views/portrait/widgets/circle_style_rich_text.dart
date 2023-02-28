import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';

///60圈子主题样式富文本
class CircleStyleRichText extends StatefulWidget {
  const CircleStyleRichText({
    Key key,
    @required this.content,
    @required this.guildId,
    this.maxHeight = double.infinity,
    this.fontWeigh = FontWeight.w500,
    this.padding = EdgeInsets.zero,
    this.maxLines = 5,
    this.fontSize = 14,
    this.fontHeight = 1.25,
    this.formSearch = false,
    this.searchKey = '',
  }) : super(key: key);
  final String content;
  final double maxHeight;
  final EdgeInsets padding;
  final double fontSize;
  final double fontHeight;
  final FontWeight fontWeigh;
  final int maxLines;
  final String guildId;
  final bool formSearch;
  final String searchKey;

  @override
  State<CircleStyleRichText> createState() => _CircleStyleRichTextState();
}

class _CircleStyleRichTextState extends State<CircleStyleRichText> {
  @override
  Widget build(BuildContext context) {
    final _textStyle = appThemeData.textTheme.bodyText2.copyWith(
      fontSize: widget.fontSize,
      height: widget.fontHeight,
      fontWeight: widget.fontWeigh,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: Padding(
        padding: widget.padding,
        child: Stack(
          children: [
            ParsedText(
              style: _textStyle,
              text: '${widget.content}$nullChar',
              maxLines: widget.maxLines,
              regexOptions: const RegexOptions(caseSensitive: false),
              parse: [
                ParsedTextExtension.matchCusEmoText(context, widget.fontSize),
                ParsedTextExtension.matchAtText(
                  context,
                  textStyle: _textStyle,
                  guildId: widget.guildId,
                  plainTextStyle: true,
                  tapToShowUserInfo: false,
                ),
                ParsedTextExtension.matchChannelLink(
                  context,
                  textStyle: _textStyle,
                  tapToJumpChannel: false,
                  hasBgColor: false,
                ),
                if (widget.formSearch)
                  ParsedTextExtension.matchSearchKey(
                    context,
                    widget.searchKey,
                    _textStyle.copyWith(color: appThemeData.primaryColor),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
