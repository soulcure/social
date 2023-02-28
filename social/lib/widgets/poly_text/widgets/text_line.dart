import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_quill/models/documents/attribute.dart';
import 'package:flutter_quill/models/documents/nodes/container.dart'
    as container;
import 'package:flutter_quill/models/documents/nodes/embed.dart';
import 'package:flutter_quill/models/documents/nodes/leaf.dart' as leaf;
import 'package:flutter_quill/models/documents/nodes/leaf.dart';
import 'package:flutter_quill/models/documents/nodes/line.dart';
import 'package:flutter_quill/models/documents/nodes/node.dart';
import 'package:flutter_quill/models/documents/style.dart';
import 'package:flutter_quill/utils/color.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/tool/url_handler/link_handler_preset.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/emo_util.dart';
import 'package:tuple/tuple.dart';

import 'default_styles.dart';
import 'proxy.dart';

typedef EmbedBuilder = Widget Function(BuildContext context, Embed node);
typedef LinkSpanBuilder = TextSpan Function(String text, Style style,
    TextStyle textStyle, GestureRecognizer recognizer);

class TextLine extends StatelessWidget {
  const TextLine({
    this.line,
    this.embedBuilder,
    this.styles,
    this.textDirection,
    // 修改，添加mentionBuilder
    this.mentionBuilder,
    // 修改，添加是否可编辑参数，只有为false才显示emoji和url超链接
    // this.editable = true,
    this.linkBuilder,
    this.refererChannelSource,
    Key key,
  }) : super(key: key);

  final Line line;
  final TextDirection textDirection;
  final EmbedBuilder embedBuilder;
  final DefaultStyles styles;
  final RefererChannelSource refererChannelSource;

