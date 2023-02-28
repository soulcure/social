import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:im/utils/utils.dart';

class EmbedProxy extends SingleChildRenderObjectWidget {
  // 修改，添加embedSize参数，保存图片宽高
  final Size embedSize;

  const EmbedProxy(Widget child, {this.embedSize}) : super(child: child);

  @override
  RenderEmbedProxy createRenderObject(BuildContext context) =>
      RenderEmbedProxy(null, embedSize: embedSize);
}

class RenderEmbedProxy extends RenderProxyBox {
  // 修改，添加embedSize参数，有此参数则优先作为渲染宽高
  final Size embedSize;

  RenderEmbedProxy(RenderBox child, {this.embedSize}) : super(child);

  double get width => embedSize == null
      ? size.width
      : getImageSize(embedSize.width, embedSize.height).item1 as double;

  double get height => embedSize == null
      ? size.height
      : getImageSize(embedSize.width, embedSize.height).item2 as double;
}

class RichTextProxy extends SingleChildRenderObjectWidget {
  const RichTextProxy(
    RichText child,
    this.textStyle,
    this.textAlign,
    this.textDirection,
    this.textScaleFactor,
    this.locale,
    this.strutStyle,
    this.textWidthBasis,
    this.textHeightBehavior,
  ) : super(child: child);

  final TextStyle textStyle;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final double textScaleFactor;
  final Locale locale;
  final StrutStyle strutStyle;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior textHeightBehavior;

  @override
  RenderParagraphProxy createRenderObject(BuildContext context) {
    return RenderParagraphProxy(
        null,
        textStyle,
        textAlign,
        textDirection,
        textScaleFactor,
        strutStyle,
        locale,
        textWidthBasis,
        textHeightBehavior);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderParagraphProxy renderObject) {
    renderObject
      ..textStyle = textStyle
      ..textAlign = textAlign
      ..textDirection = textDirection
      ..textScaleFactor = textScaleFactor
      ..locale = locale
      ..strutStyle = strutStyle
      ..textWidthBasis = textWidthBasis
      ..textHeightBehavior = textHeightBehavior;
  }
}

class RenderParagraphProxy extends RenderProxyBox {
  RenderParagraphProxy(
    RenderParagraph child,
    TextStyle textStyle,
    TextAlign textAlign,
    TextDirection textDirection,
    double textScaleFactor,
    StrutStyle strutStyle,
    Locale locale,
    TextWidthBasis textWidthBasis,
    TextHeightBehavior textHeightBehavior,
  )   : _prototypePainter = TextPainter(
            text: TextSpan(text: ' ', style: textStyle),
            textAlign: textAlign,
            textDirection: textDirection,
            textScaleFactor: textScaleFactor,
            strutStyle: strutStyle,
            locale: locale,
            textWidthBasis: textWidthBasis,
            textHeightBehavior: textHeightBehavior),
        super(child);

  final TextPainter _prototypePainter;

  set textStyle(TextStyle value) {
    if (_prototypePainter.text.style == value) {
      return;
    }
    _prototypePainter.text = TextSpan(text: ' ', style: value);
    markNeedsLayout();
  }

  set textAlign(TextAlign value) {
    if (_prototypePainter.textAlign == value) {
      return;
    }
    _prototypePainter.textAlign = value;
    markNeedsLayout();
  }

  set textDirection(TextDirection value) {
    if (_prototypePainter.textDirection == value) {
      return;
    }
    _prototypePainter.textDirection = value;
    markNeedsLayout();
  }

  set textScaleFactor(double value) {
    if (_prototypePainter.textScaleFactor == value) {
      return;
    }
    _prototypePainter.textScaleFactor = value;
    markNeedsLayout();
  }

  set strutStyle(StrutStyle value) {
    if (_prototypePainter.strutStyle == value) {
      return;
    }
    _prototypePainter.strutStyle = value;
    markNeedsLayout();
  }

  set locale(Locale value) {
    if (_prototypePainter.locale == value) {
      return;
    }
    _prototypePainter.locale = value;
    markNeedsLayout();
  }

  set textWidthBasis(TextWidthBasis value) {
    if (_prototypePainter.textWidthBasis == value) {
      return;
    }
    _prototypePainter.textWidthBasis = value;
    markNeedsLayout();
  }

  set textHeightBehavior(TextHeightBehavior value) {
    if (_prototypePainter.textHeightBehavior == value) {
      return;
    }
    _prototypePainter.textHeightBehavior = value;
    markNeedsLayout();
  }

  @override
  RenderParagraph get child => super.child as RenderParagraph;

  @override
  void performLayout() {
    super.performLayout();
    _prototypePainter.layout(
        minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
  }
}
