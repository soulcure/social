import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';

class SearchEdit extends StatefulWidget {
  final double? horizontal;
  final String? text;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final GestureTapCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool enable;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClean;

  const SearchEdit({
    this.horizontal,
    this.text,
    this.controller,
    this.focusNode,
    this.onTap,
    this.onChanged,
    this.autofocus = false,
    this.enable = true,
    this.onSubmitted,
    this.onClean,
  });

  @override
  State<SearchEdit> createState() => _SearchEditState();
}

class _SearchEditState extends State<SearchEdit> {
  Color? indicateColor;

  TextEditingController get controller {
    return widget.controller ?? TextEditingController();
  }

  @override
  void initState() {
    super.initState();
    indicateColor = const Color(0xff6179F2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: widget.horizontal ?? 12.px),
      padding: EdgeInsets.symmetric(horizontal: widget.horizontal ?? 12.px),
      decoration: BoxDecoration(
        color: const Color(0xffF5F5F8),
        borderRadius: BorderRadius.all(Radius.circular(18.px)),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/live/main/aid_search.png',
            width: 16.px,
            height: 16.px,
          ),
          Space(width: widget.horizontal == 16.px ? 8.px : 2.px),
          Expanded(
            child: TextField(
              onTap: () {
                if (widget.onTap != null) {
                  widget.onTap!();
                }
              },
              focusNode: widget.focusNode,
              controller: controller,
              cursorColor: indicateColor,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: widget.text,
                hintStyle:
                    TextStyle(color: const Color(0xff8F959E), fontSize: 16.px),
              ),
              style: TextStyle(color: const Color(0xff363940), fontSize: 16.px),
              onChanged: (v) {
                setState(() {});
                if (widget.onChanged != null) {
                  widget.onChanged!(v);
                }
              },
              onSubmitted: (v) {
                if (widget.onSubmitted != null) {
                  widget.onSubmitted!(v);
                }
              },
              enabled: widget.enable,
            ),
          ),
          if (strNoEmpty(controller.text))
            ClickEvent(
              onTap: () async {
                controller.clear();
                setState(() {});
                if (widget.onClean != null) {
                  widget.onClean!();
                }
              },
              child: Container(
                padding: EdgeInsets.only(bottom: 8.px, top: 8.px, left: 8.px),
                child: Image.asset(
                  'assets/live/main/goods_field_clean.png',
                  width: 16.px,
                  height: 16.px,
                ),
              ),
            )
        ],
      ),
    );
  }
}

class SearchCancelButton extends StatefulWidget {
  final FocusNode focusNode;
  final GestureTapCallback? onTap;

  const SearchCancelButton(this.focusNode, {this.onTap});

  @override
  _SearchCancelButtonState createState() => _SearchCancelButtonState();
}

// todo SearchCancelButton组件的代码尝试删除
class _SearchCancelButtonState extends State<SearchCancelButton> {
  ///  搜索的取消目前没有任何意义，可以去掉 直播UI验收11.16 - 飞书云文档
  ///  [2021 11.25]
  bool isCancelSearch = true;

  @override
  Widget build(BuildContext context) {
    if (isCancelSearch) {
      return Container();
    }
    if (widget.focusNode.hasFocus || widget.onTap != null) {
      return InkWell(
        onTap: () {
          if (widget.onTap != null) {
            widget.onTap!();
          } else {
            FocusScope.of(context).requestFocus(FocusNode());
            setState(() {});
          }
        },
        child: Padding(
          padding: EdgeInsets.only(right: 12.px),
          child: Text(
            '取消',
            style: TextStyle(color: const Color(0xff6179F2), fontSize: 16.px),
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}