  final InlineSpan Function(Embed) mentionBuilder;
  final LinkSpanBuilder linkBuilder;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    // In rare circumstances, the line could contain an Embed & a Text of
    // newline, which is unexpected and probably we should find out the
    // root cause
    final childCount = line.childCount;
    if (line.hasEmbed || (childCount > 1 && line.children.first is Embed)) {
      final embed = line.children.first as Embed;
      //  修改，添加判断是否VideoEmbed或者ImageEmbed
      if (embed.value is VideoEmbed || embed.value is ImageEmbed) {
        // 修改，添加embedSize参数
        final width = (embed.value.data['width'] ?? 100).toDouble();
        final height = (embed.value.data['height'] ?? 100).toDouble();
        final size =
            (width != null && height != null) ? Size(width, height) : null;
        return EmbedProxy(embedBuilder(context, embed), embedSize: size);
      } else if (embed.value is BlockEmbed && embed.value.type == 'divider') {
        /// 修改，下划线回调
        return EmbedProxy(embedBuilder(context, embed));
      }
    }
    final textSpan = _buildTextSpan(context);
    final strutStyle = StrutStyle.fromTextStyle(textSpan.style);
    final textAlign = _getTextAlign();
    final child = RichText(
      text: textSpan,
      textAlign: textAlign,
      textDirection: textDirection,
      strutStyle: strutStyle,
      textScaleFactor: MediaQuery.textScaleFactorOf(context),
    );
    return RichTextProxy(
        child,
        textSpan.style,
        textAlign,
        textDirection,
        1,
        Localizations.localeOf(context),
        strutStyle,
        TextWidthBasis.parent,
        null);
  }

  TextAlign _getTextAlign() {
    final alignment = line.style.attributes[Attribute.align.key];
    if (alignment == Attribute.leftAlignment) {
      return TextAlign.left;
    } else if (alignment == Attribute.centerAlignment) {
      return TextAlign.center;
    } else if (alignment == Attribute.rightAlignment) {
      return TextAlign.right;
    } else if (alignment == Attribute.justifyAlignment) {
      return TextAlign.justify;
    }
    return TextAlign.start;
  }

  TextSpan _buildTextSpan(BuildContext context) {
    final defaultStyles = styles;
    // 修改，修复RichText 为空或者换行字符时高度为0，插入一个特殊空字符占位
    final isWrapLine = line.toPlainText() == '\n';
    final useTempLine = kIsWeb && isWrapLine;
    final newLine = Line();
    if (useTempLine) {
      newLine.insert(0, '\u{200B}', Style());
    }
    final List<InlineSpan> children = (useTempLine ? newLine : line)
        .children
        .map((node) => _getTextSpanFromNode(defaultStyles, node))
        .toList(growable: false);

    var textStyle = const TextStyle();

    if (line.style.containsKey(Attribute.placeholder.key)) {
      textStyle = defaultStyles.placeHolder.style;
      return TextSpan(children: children, style: textStyle);
    }

    final header = line.style.attributes[Attribute.header.key];
    final m = <Attribute, TextStyle>{
      Attribute.h1: defaultStyles.h1.style,
      Attribute.h2: defaultStyles.h2.style,
      Attribute.h3: defaultStyles.h3.style,
    };

    textStyle = textStyle.merge(m[header] ?? defaultStyles.paragraph.style);

    final block = line.style.getBlockExceptHeader();
    TextStyle toMerge;
    if (block == Attribute.blockQuote) {
      toMerge = defaultStyles.quote.style;
    } else if (block == Attribute.codeBlock) {
      toMerge = defaultStyles.code.style;
    } else if (block != null) {
      toMerge = defaultStyles.lists.style;
    }

    textStyle = textStyle.merge(toMerge);

    return TextSpan(children: children, style: textStyle);
  }

  InlineSpan _getTextSpanFromNode(DefaultStyles defaultStyles, Node node) {
    if (node is Embed) {
      if (node.value is MentionEmbed) {
        return mentionBuilder?.call(node) ??
            TextSpan(text: node.value.toString());
      } else {
        return const TextSpan(text: '');
      }
    }
    final textNode = node as leaf.Text;
    final style = textNode.style;
    var res = const TextStyle();
    final color = textNode.style.attributes[Attribute.color.key];

    <String, TextStyle>{
      Attribute.bold.key: defaultStyles.bold,
      Attribute.italic.key: defaultStyles.italic,
      Attribute.link.key: defaultStyles.link,
      Attribute.underline.key: defaultStyles.underline,
      Attribute.strikeThrough.key: defaultStyles.strikeThrough,
      // 修改
      Attribute.at.key: defaultStyles.at,
      Attribute.channel.key: defaultStyles.channel,
    }.forEach((k, s) {
      if (style.values.any((v) => v.key == k)) {
        if (k == Attribute.underline.key || k == Attribute.strikeThrough.key) {
          var textColor = defaultStyles.color;
          if (color?.value is String) {
            textColor = stringToColor(color?.value);
          }
          res = _merge(res.copyWith(decorationColor: textColor),
              s.copyWith(decorationColor: textColor));
        } else {
          res = _merge(res, s);
        }
      }
    });

    final font = textNode.style.attributes[Attribute.font.key];
    if (font != null && font.value != null) {
      res = res.merge(TextStyle(fontFamily: font.value));
    }

    final size = textNode.style.attributes[Attribute.size.key];
    if (size != null && size.value != null) {
      switch (size.value) {
        case 'small':
          res = res.merge(defaultStyles.sizeSmall);
          break;
        case 'large':
          res = res.merge(defaultStyles.sizeLarge);
          break;
        case 'huge':
          res = res.merge(defaultStyles.sizeHuge);
          break;
        default:
          final fontSize = double.tryParse(size.value);
          if (fontSize != null) {
            res = res.merge(TextStyle(fontSize: fontSize));
          } else {
            throw 'Invalid size ${size.value}';
          }
      }
    }

    if (color != null && color.value != null) {
      var textColor = defaultStyles.color;
      if (color.value is String) {
        textColor = stringToColor(color.value);
      }
      if (textColor != null) {
        res = res.merge(TextStyle(color: textColor));
      }
    }

    final background = textNode.style.attributes[Attribute.background.key];
    if (background != null && background.value != null) {
      final backgroundColor = stringToColor(background.value);
      res = res.merge(TextStyle(backgroundColor: backgroundColor));
    }
    // 添加url点击事件
    TapGestureRecognizer tapGestureRecognizer;
    try {
      final linkAttribuite = node.style.values
          .firstWhere((element) => element.key == Attribute.link.key);
      tapGestureRecognizer = TapGestureRecognizer()
        ..onTap = () {
          if (linkAttribuite.value is String)
            LinkHandlerPreset.common.handle(linkAttribuite.value,
                refererChannelSource: refererChannelSource);
        };
    } catch (e) {
      //
    }
    if (tapGestureRecognizer == null) {
      // if (editable)
      //   return TextSpan(text: textNode.value, style: res);
      // else
      return separateEmojiAndUrl(textNode.value, res);
    } else {
      final isLink =
          textNode.style.attributes.keys.contains(Attribute.link.key);
      TextSpan textSpan;
      if (isLink) {
        textSpan = linkBuilder?.call(
          textNode.value,
          textNode.style,
          res,
          tapGestureRecognizer,
        );
      }
      return textSpan ??
          TextSpan(
              text: textNode.value,
              style: res,
              recognizer: tapGestureRecognizer);
    }
  }

  TextSpan separateEmojiAndUrl(String text, TextStyle style) {
    final emojiSeparator = String.fromCharCode(0);
    // 匹配表情和url
    final newText = text.splitMapJoin(
        RegExp(
            r"\[.*?\]|(http(s)?):\/\/[(www\.)?a-zA-Z0-9@:._\+~#=-]{1,256}\.[a-z0-9]{2,6}\b([-a-zA-Z0-9!@:_\+.~#?&//=%,]*)"),
        onMatch: (m) => "$emojiSeparator${m.group(0)}$emojiSeparator",
        onNonMatch: (m) => m);
    final splits = newText.split(emojiSeparator);
    final List<InlineSpan> children = [];
    for (final e in splits) {
      if (e.isEmpty) continue;
      if (e[0] == '[' && e[e.length - 1] == ']') {
        final emojiName = e.substring(1, e.length - 1);
        if (EmoUtil.instance.allEmoMap[emojiName] != null && !kIsWeb) {
          children.add(WidgetSpan(
              child: Padding(
            padding: const EdgeInsets.all(2),
            child: EmoUtil.instance.getEmoIcon(emojiName, size: 17),
          )));
        } else {
          children.add(TextSpan(text: e, style: style));
        }
      } else if (e.startsWith('http')) {
        children.add(TextSpan(
            text: e,
            style: style.copyWith(color: primaryColor),
            recognizer: TapGestureRecognizer()
              ..onTap = () => LinkHandlerPreset.common
                  .handle(e, refererChannelSource: refererChannelSource)));
      } else {
        children.add(TextSpan(text: e, style: style));
      }
    }

    return TextSpan(children: children);
  }

  TextStyle _merge(TextStyle a, TextStyle b) {
    final decorations = <TextDecoration>[];
    if (a.decoration != null) {
      decorations.add(a.decoration);
    }
    if (b.decoration != null) {
      decorations.add(b.decoration);
    }
    return a.merge(b).apply(
        decoration: TextDecoration.combine(
            List.castFrom<dynamic, TextDecoration>(decorations)));
  }
}

