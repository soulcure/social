import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/pages/create_room/widget_web/create_field_widget.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';

import 'detection_title_tip.dart';

class DetectionItem extends StatelessWidget {
  final Widget? centerW;
  final TextEditingController? controller;
  final String? title;
  final GestureTapCallback? onTap;
  final bool? isFail;
  final bool? isArrow;

  const DetectionItem({
    this.centerW,
    this.controller,
    this.title,
    this.onTap,
    this.isFail,
    this.isArrow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetectionTitleTip(title: title ?? 'title', isFail: isFail),
        Space(height: FrameSize.px(10)),
        if (centerW != null) centerW!,
        if (centerW != null) Space(height: FrameSize.px(10)),
        Container(
          margin: title != '扬声器'
              ? const EdgeInsets.only(left: 24)
              : const EdgeInsets.only(),
          child: CreateFieldWidget(
            hintText: '请选择$title',
            controller: controller,
            enable: false,
            onTap: onTap,
            isArrow: isArrow,
          ),
        ),
      ],
    );
  }
}
