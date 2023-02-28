import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/web/widgets/web_form_detector/web_form_detector.dart';
import 'package:im/web/widgets/web_form_detector/web_form_detector_model.dart';
import 'package:provider/provider.dart';

class WebFormTabItem extends StatefulWidget {
  final bool isTab;
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final int index;
  final Widget child;

  // tab构造函数
  const WebFormTabItem({
    @required this.title,
    @required this.index,
    this.icon,
    this.onTap,
    this.child,
  }) : isTab = true;

  // tab标题构造函数，只需传title，其余不需要传
  const WebFormTabItem.title(
      {@required this.title, this.index, this.icon, this.child, this.onTap})
      : isTab = false;

  const WebFormTabItem.builder({
    this.child,
    this.onTap,
  })  : isTab = false,
        title = null,
        icon = null,
        index = null;

  @override
  _WebFormTabItemState createState() => _WebFormTabItemState();
}

class _WebFormTabItemState extends State<WebFormTabItem> {
  static const double _paddingLeft = 18;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _tabIndex =
        Provider.of<WebFormDetectorModel>(context, listen: false).tabIndex;
    if (widget.child != null)
      return MouseRegion(
        cursor: widget.onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: widget.child,
        ),
      );

    if (!widget.isTab)
      return Padding(
        padding: const EdgeInsets.only(left: _paddingLeft, bottom: 10),
        child: Text(
          widget.title ?? '',
          style:
              TextStyle(fontSize: 12, color: CustomColor(context).disableColor),
        ),
      );
    return WebFormDetector(
        onTap: () {
          _tabIndex.value = widget.index;
          Provider.of<WebFormDetectorModel>(context, listen: false)
              .setCallback();
        },
        child: ValueListenableBuilder(
            valueListenable: _tabIndex,
            builder: (context, tabIndex, child) {
              final active = tabIndex == widget.index;
              final color = active
                  ? Theme.of(context).textTheme.bodyText2.color
                  : CustomColor(context).disableColor;
              return Container(
                  alignment: Alignment.center,
                  height: 40,
                  padding: const EdgeInsets.only(left: _paddingLeft),
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(4),
                          topLeft: Radius.circular(4)),
                      color: active
                          ? Colors.white
                          : Theme.of(context).scaffoldBackgroundColor),
                  child: Row(
                    children: [
                      Icon(
                        widget.icon,
                        size: 18,
                        color: color,
                      ),
                      sizeWidth8,
                      Text(widget.title ?? '',
                          style: TextStyle(fontSize: 16, color: color))
                    ],
                  ));
            }));
  }
}
