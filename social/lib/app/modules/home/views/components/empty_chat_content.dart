import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/svg_icons.dart';
import 'package:im/widgets/svg_tip_widget.dart';

class EmptyChatContent extends StatelessWidget {
  const EmptyChatContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        top: false,
        left: false,
        right: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 64),
            child: SvgTipWidget(
              svgName: SvgIcons.nullState,
              text: '暂无聊天内容'.tr,
              textSize: 17,
            ),
          ),
        ));
  }
}
