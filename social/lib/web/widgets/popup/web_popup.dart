import 'dart:async';

import 'package:flutter/material.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/mouse_hover_builder.dart';
import 'package:im/widgets/super_tooltip.dart';

class SelectionAction {
  final IconData icon;
  final String content;
  final int index;
  final TextStyle textStyle;

  const SelectionAction(
    this.icon,
    this.content,
    this.index, {
    this.textStyle,
  });
}

Future showWebSelectionPopup(
  BuildContext context, {
  List<String> items,
  List<SelectionAction> actions,
  double width = 118,
  double offsetX = 0,
  double offsetY = 0,
  double minimumOutSidePadding = 8,
  EdgeInsets padding = EdgeInsets.zero,
  TooltipDirection popupDirection = TooltipDirection.bottom,
}) {
  final completer = Completer();
  int _index;
  SuperTooltip _toolTop;
  _toolTop = SuperTooltip(
    arrowBaseWidth: 0,
    arrowLength: 0,
    arrowTipDistance: 0,
    borderWidth: 1,
    borderColor: const Color(0xff717D8D).withOpacity(0),
    shadowColor: const Color(0xff717D8D).withOpacity(0.1),
    outsideBackgroundColor: Colors.transparent,
    borderRadius: 4,
    onClose: () => completer.complete(Future.value(_index)),
    minimumOutSidePadding: minimumOutSidePadding,
    offsetX: offsetX,
    offsetY: offsetY,
    content: SizedBox(
        width: width,
        // height: height ?? (length * 32.0),
        child: WebSelectionPopup(
          items: items,
          actions: actions,
          padding: padding,
          callBack: (index) {
            _index = index;
//            completer.complete(Future.value(index));
            _toolTop.close();
          },
        )),
    popupDirection: popupDirection,
  );
  _toolTop.show(context);
  return completer.future;
}

class WebSelectionPopup extends StatefulWidget {
  /// items or actions 取一个， 优先取items
  final List<String> items;
  // item3 是索引，不为空则返回，为空则返回action在list的索引
  final List<SelectionAction> actions;
  final Function(int) callBack;
  final EdgeInsets padding;

  const WebSelectionPopup(
      {this.items,
      this.actions,
      this.callBack,
      this.padding = EdgeInsets.zero});

  @override
  _WebSelectionPopupState createState() => _WebSelectionPopupState();
}

class _WebSelectionPopupState extends State<WebSelectionPopup> {
  Widget _item(String text, VoidCallback callback,
      {IconData icon, TextStyle style}) {
    return MouseHoverBuilder(
      builder: (context, selected) {
        return FadeBackgroundButton(
          tapDownBackgroundColor: Theme.of(context).disabledColor,
          onTap: callback,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: selected
                ? const Color(0xffd3d7dc)
                : Theme.of(context).backgroundColor,
            child: Row(
              children: [
                sizeWidth8,
                if (icon != null)
                  Icon(
                    icon,
                    size: 16,
                    color: style?.color,
                  ),
                if (icon != null) sizeWidth10,
                Text(
                  text,
                  style: style ??
                      Theme.of(context)
                          .textTheme
                          .bodyText2
                          .copyWith(fontSize: 12),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildList() {
    final List<Widget> ret = [];
    if (widget.items != null) {
      for (int i = 0; i < widget.items.length; i++) {
        ret.add(_item(widget.items[i], () {
          widget.callBack(i);
        }));
      }
    } else if (widget.actions != null) {
      for (int i = 0; i < widget.actions.length; i++) {
        ret.add(_item(widget.actions[i].content, () {
          widget.callBack(widget.actions[i].index ?? i);
        }, icon: widget.actions[i].icon, style: widget.actions[i].textStyle));
      }
    }
    return ret;
  }

  @override
  Widget build(BuildContext context) {
    if ((widget.items != null && widget.items.length > 9) ||
        (widget.actions != null && widget.actions.length > 9))
      return Padding(
        padding: widget.padding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView(
            children: _buildList(),
          ),
        ),
      );
    else
      return Padding(
        padding: widget.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildList(),
        ),
      );
  }
}
