import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:im/themes/custom_color.dart';

///Default Index data.
const List<String> INDEX_DATA_DEF = [
  "A",
  "B",
  "C",
  "D",
  "E",
  "F",
  "G",
  "H",
  "I",
  "J",
  "K",
  "L",
  "M",
  "N",
  "O",
  "P",
  "Q",
  "R",
  "S",
  "T",
  "U",
  "V",
  "W",
  "X",
  "Y",
  "Z",
  "#"
];

/// IndexBar.
class CustomIndexBar extends StatefulWidget {
  const CustomIndexBar(
      {this.data = INDEX_DATA_DEF,
      @required this.onTouch,
      this.width = 30,
      this.itemHeight = 16,
      this.color = Colors.transparent,
      this.textStyle = const TextStyle(fontSize: 12, color: Color(0xFF666666)),
      this.touchDownColor = const Color(0xffeeeeee),
      this.touchDownTextStyle =
          const TextStyle(fontSize: 12, color: Colors.black)});

  /// index data.
  final List<String> data;

  /// IndexBar width(def:30).
  final int width;

  /// IndexBar item height(def:16).
  final int itemHeight;

  /// Background color
  final Color color;

  /// IndexBar touch down color.
  final Color touchDownColor;

  /// IndexBar text style.
  final TextStyle textStyle;

  final TextStyle touchDownTextStyle;

  /// Item touch callback.
  final IndexBarTouchCallback onTouch;

  @override
  _SuspensionListViewIndexBarState createState() =>
      _SuspensionListViewIndexBarState();
}

class _SuspensionListViewIndexBarState extends State<CustomIndexBar> {
  bool _isTouchDown = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: _isTouchDown ? widget.touchDownColor : widget.color,
      width: widget.width.toDouble(),
      child: _IndexBar(
        data: widget.data,
        width: widget.width,
        itemHeight: widget.itemHeight,
        textStyle: widget.textStyle,
        touchDownTextStyle: widget.touchDownTextStyle,
        onTouch: (details) {
          if (widget.onTouch != null) {
            if (_isTouchDown != details.isTouchDown) {
              setState(() {
                _isTouchDown = details.isTouchDown;
              });
            }
            widget.onTouch(details);
          }
        },
      ),
    );
  }
}

/// Base IndexBar.
class _IndexBar extends StatefulWidget {
  /// index data.
  final List<String> data;

  /// IndexBar width(def:30).
  final int width;

  /// IndexBar item height(def:16).
  final int itemHeight;

  /// IndexBar text style.
  final TextStyle textStyle;

  final TextStyle touchDownTextStyle;

  /// Item touch callback.
  final IndexBarTouchCallback onTouch;

  const _IndexBar(
      {Key key,
      this.data = INDEX_DATA_DEF,
      @required this.onTouch,
      this.width = 30,
      this.itemHeight = 16,
      this.textStyle,
      this.touchDownTextStyle})
      : assert(onTouch != null),
        super(key: key);

  @override
  _CustomIndexBarState createState() => _CustomIndexBarState();
}

class _CustomIndexBarState extends State<_IndexBar> {
  final List<int> _indexSectionList = [];
  int _widgetTop = -1;
  int _lastIndex = 0;
  bool _widgetTopChange = false;
  final IndexBarDetails _indexModel = IndexBarDetails();

  /// get index.
  int _getIndex(int offset) {
    final length = _indexSectionList.length;
    for (int i = 0; i < length - 1; i++) {
      final int a = _indexSectionList[i];
      final int b = _indexSectionList[i + 1];
      if (offset >= a && offset < b) {
        return i;
      }
    }
    return -1;
  }

  void _init() {
    _widgetTopChange = true;
    _indexSectionList.clear();
    _indexSectionList.add(0);
    int tempHeight = 0;
    widget.data?.forEach((value) {
      tempHeight = tempHeight + widget.itemHeight;
      _indexSectionList.add(tempHeight);
    });
  }

  void _triggerTouchEvent() {
    if (widget.onTouch != null) {
      widget.onTouch(_indexModel);
    }
  }

  @override
  Widget build(BuildContext context) {
    TextStyle _style = widget.textStyle;
    if (_indexModel.isTouchDown == true) {
      _style = widget.touchDownTextStyle;
    }
    _init();

    final List<Widget> children = [];
    widget.data.forEach((v) {
      children.add(Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _indexModel.tag == v && _indexModel.isTouchDown
              ? CustomColor(context).backgroundColor4
              : Colors.transparent,
        ),
        width: widget.width.toDouble(),
        height: widget.itemHeight.toDouble(),
        child: Text(v, textAlign: TextAlign.center, style: _style),
      ));
    });

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragDown: (details) {
        if (_widgetTop == -1 || _widgetTopChange) {
          _widgetTopChange = false;
          final RenderBox box = context.findRenderObject();
          final Offset topLeftPosition = box.localToGlobal(Offset.zero);
          _widgetTop = topLeftPosition.dy.toInt();
        }
        final offset = details.globalPosition.dy.toInt() - _widgetTop;
        final index = _getIndex(offset);
        if (index != -1) {
          _lastIndex = index;
          _indexModel.position = index;
          _indexModel.tag = widget.data[index];
          _indexModel.isTouchDown = true;
          _triggerTouchEvent();
        }
      },
      onVerticalDragUpdate: (details) {
        final offset = details.globalPosition.dy.toInt() - _widgetTop;
        final index = _getIndex(offset);
        if (index != -1 && _lastIndex != index) {
          _lastIndex = index;
          _indexModel.position = index;
          _indexModel.tag = widget.data[index];
          _indexModel.isTouchDown = true;
          _triggerTouchEvent();
        }
      },
      onHorizontalDragUpdate: (details) {
        _indexModel.isTouchDown = false;
        _triggerTouchEvent();
      },
      onVerticalDragEnd: (details) {
        _indexModel.isTouchDown = false;
        _triggerTouchEvent();
      },
      onTapUp: (details) {
        _indexModel.isTouchDown = false;
        _triggerTouchEvent();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
