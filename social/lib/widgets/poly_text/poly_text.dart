import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_quill/models/documents/attribute.dart';
import 'package:flutter_quill/models/documents/document.dart';
import 'package:flutter_quill/models/documents/nodes/block.dart';
import 'package:flutter_quill/models/documents/nodes/leaf.dart';
import 'package:flutter_quill/models/documents/nodes/line.dart';
import 'package:flutter_quill/models/documents/style.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/themes/default_theme.dart';
import 'package:tuple/tuple.dart';

import 'widgets/default_styles.dart';
import 'widgets/editor.dart';
import 'widgets/text_block.dart';
import 'widgets/text_line.dart';

/// 富文本渲染器，使用flutter_quill中的models
class PolyText extends StatefulWidget {
  const PolyText({
    Key key,
    this.document,
    this.baseStyle,
    this.embedBuilder,
    this.mentionBuilder,
    this.quoteVerticalSpacing = 0,
    this.codeVerticalSpacing = 0,
    this.paragraphHeight = 1.25,
    this.refererChannelSource,
  }) : super(key: key);

  final Document document;
  final TextStyle baseStyle;
  final EmbedBuilder embedBuilder;
  final double quoteVerticalSpacing;
  final double codeVerticalSpacing;
  final RefererChannelSource refererChannelSource;

  /// 内容的行高
  final double paragraphHeight;

  // 修改，添加mention builder
  final InlineSpan Function(Embed) mentionBuilder;

  @override
  State<StatefulWidget> createState() => PolyTextState();
}

