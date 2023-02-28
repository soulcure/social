import 'package:flutter/rendering.dart';

import 'editable_box.dart';
import 'package:im/utils/utils.dart';

/// Proxy to an arbitrary embeddable [RenderBox].
///
/// Computes necessary editing metrics based on the dimensions of the child
/// render box.
class RenderEmbedProxy extends RenderProxyBox implements RenderContentProxyBox {
  // 修改，添加embedSize参数，有此参数则优先作为渲染宽高
  Size embedSize;
  RenderEmbedProxy({RenderBox child, this.embedSize}) : super(child);

  double get width => embedSize == null
      ? size.width
      : getImageSize(embedSize.width, embedSize.height).item1;
  double get height => embedSize == null
      ? size.height
      : getImageSize(embedSize.width, embedSize.height).item2;

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) {
    if (selection.isCollapsed) {
      final left = selection.extentOffset == 0 ? 0.0 : width;
      final right = selection.extentOffset == 0 ? 0.0 : width;
      return <TextBox>[
        TextBox.fromLTRBD(left, 0.0, right, height, TextDirection.ltr)
      ];
    }
    return <TextBox>[
      TextBox.fromLTRBD(0.0, 0.0, width, height, TextDirection.ltr)
    ];
  }

  @override
  double getFullHeightForCaret(TextPosition position) {
    return preferredLineHeight;
  }

  @override
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    assert(position.offset == 0 || position.offset == 1);
    return (position.offset == 0) ? Offset(-1, 0) : Offset(width, 0.0);
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    // 修改，修复点击embedObject右侧聚焦到左边的bug
    final position = (offset.dx > width / 2) ? 1 : 0;
    return TextPosition(offset: position);
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    return TextRange(start: 0, end: 1);
  }

  @override
  double get preferredLineHeight => size.height;
}
