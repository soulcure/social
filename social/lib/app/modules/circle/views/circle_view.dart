import 'package:flutter/material.dart';
import 'package:im/app/modules/circle/views/landscape/landscape_circle_main_page.dart';
import 'package:im/app/modules/circle/views/portrait/portrait_circle_main_page.dart';
import 'package:im/utils/orientation_util.dart';

class CircleView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OrientationUtil.portrait
        ? const PortraitCircleMainPage()
        : const LandscapeCircleMainPage();
  }
}