class PolyTextState extends State<PolyText>
    with WidgetsBindingObserver, TickerProviderStateMixin<PolyText> {
  final GlobalKey _editorKey = GlobalKey();

  DefaultStyles _styles;

  TextDirection get _textDirection => Directionality.of(context);

  DefaultStyles getDefaultStyles(TextStyle baseStyle) {
    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        baseStyle.copyWith(height: widget.paragraphHeight),
        const Tuple2(0, 0),
        const Tuple2(0, 0),
        null,
      ),
      h1: DefaultTextBlockStyle(
          baseStyle.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          const Tuple2(0, 0),
          const Tuple2(0, 0),
          null),
      h2: DefaultTextBlockStyle(
          baseStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          const Tuple2(0, 0),
          const Tuple2(0, 0),
          null),
      h3: DefaultTextBlockStyle(
          baseStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          const Tuple2(0, 0),
          const Tuple2(0, 0),
          null),
      leading: DefaultTextBlockStyle(
        baseStyle.copyWith(fontSize: 16, height: 1.5),
        null,
        null,
        null,
      ),
      quote: DefaultTextBlockStyle(
        const TextStyle(fontSize: 16, color: Color(0xFF646A73), height: 1.5),
        Tuple2(widget.quoteVerticalSpacing, widget.quoteVerticalSpacing),
        const Tuple2(0, 0),
        BoxDecoration(
          border: Border(left: BorderSide(width: 2, color: primaryColor)),
        ),
      ),
      code: DefaultTextBlockStyle(
        const TextStyle(fontSize: 14, color: Color(0xFF646A73), height: 1.5),
        Tuple2(widget.codeVerticalSpacing, widget.codeVerticalSpacing),
        const Tuple2(0, 0),
        BoxDecoration(
          // color: Colors.grey.shade50,
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      lists: DefaultTextBlockStyle(
        baseStyle.copyWith(fontSize: 16, height: 1.5),
        const Tuple2(0, 0),
        const Tuple2(0, 0),
        null,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final parentStyles = PolyStyles.getStyles(context, true);
    final defaultStyles = DefaultStyles.getInstance(context);
    _styles = (parentStyles != null)
        ? defaultStyles.merge(parentStyles)
        : defaultStyles;

    final DefaultStyles customStyles = getDefaultStyles(widget.baseStyle);
    if (customStyles != null) {
      _styles = _styles.merge(customStyles);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.document == null || widget.document.isEmpty()) {
      return const SizedBox();
    }
    return PolyStyles(
      data: _styles,
      child: Container(
        constraints: const BoxConstraints(),
        child: _PolyWrap(
          key: _editorKey,
          document: widget.document,
          textDirection: _textDirection,
          children: _buildChildren(widget.document, context),
        ),
      ),
    );
  }

  List<Widget> _buildChildren(Document doc, BuildContext context) {
    final result = <Widget>[];
    for (final node in doc.root.children) {
      if (node is Line) {
        final editableTextLine = _getEditableTextLineFromNode(node, context);
        result.add(editableTextLine);
      } else if (node is Block) {
        final editableTextBlock = _getEditableTextBlockFromNode(node);
        result.add(editableTextBlock);
      } else {
        throw StateError('Unreachable.');
      }
    }
    return result;
  }

  TextSpan linkBuilder(String text, Style style, TextStyle textStyle,
      GestureRecognizer recognizer) {
    final Attribute link = style.attributes['link'];
    final String url = link?.value ?? '';
    if (url.isNotEmpty && url.startsWith('#')) {
      //# 选择圈子频道逻辑
      return TextSpan(
          text: text,
          style: textStyle.copyWith(decoration: TextDecoration.none),
          recognizer: recognizer);
    }
    return null;
  }

  EditableTextBlock _getEditableTextBlockFromNode(Block node) {
    final attrs = node.style.attributes;
    final indentLevelCounts = <int, int>{};
    return EditableTextBlock(
      block: node,
      textDirection: _textDirection,
      verticalSpacing: _getVerticalSpacingForBlock(node, _styles),
      styles: _styles,
      contentPadding: attrs.containsKey(Attribute.codeBlock.key)
          ? const EdgeInsets.all(8)
          : null,
      embedBuilder: widget.embedBuilder,
      mentionBuilder: widget.mentionBuilder,
      linkBuilder: linkBuilder,
      indentLevelCounts: indentLevelCounts,
    );
  }

  EditableTextLine _getEditableTextLineFromNode(
      Line node, BuildContext context) {
    final textLine = TextLine(
      line: node,
      textDirection: _textDirection,
      styles: _styles,
      embedBuilder: widget.embedBuilder,
      mentionBuilder: widget.mentionBuilder,
      linkBuilder: linkBuilder,
      refererChannelSource: widget.refererChannelSource,
    );
    final editableTextLine = EditableTextLine(
      line: node,
      body: textLine,
      indentWidth: 0,
      verticalSpacing: _getVerticalSpacingForLine(node, _styles),
      textDirection: _textDirection,
      devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
    );
    return editableTextLine;
  }

  Tuple2<double, double> _getVerticalSpacingForLine(
      Line line, DefaultStyles defaultStyles) {
    final attrs = line.style.attributes;
    if (attrs.containsKey(Attribute.header.key)) {
      final int level = attrs[Attribute.header.key].value;
      switch (level) {
        case 1:
          return defaultStyles.h1.verticalSpacing;
        case 2:
          return defaultStyles.h2.verticalSpacing;
        case 3:
          return defaultStyles.h3.verticalSpacing;
        default:
          return defaultStyles.h3.verticalSpacing;
      }
    }

    return defaultStyles.paragraph.verticalSpacing;
  }

  Tuple2<double, double> _getVerticalSpacingForBlock(
      Block node, DefaultStyles defaultStyles) {
    final attrs = node.style.attributes;
    if (attrs.containsKey(Attribute.blockQuote.key)) {
      return defaultStyles.quote.verticalSpacing;
    } else if (attrs.containsKey(Attribute.codeBlock.key)) {
      return defaultStyles.code.verticalSpacing;
    } else if (attrs.containsKey(Attribute.indent.key)) {
      return defaultStyles.indent.verticalSpacing;
    }
    return defaultStyles.lists.verticalSpacing;
  }
}

class _PolyWrap extends MultiChildRenderObjectWidget {
  _PolyWrap({
    Key key,
    List<Widget> children,
    this.document,
    this.textDirection,
    this.padding = EdgeInsets.zero,
  }) : super(key: key, children: children);

  final Document document;
  final TextDirection textDirection;
  final EdgeInsetsGeometry padding;

  @override
  RenderEditor createRenderObject(BuildContext context) {
    return RenderEditor(textDirection, padding, document);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderEditor renderObject) {
    renderObject
      ..document = document
      ..setContainer(document.root)
      ..textDirection = textDirection
      ..setPadding(padding);
  }
}
