import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';

typedef RichTextLayoutLinesCallback = void Function(int lines);

///60圈子主题样式富文本
class CircleVideoRichText extends StatefulWidget {
  const CircleVideoRichText({
    Key key,
    @required this.content,
    @required this.guildId,
    this.maxHeight = double.infinity,
    this.fontWeigh = FontWeight.w400,
    this.padding = EdgeInsets.zero,
    this.maxLines = 2,
    this.fontSize = 15,
    this.fontHeight = 1.25,
    this.richTextLayoutLinesCallback,
    this.showAll = false,
  }) : super(key: key);
  final String content;
  final double maxHeight;
  final EdgeInsets padding;
  final double fontSize;
  final double fontHeight;
  final FontWeight fontWeigh;
  final int maxLines;
  final String guildId;
  final RichTextLayoutLinesCallback richTextLayoutLinesCallback;
  final bool showAll;

  @override
  State<CircleVideoRichText> createState() => _CircleVideoRichTextState();
}

class _CircleVideoRichTextState extends State<CircleVideoRichText> {
  int lines = 0;

  @override
  Widget build(BuildContext context) {
    final _textStyle = appThemeData.textTheme.bodyText2.copyWith(
      fontSize: widget.fontSize,
      height: widget.fontHeight,
      fontWeight: widget.fontWeigh,
      color: Colors.white.withOpacity(.8),
    );
    final content =
        widget.showAll ? widget.content : widget.content.replaceAll('\n', ' ');
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: Padding(
        padding: widget.padding,
        child: ParsedText(
          style: _textStyle,
          text: '$content$nullChar',
          maxLines: widget.showAll ? null : 2,
          overflow: widget.showAll ? null : TextOverflow.ellipsis,
          regexOptions: const RegexOptions(caseSensitive: false),
          layoutCallback: (textPainter) {
            final lineMetrics = textPainter.computeLineMetrics();
            if (lines != lineMetrics.length) {
              lines = lineMetrics.length;
              widget.richTextLayoutLinesCallback?.call(lines);
            }
          },
          parse: [
            ParsedTextExtension.matchCusEmoText(context, widget.fontSize),
            ParsedTextExtension.matchAtText(
              context,
              textStyle: _textStyle.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              guildId: widget.guildId,
              plainTextStyle: true,
            ),
            ParsedTextExtension.matchChannelLink(
              context,
              textStyle: _textStyle,
              fromCircleJump: true,
              hasBgColor: false,
            ),
          ],
        ),
      ),
    );
  }
}
