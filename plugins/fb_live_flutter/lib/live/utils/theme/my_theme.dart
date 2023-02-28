import 'package:flutter/material.dart';

class MyTheme {
  static const Color themeColor = Color(0xFF198CFE);
  static const Color themeSwitchColor = Color(0xFF198CFE);
  static const Color noActivityColor = Color(0xffDEE0E3);

  //按钮背景颜色
  static Color redColor = const Color(0xffF24848);
  static Color blueColor = const Color(0xFF198CFE);
  static Color blueOpacityColor = blueColor.withOpacity(0.49);
  static Color transparent = Colors.transparent;

  //按钮字颜色
  static Color blackColor = const Color(0xff17181A);

  //按钮字、背景颜色
  static Color whiteColor = Colors.white;

  static Border mainBottomBorder() {
    return Border(
      bottom: BorderSide(
          color: const Color(0xff8F959E).withOpacity(0.15), width: 0.5),
    );
  }
}