class EditableTextLine extends RenderObjectWidget {
  const EditableTextLine({
    this.line,
    this.leading,
    this.body,
    this.indentWidth,
    this.verticalSpacing,
    this.textDirection,
    this.devicePixelRatio,
  });

  final Line line;
  final Widget leading;
  final Widget body;
  final double indentWidth;
  final Tuple2 verticalSpacing;
  final TextDirection textDirection;
  final double devicePixelRatio;

  @override
  RenderObjectElement createElement() {
    return _TextLineElement(this);
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderEditableTextLine(
        line, textDirection, devicePixelRatio, _getPadding());
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderEditableTextLine renderObject) {
    renderObject
      ..setLine(line)
      ..setPadding(_getPadding())
      ..setTextDirection(textDirection)
      ..setDevicePixelRatio(devicePixelRatio);
  }

  EdgeInsetsGeometry _getPadding() {
    return EdgeInsetsDirectional.only(
        start: indentWidth,
        top: verticalSpacing.item1,
        bottom: verticalSpacing.item2);
  }
}

enum TextLineSlot { LEADING, BODY }

class RenderEditableTextLine extends RenderBox {
  RenderEditableTextLine(
    this.line,
    this.textDirection,
    this.devicePixelRatio,
    this.padding,
  );

  RenderBox _leading;
  RenderBox _body;
  Line line;
  TextDirection textDirection;
  double devicePixelRatio;
  EdgeInsetsGeometry padding;

  EdgeInsets _resolvedPadding;
  final Map<TextLineSlot, RenderBox> children = <TextLineSlot, RenderBox>{};

  Iterable<RenderBox> get _children sync* {
    if (_leading != null) {
      yield _leading;
    }
    if (_body != null) {
      yield _body;
    }
  }

