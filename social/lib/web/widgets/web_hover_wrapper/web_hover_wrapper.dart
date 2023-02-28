import 'package:flutter/material.dart';
import 'package:im/icon_font.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/web/widgets/popup/web_popup.dart';
import 'package:im/widgets/mouse_hover_builder.dart';

class WebHoverWrapper extends StatefulWidget {
  final Widget Function(BuildContext, bool) builder;
  final List<IconData> emojis;
  final List<IconData> hoverEmojis;
  final List<String> extendActions;

  /// emoji 点击事件 0..<n
  /// extend 点击事件 10..<10+n
  final Function(int) callback;

  /// 距离右上角的位置
  final EdgeInsets postion;

  const WebHoverWrapper({
    this.builder,
    this.emojis,
    this.hoverEmojis,
    this.extendActions = const [],
    this.callback,
    this.postion = const EdgeInsets.only(right: 60, top: 8),
  });

  @override
  _WebHoverWrapperState createState() => _WebHoverWrapperState();
}

class _WebHoverWrapperState extends State<WebHoverWrapper> {
  final ValueNotifier _enterValue = ValueNotifier(false);
  final ValueNotifier _selectMoreValue = ValueNotifier(false);

  Widget _buildItem(BuildContext context, IconData data, VoidCallback callback,
      {IconData hoverData, bool selected = false}) {
    return GestureDetector(
      onTap: callback,
      child: MouseHoverBuilder(
        builder: (context, hover) {
          final color = hoverData != null && hover
              ? Theme.of(context).primaryColor
              : (selected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).iconTheme.color);
          return Container(
            width: 32,
            height: 32,
            color: Theme.of(context).backgroundColor,
            alignment: Alignment.center,
            child: Icon(
              hover ? (hoverData ?? data) : data,
              size: 16,
              color: color,
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildList() {
    final List<Widget> ret = [];
    for (int i = 0; i < widget.emojis.length; i++) {
      final hoverEmoji =
          widget.hoverEmojis == null ? null : widget.hoverEmojis[i];
      ret.add(Padding(
        padding: EdgeInsets.only(left: i > 0 ? 1 : 0),
        child: _buildItem(context, widget.emojis[i], () => widget.callback(i),
            hoverData: hoverEmoji),
      ));
    }
    if (widget.extendActions.isNotEmpty) {
      final child = ValueListenableBuilder(
          valueListenable: _selectMoreValue,
          builder: (context, selected, child) {
            return _buildItem(context, IconFont.buffMoreHorizontal, () async {
              _selectMoreValue.value = true;
              final res = await showWebSelectionPopup(context,
                  items: widget.extendActions, offsetY: 18);
              _selectMoreValue.value = false;
              widget.callback(10 + res);
            }, selected: selected);
          });
      ret.add(Padding(
        padding: const EdgeInsets.only(left: 1),
        child: child,
      ));
    }
    return ret;
  }

  @override
  Widget build(BuildContext context) {
    if (OrientationUtil.portrait) return widget.builder(context, false);

    return MouseRegion(
      onEnter: (_) {
        _enterValue.value = true;
      },
      onExit: (_) {
        if (!_selectMoreValue.value) _enterValue.value = false;
      },
      child: ValueListenableBuilder(
        valueListenable: _enterValue,
        builder: (context, value, child) {
          return Stack(
            children: [
              widget.builder(context, value),
              if (value)
                Positioned(
                  right: widget.postion.right,
                  top: widget.postion.top,
                  child: Row(
                    children: _buildList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
