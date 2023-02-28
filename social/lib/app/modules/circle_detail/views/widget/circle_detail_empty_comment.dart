import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:im/themes/const.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../../svg_icons.dart';

class CircleDetailEmptyComment extends StatelessWidget {
  const CircleDetailEmptyComment({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 40, top: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WebsafeSvg.asset(SvgIcons.nullState, height: 140),
            sizeHeight24,
            Text('快来进行回复吧'.tr,
                style: Get.textTheme.bodyText1.copyWith(fontSize: 14)),
          ],
        ),
      );
}