  void setDevicePixelRatio(double d) {
    if (devicePixelRatio == d) {
      return;
    }
    devicePixelRatio = d;
    markNeedsLayout();
  }

  void setTextDirection(TextDirection t) {
    if (textDirection == t) {
      return;
    }
    textDirection = t;
    _resolvedPadding = null;
    markNeedsLayout();
  }

  void setLine(Line l) {
    if (line == l) {
      return;
    }
    line = l;
    markNeedsLayout();
  }

  void setPadding(EdgeInsetsGeometry p) {
    assert(p.isNonNegative);
    if (padding == p) {
      return;
    }
    padding = p;
    _resolvedPadding = null;
    markNeedsLayout();
  }

  void setLeading(RenderBox l) {
    _leading = _updateChild(_leading, l, TextLineSlot.LEADING);
  }

  void setBody(RenderBox b) {
    _body = _updateChild(_body, b, TextLineSlot.BODY);
  }

  bool containsCursor() {
    return false;
  }

  RenderBox _updateChild(RenderBox old, RenderBox newChild, TextLineSlot slot) {
    if (old != null) {
      dropChild(old);
      children.remove(slot);
    }
    if (newChild != null) {
      children[slot] = newChild;
      adoptChild(newChild);
    }
    return newChild;
  }

  void _resolvePadding() {
    if (_resolvedPadding != null) {
      return;
    }
    _resolvedPadding = padding.resolve(textDirection);
    assert(_resolvedPadding.isNonNegative);
  }

