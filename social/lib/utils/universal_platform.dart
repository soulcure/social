import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:im/global.dart';
import 'package:tuple/tuple.dart';
import 'package:universal_html/html.dart' as html;

class UniversalPlatform {
  static bool get isWebMobile {
    if (!kIsWeb) return false;
    final pattern = RegExp("iPhone|iPad|iPod|Android", caseSensitive: false);
    return pattern.hasMatch(html.window.navigator.userAgent);
  }

  static String get operatingSystem =>
      kIsWeb ? "web" : Platform.operatingSystem;

  static bool get isWeb => kIsWeb;

  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  static bool get isWindows => !kIsWeb && Platform.isWindows;

  static bool get isIOS => !kIsWeb && Platform.isIOS;

  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  static bool get isFuchsia => !kIsWeb && Platform.isFuchsia;

  static bool get isLinux => !kIsWeb && Platform.isLinux;

  static bool get isPc => isMacOS || isWindows || isLinux;

  static bool get isMobileDevice => isIOS || isAndroid;

  /// 判断是否>=[targetApi]的android系统api版本
  ///
  /// 注意使用时机，Global.deviceInfo信息不能为空
  /// https://source.android.com/setup/start/build-numbers
  static bool isAndroidAboveLevel(int targetApi) {
    return UniversalPlatform.isAndroid && Global.androidSdkInt >= targetApi;
  }

  static bool isAndroidBelowLevel(int targetApi) {
    return UniversalPlatform.isAndroid &&
        Global.deviceInfo != null &&
        Global.deviceInfo.sdkInt < targetApi;
  }

  static bool isIOSBelowLevel(int mainVersion, {int item2 = 0, int item3 = 0}) {
    return UniversalPlatform.isIOS &&
        (Global.deviceInfo?.systemVersion?.isNotEmpty ?? false) &&
        versionCompare(mainVersion, item2: item2, item3: item3);
  }

  static bool versionCompare(int item1, {int item2 = 0, int item3 = 0}) {
    final Tuple3<int, int, int> current =
        iOSVersionNumber(Global.deviceInfo.systemVersion);
    if (current.item1 < item1) return true;
    if (current.item1 == item1) {
      if (current.item2 < item2)
        return true;
      else if (current.item2 == item2)
        return current.item3 < item3;
      else
        return false;
    } else
      return false;
  }

  static Tuple3<int, int, int> iOSVersionNumber(String systemVersion) {
    const Tuple3<int, int, int> zeroTuple = Tuple3(0, 0, 0);
    if (systemVersion == null) return zeroTuple;
    bool _isVersionString(String version) {
      const regExp = r'^([0-9]{1,3})(.([0-9]{1,3})){0,2}$';
      return RegExp(regExp).hasMatch(version);
    }

    if (!_isVersionString(systemVersion)) return zeroTuple;
    try {
      final nums = systemVersion.split('.');
      if (nums.isEmpty) {
        return zeroTuple;
      } else {
        return Tuple3(
          int.parse(nums[0]),
          int.parse(nums.length > 1 ? nums[1] : "0"),
          int.parse(nums.length > 2 ? nums[2] : '0'),
        );
      }
    } catch (e) {
      return zeroTuple;
    }
  }

  /// - 获取当前平台
  /// - 1:android,2:ios,3:web,4:小程序，5：win pc，6：linux pc 7：Mac pc
  static int clientType() {
    if (isMobileDevice && isWeb) {
      return 4;
    } else if (isAndroid) {
      return 1;
    } else if (isIOS) {
      return 2;
    } else if (isWeb) {
      return 3;
    } else if (isWindows) {
      return 5;
    } else if (isLinux) {
      return 6;
    } else if (isMacOS) {
      return 7;
    }
    return -1;
  }
}
