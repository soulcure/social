import 'dart:io';

import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/material.dart';

class PriceView extends StatelessWidget {
  final Color textColor;
  final String price;
  final bool isShowYuan;
  final double? fontSize;

  const PriceView(this.textColor, this.price,
      {this.isShowYuan = true, this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Padding(
          /// 【APP】￥和数字之间的间距太窄了
          /// [ ] 这个￥图标跟数字贴的太紧了 4 => 7
          padding: EdgeInsets.only(left: isShowYuan ? (fontSize! * 0.28) : 0),
          child: Text(
            price,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize ?? 16.px,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.fade,
          ),
        ),
        if (isShowYuan)
          Padding(
            padding: EdgeInsets.only(
                bottom: fontSize! * (Platform.isIOS ? 0.08 : 0.14)),
            child: Text(
              '¥ ',
              style: TextStyle(
                color: textColor,
                fontSize: fontSize != null ? fontSize! * 0.53 : 9.px,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