  container.Container getContainer() {
    return line;
  }

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    for (final child in _children) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    for (final child in _children) {
      child.detach();
    }
  }

  @override
  void redepthChildren() {
    _children.forEach(redepthChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    _children.forEach(visitor);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final value = <DiagnosticsNode>[];
    void add(RenderBox child, String name) {
      if (child != null) {
        value.add(child.toDiagnosticsNode(name: name));
      }
    }

    add(_leading, 'leading');
    add(_body, 'body');
    return value;
  }

  @override
  bool get sizedByParent => false;

  @override
  double computeMinIntrinsicWidth(double height) {
    _resolvePadding();
    final horizontalPadding = _resolvedPadding.left + _resolvedPadding.right;
    final verticalPadding = _resolvedPadding.top + _resolvedPadding.bottom;
    final leadingWidth = _leading == null
        ? 0
        : _leading.getMinIntrinsicWidth(height - verticalPadding).ceil();
    final bodyWidth = _body == null
        ? 0
        : _body
            .getMinIntrinsicWidth(math.max(0, height - verticalPadding))
            .ceil();
    return horizontalPadding + leadingWidth + bodyWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _resolvePadding();
    final horizontalPadding = _resolvedPadding.left + _resolvedPadding.right;
    final verticalPadding = _resolvedPadding.top + _resolvedPadding.bottom;
    final leadingWidth = _leading == null
        ? 0
        : _leading.getMaxIntrinsicWidth(height - verticalPadding).ceil();
    final bodyWidth = _body == null
        ? 0
        : _body
            .getMaxIntrinsicWidth(math.max(0, height - verticalPadding))
            .ceil();
    return horizontalPadding + leadingWidth + bodyWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    _resolvePadding();
    final horizontalPadding = _resolvedPadding.left + _resolvedPadding.right;
    final verticalPadding = _resolvedPadding.top + _resolvedPadding.bottom;
    if (_body != null) {
      return _body
              .getMinIntrinsicHeight(math.max(0, width - horizontalPadding)) +
          verticalPadding;
    }
    return verticalPadding;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    _resolvePadding();
    final horizontalPadding = _resolvedPadding.left + _resolvedPadding.right;
    final verticalPadding = _resolvedPadding.top + _resolvedPadding.bottom;
    if (_body != null) {
      return _body
              .getMaxIntrinsicHeight(math.max(0, width - horizontalPadding)) +
          verticalPadding;
    }
    return verticalPadding;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    _resolvePadding();
    return _body.getDistanceToActualBaseline(baseline) + _resolvedPadding.top;
  }

  @override
  void performLayout() {
    final constraints = this.constraints;

    _resolvePadding();
    assert(_resolvedPadding != null);

    if (_body == null && _leading == null) {
      size = constraints.constrain(Size(
        _resolvedPadding.left + _resolvedPadding.right,
        _resolvedPadding.top + _resolvedPadding.bottom,
      ));
      return;
    }
    final innerConstraints = constraints.deflate(_resolvedPadding);

    final indentWidth = textDirection == TextDirection.ltr
        ? _resolvedPadding.left
        : _resolvedPadding.right;

    _body.layout(innerConstraints, parentUsesSize: true);
    (_body.parentData as BoxParentData).offset =
        Offset(_resolvedPadding.left, _resolvedPadding.top);

    if (_leading != null) {
      final leadingConstraints = innerConstraints.copyWith(
          minWidth: indentWidth,
          maxWidth: indentWidth,
          maxHeight: _body.size.height);
      _leading.layout(leadingConstraints, parentUsesSize: true);
      (_leading.parentData as BoxParentData).offset =
          Offset(0, _resolvedPadding.top);
    }

    size = constraints.constrain(Size(
      _resolvedPadding.left + _body.size.width + _resolvedPadding.right,
      _resolvedPadding.top + _body.size.height + _resolvedPadding.bottom,
    ));

    // _computeCaretPrototype();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_leading != null) {
      final parentData = _leading.parentData as BoxParentData;
      final effectiveOffset = offset + parentData.offset;
      context.paintChild(_leading, effectiveOffset);
    }

    if (_body != null) {
      final parentData = _body.parentData as BoxParentData;
      final effectiveOffset = offset + parentData.offset;

      context.paintChild(_body, effectiveOffset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    return _children.last.hitTest(result, position: position);
  }
}

class _TextLineElement extends RenderObjectElement {
  _TextLineElement(EditableTextLine line) : super(line);

  final Map<TextLineSlot, Element> _slotToChildren = <TextLineSlot, Element>{};

  @override
  EditableTextLine get widget => super.widget as EditableTextLine;

  @override
  RenderEditableTextLine get renderObject =>
      super.renderObject as RenderEditableTextLine;

  @override
  void visitChildren(ElementVisitor visitor) {
    _slotToChildren.values.forEach(visitor);
  }

  @override
  void forgetChild(Element child) {
    assert(_slotToChildren.containsValue(child));
    assert(child.slot is TextLineSlot);
    assert(_slotToChildren.containsKey(child.slot));
    _slotToChildren.remove(child.slot);
    super.forgetChild(child);
  }

  @override
  // ignore: avoid_annotating_with_dynamic
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _mountChild(widget.leading, TextLineSlot.LEADING);
    _mountChild(widget.body, TextLineSlot.BODY);
  }

  @override
  void update(EditableTextLine newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _updateChild(widget.leading, TextLineSlot.LEADING);
    _updateChild(widget.body, TextLineSlot.BODY);
  }

  @override
  void insertRenderObjectChild(RenderBox child, TextLineSlot slot) {
    // assert(child is RenderBox);
    _updateRenderObject(child, slot);
    assert(renderObject.children.keys.contains(slot));
  }

  @override
  void removeRenderObjectChild(RenderObject child, TextLineSlot slot) {
    assert(child is RenderBox);
    assert(renderObject.children[slot] == child);
    _updateRenderObject(null, slot);
    assert(!renderObject.children.keys.contains(slot));
  }

  @override
  void moveRenderObjectChild(
      RenderObject child,
      // ignore: avoid_annotating_with_dynamic
      dynamic oldSlot,
      // ignore: avoid_annotating_with_dynamic
      dynamic newSlot) {
    throw UnimplementedError();
  }

  void _mountChild(Widget widget, TextLineSlot slot) {
    final oldChild = _slotToChildren[slot];
    final newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      _slotToChildren.remove(slot);
    }
    if (newChild != null) {
      _slotToChildren[slot] = newChild;
    }
  }

  void _updateRenderObject(RenderBox child, TextLineSlot slot) {
    switch (slot) {
      case TextLineSlot.LEADING:
        renderObject.setLeading(child);
        break;
      case TextLineSlot.BODY:
        renderObject.setBody(child);
        break;
      default:
        throw UnimplementedError();
    }
  }

  void _updateChild(Widget widget, TextLineSlot slot) {
    final oldChild = _slotToChildren[slot];
    final newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      _slotToChildren.remove(slot);
    }
    if (newChild != null) {
      _slotToChildren[slot] = newChild;
    }
  }
}
