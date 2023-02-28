import 'package:flutter/material.dart';
import 'package:im/themes/dark_theme.dart';
import 'package:im/themes/web_light_theme.dart';
import 'package:im/utils/universal_platform.dart';

import 'default_theme.dart';

enum SkinType { ligth, dark, webLight }

/// 皮肤管理类
class Skin {
  /// 当前主题
  static DefaultTheme theme =
      UniversalPlatform.isMobileDevice ? DefaultTheme() : WebLightTheme();

  /// 当前主题数据
  static ThemeData themeData = theme.themeData;

  /// 当前主题类型
  static SkinType skinType = SkinType.ligth;

  /// 更改皮肤
  static void change(SkinType mode) {
    if (skinType == mode) return;
    skinType = mode;
    if (mode == SkinType.webLight) {
      theme = WebLightTheme();
      themeData = theme.themeData;
    } else if (mode == SkinType.ligth) {
      theme = DefaultTheme();
      themeData = theme.themeData;
    } else {
      theme = DarkTheme();
      themeData = theme.themeData;
    }
    // App.refresh();
  }
}
