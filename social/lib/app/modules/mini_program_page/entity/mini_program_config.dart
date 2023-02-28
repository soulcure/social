import 'package:flutter/material.dart';
import 'package:im/common/extension/string_extension.dart';

class MiniProgramConfig {
  final Map<String, MiniProgramPageConfig> pages;
  MiniProgramConfig({
    Map<String, MiniProgramPageConfig> pages,
  }) : pages = pages ?? {};
  static MiniProgramConfig fromJson(Map<String, dynamic> json) {
    return MiniProgramConfig(
        pages: (json['pages'] as Map).map(
      (key, value) => MapEntry(
        key,
        MiniProgramPageConfig.fromJson(value),
      ),
    ));
  }
}

class MiniProgramPageConfig {
  final bool showNavigationBar;
  final Color navigationBarBackgroundColor;
  final Color navigationBarTextColor;
  final String navigationBarTitleText;
  MiniProgramPageConfig({
    this.showNavigationBar,
    this.navigationBarBackgroundColor,
    this.navigationBarTextColor,
    this.navigationBarTitleText,
  });

  MiniProgramPageConfig copyWith({
    bool showNavigationBar,
    Color navigationBarBackgroundColor,
    Color navigationBarTextColor,
    String navigationBarTitleText,
  }) {
    return MiniProgramPageConfig(
      showNavigationBar: showNavigationBar ?? this.showNavigationBar,
      navigationBarBackgroundColor:
          navigationBarBackgroundColor ?? this.navigationBarBackgroundColor,
      navigationBarTextColor:
          navigationBarTextColor ?? this.navigationBarTextColor,
      navigationBarTitleText:
          navigationBarTitleText ?? this.navigationBarTitleText,
    );
  }

  static MiniProgramPageConfig fromJson(Map<String, dynamic> json) {
    final showNavigationBar =
        json['showNavigationBar'] == true || json['showNavigationBar'] == false
            ? json['showNavigationBar']
            : null;

    return MiniProgramPageConfig(
      showNavigationBar: showNavigationBar,
      navigationBarBackgroundColor:
          parseBgColorStr(json['navigationBarBackgroundColor']),
      navigationBarTextColor:
          _parseTextColorStr(json['navigationBarTextColor']),
      navigationBarTitleText: json['navigationBarTitleText'],
    );
  }

  static Color parseBgColorStr(String colorStr) {
    if (colorStr.noValue) return null;
    final colorValue = int.tryParse(colorStr.substring(1), radix: 16);
    if (colorValue == null) return null;
    int rgb;
    int a;
    if (colorStr.length >= 8) {
      rgb = colorValue >> 8;
      a = colorValue & 0xFF;
    } else {
      rgb = colorValue;
      a = 0xFF;
    }
    final argb = a << 24 | rgb;
    return Color(argb);
  }

  // 文字颜色只支持黑白两种颜色，默认是黑色字体
  static Color _parseTextColorStr(String colorStr) {
    if (colorStr.noValue) return Colors.black;
    if (colorStr == 'white') return Colors.white;
    return Colors.black;
  }
}
