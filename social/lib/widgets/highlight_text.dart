import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';

/// 截取文本的方向，左边或右边
enum TruncateDirection { left, right }

/// 单行展示包含特定关键字的文本的组件，经过计算竟可能将关键字居中，并高亮展示。如果关键字左侧或
/// 右侧的文本超出组件的区域，则采用...截取
class HighlightText extends StatefulWidget {
  /// 要展示的完整文本
  final String text;

  /// 关键字
  final String keyword;

  /// 关键字样式
  final TextStyle highlightStyle;

  /// 非关键字文本的样式
  final TextStyle style;

  final int maxLines;

  const HighlightText(
    this.text, {
    Key key,
    @required this.keyword,
    this.highlightStyle,
    this.style,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  _HighlightTextState createState() => _HighlightTextState();
}

class _HighlightTextState extends State<HighlightText> {
  /// 是否有匹配到关键字
  bool _isMatch;

  /// 关键字
  String _keyword;

  /// 关键字左侧文本
  String _leftText;

  /// 关键字右侧文本
  String _rightText;

  /// 构造Paragraph，用于测量文本宽度
  ParagraphBuilder _paragraphBuilder;

  /// 超出范围文本的截断字符（...字符）
  final String _ellipsisChar = '\u2026';

  /// 拆分出关键字左侧和右侧的文本
  void _splitText() {
    _keyword = widget.keyword;
    if (_keyword == null || _keyword.isEmpty) {
      // 关键字为空
      _isMatch = false;
      _clear();
      return;
    }

    final _text = widget.text.replaceAll('\n', ' ');
    final RegExp pattern = RegExp(_keyword, caseSensitive: false);
    final m = pattern.firstMatch(_text);

    // 没有匹配到关键字
    if (m == null) {
      _isMatch = false;
      _clear();
      return;
    }
    _keyword = m.group(0);

    final keywordIndex = m.start;
    // 匹配到关键字
    _isMatch = true;
    _leftText = _text.substring(0, keywordIndex);
    _rightText = _text.substring(keywordIndex + _keyword.length);
  }

  TextStyle _getTextStyle() {
    return DefaultTextStyle.of(context).style.merge(widget.style);
  }

  TextStyle _getHighlightStyle() {
    return DefaultTextStyle.of(context).style.merge(widget.highlightStyle);
  }

  /// 清空measure时缓存的数据
  void _clear() {
    _leftText = null;
    _rightText = null;
    _paragraphBuilder = null;
  }

  /// 测量关键字左，右侧文本的宽度，经过裁剪使关键字居中
  /// maxConstrainWidth: 此组件的最大宽度
  void _measure(double maxConstrainWidth) {
    // 未匹配到关键字，不进行测量
    if (!_isMatch) return;

    final _keywordW = _getIntrinsicWidth(
      _getParagraph(
        _keyword,
        textStyle: widget.highlightStyle,
      ),
    );
    if (_keywordW >= maxConstrainWidth) {
      // 关键字宽度超过控件最大宽度，忽略左，右侧的文本
      _leftText = null;
      _rightText = null;
      // 截取关键字
      _truncateKeyword(maxConstrainWidth);
    }

    // 如果关键字居中展示，单边剩余的宽度（左侧跟右侧的剩余宽度相等）
    var d = ((maxConstrainWidth - _keywordW) / 2).ceilToDouble();
    // 如果关键字比约束宽度长，但边剩余宽度为0
    if (d < 0) d = 0;
    // 左边文字，右边文字的宽
    double _leftTxtW, _rightTxtW;

    if (_leftText != null) {
      // 测量左边文字的实际宽度
      _leftTxtW = _getIntrinsicWidth(_getParagraph(_leftText));
    } else {
      _leftTxtW = 0;
    }
    if (_rightText != null) {
      // 测量右边文字的实际宽度
      _rightTxtW = _getIntrinsicWidth(_getParagraph(_rightText));
    } else {
      _rightTxtW = 0;
    }

    // 左右两侧的文本都没有超过单边剩余宽度，两侧都不需要截取
    if (_leftTxtW <= d && _rightTxtW <= d) {
      return;
    }

    // 左右两侧的文本都超过单边剩余宽度，两侧都要截取
    if (_leftTxtW > d && _rightTxtW > d) {
      // 截取左侧文本
      _leftTxtW = _truncateLeftText(d);
      // 截取右侧文本
      _truncateRightText(maxConstrainWidth - _keywordW - _leftTxtW);
      return;
    }

    // 只有左侧文字超过单边剩余宽度，只截取左侧
    if (_leftTxtW > d) {
      // 左侧文本最大宽度为控件最大宽度减去关键字宽度和右侧文本宽度
      final leftRemain = maxConstrainWidth - _keywordW - _rightTxtW;
      // 截取左侧文本
      _truncateLeftText(leftRemain);
      return;
    }

    // 只有右边文字超过单边剩余宽度，只截取右侧
    if (_rightTxtW > d) {
      // 右侧文字约束宽度为控件宽度减去关键字和左侧文字宽度
      _rightTxtW = maxConstrainWidth - _keywordW - _leftTxtW;
      _truncateRightText(_rightTxtW);
      return;
    }
  }

  /// 根据宽度width截取文本，返回截取后的文本
  ///
  /// 截取右侧文本可以使用：TextOverFlow.ellipsis，但此属性有个问题，当一个长单词或数字
  /// 超出范围后，整个单词会被截掉，在右侧留下一个空缺，所以本方法采用先测量再截取
  /// 实现截取左侧文本，必须通过测量来决定截取的位置
  ///
  /// @param text: 要截取的文本
  /// @param width: 截取后的最大宽度
  /// @param direction: 截取的方向，左侧或右侧
  TruncateTextResult _truncateText(
    String text,
    double width, {
    TruncateDirection direction = TruncateDirection.right,
  }) {
    Paragraph paragraph;
    if (direction == TruncateDirection.left) {
      // 截取左侧文本时，先将左侧文本反转，用于后续测量
      final reversedText = text.characters.toList().reversed.join('');
      paragraph = _getParagraph(reversedText);
    } else {
      paragraph = _getParagraph(text);
    }
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    // 获得约束宽度内的最后一个字符的位置
    final position =
        paragraph.getPositionForOffset(Offset(width, double.infinity)).offset;

    try {
      // 截取文本，并在末尾追加...，返回新文本的宽度
      if (direction == TruncateDirection.left)
        // 截取左侧文本
        text = _ellipsisChar +
            text
                .substring(text.length - position)
                .characters
                .skip(1)
                .toString();
      else {
        // 截取右侧文本
        text = text.substring(0, position).characters.skipLast(1).toString() +
            _ellipsisChar;
      }
    } catch (e) {
      // debugPrint('HighlightText error: $e');
    }
    var truncateW = _getIntrinsicWidth(_getParagraph(text));
    // 如果截取后的文本宽度大于约束宽度，则再截取一个字符，直到满足约束
    int count = 1;
    while (truncateW > width) {
      if (count++ >= 3) break;
      if (direction == TruncateDirection.left) {
        text = _ellipsisChar + text.characters.skip(2).toString();
      } else {
        text = text.characters.skipLast(2).toString() + _ellipsisChar;
      }
      truncateW = _getIntrinsicWidth(_getParagraph(text));
    }

    // 返回截取后满足约束宽度的文本
    return TruncateTextResult(text, truncateW);
  }

  /// 截取关键字左侧文本，返回截取后的宽度
  double _truncateLeftText(double width) {
    final res = _truncateText(
      _leftText,
      width,
      direction: TruncateDirection.left,
    );
    _leftText = res.text;
    return res.width;
  }

  /// 截取关键字右侧文本，返回截取后的宽度
  double _truncateRightText(double width) {
    final res = _truncateText(_rightText, width);
    _rightText = res.text;
    return res.width;
  }

  /// 截取关键字
  void _truncateKeyword(double width) {
    _keyword = _truncateText(_keyword, width).text;
  }

  /// 不限制宽度的情况下，获取文字渲染的实际宽度
  double _getIntrinsicWidth(Paragraph paragraph) {
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    return paragraph.maxIntrinsicWidth.ceilToDouble();
  }

  Paragraph _getParagraph(String text, {TextStyle textStyle}) {
    final _style = textStyle ?? _getTextStyle();
    _paragraphBuilder ??= ParagraphBuilder(
      _style.getParagraphStyle(maxLines: 1),
    );
    final textSpan = TextSpan(text: text);
    textSpan.build(_paragraphBuilder);
    return _paragraphBuilder.build();
  }

  @override
  void initState() {
    super.initState();
    _splitText();
  }

  @override
  void didUpdateWidget(covariant HighlightText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _splitText();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMatch) {
      // 未匹配到关键字，原样输出文本
      return Text(
        widget.text,
        style: _getTextStyle(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return LayoutBuilder(
      builder: (context, constraint) {
        ///NOTE fixme: widget.maxLines>1 时候，_measure()方法会导致ParsedText无法换行
        if (widget.maxLines == 1) _measure(constraint.maxWidth);
        return ParsedText(
          text: (_leftText ?? '') + _keyword + (_rightText ?? ''),
          style: _getTextStyle(),
          maxLines: widget.maxLines,
          overflow: TextOverflow.ellipsis,
          regexOptions: const RegexOptions(caseSensitive: false),
          parse: [
            ParsedTextExtension.matchSearchKey(
                context, _keyword, _getHighlightStyle()),
          ],
        );
      },
    );
  }
}

// 截取文本的结果
class TruncateTextResult {
  final String text;
  final double width;

  TruncateTextResult(this.text, this.width);
}
