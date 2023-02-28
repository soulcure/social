import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/*
* num扩展方法
* */
extension FrameSizeNum on num {
  double get px {
    return FrameSize.px(this);
  }
}

class FrameSize {
  FrameSize();

  static MediaQueryData mediaQuery = MediaQueryData.fromWindow(window);
  static final double _width = mediaQuery.size.width;
  static final double _height = mediaQuery.size.height;
  static final double _topBarH = mediaQuery.padding.top;
  static final double _botBarH = mediaQuery.padding.bottom;
  static final double _pixelRatio = mediaQuery.devicePixelRatio;
  static double? _ratio;

  static void init(int number) {
    final int uiWidth = number is int ? number : 375;
    _ratio = _width / uiWidth;
  }

  /// 适配方式：实际值 *（屏幕宽度 / 375【设计稿宽度】）
  static double px(num number) {
    if (kIsWeb) {
      return number.toDouble();
    }
    if (!(_ratio is double || _ratio is int)) {
      FrameSize.init(375);
    }

    return number * (_ratio ?? 0);
  }

  /*
  * 当横屏时获取的值还是竖屏的
  * */
  static double screenW() {
    return _width;
  }

  /*
  * 当横屏时获取的值还是竖屏的
  * */
  static double screenH() {
    return _height;
  }

  static bool isHorizontal() {
    return winWidth() > winHeight();
  }

  /*
  * 取宽高里面的最大值，
  * 如果宽大于高那就使用宽
  * 如果高大于宽那就使用高
  * */
  static double maxValue() {
    final maxValue = isHorizontal() ? winWidth() : winHeight();

    return maxValue;
  }

  /*
  * 取宽高里面的最小值，
  * */
  static double minValue() {
    final minValue = isHorizontal() ? winHeight() : winWidth();

    return minValue;
  }

  static bool isNeedRotate() {
    return !kIsWeb && isHorizontal();
  }

  /// 屏幕宽度[横屏需要]
  static double winWidth() {
    final MediaQueryData mediaQuery = MediaQueryData.fromWindow(window);
    return mediaQuery.size.width;
  }

  /// 屏幕高度[横屏需要]
  static double winHeight() {
    final MediaQueryData mediaQuery = MediaQueryData.fromWindow(window);
    return mediaQuery.size.height;
  }

  /// 屏幕宽度[横屏需要]-动态-横竖屏转换会变化
  /// 会影响到上下文
  static double winWidthDynamic(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// 屏幕高度[横屏需要]-动态-横竖屏转换会变化
  /// 会影响到上下文
  static double winHeightDynamic(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// 键盘高度
  /// 如果为0则是键盘未弹出
  static double winKeyHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// 状态栏高度
  static double statusBarHeight() {
    return MediaQueryData.fromWindow(window).padding.top;
  }

  /// navigationBar高度
  static double navigationBarHeight() {
    return kToolbarHeight;
  }

  /// 整AppBar高度
  /// 状态栏高度 + navigationBar高度
  static double topBarHeight() {
    return navigationBarHeight() + statusBarHeight();
  }

  static double padTopH() {
    return _topBarH;
  }

  static double padTopHDynamic(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// 【2021 12.28】优惠券图标适配有左右安全区时
  /// 获取安全区右边间距
  static double padRight() {
    return MediaQueryData.fromWindow(window).padding.right;
  }

  /// 【2021 12.28】优惠券图标适配有左右安全区时
  /// /// 获取安全区左边间距
  static double padLeft() {
    return MediaQueryData.fromWindow(window).padding.left;
  }

  static double padBotH() {
    return _botBarH;
  }

  static double pixelRatio() {
    return _pixelRatio;
  }
}
