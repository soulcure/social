import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/loggers.dart';
import 'package:im/utils/utils.dart';

import 'config.dart';

/// 错误上报，限制最大数量及重复的错误，减轻服务器压力
class ErrorReporter {
  static final Map<String, bool> _names = {};
//  static final SentryClient _sentry = new SentryClient(dsn: Config.logHost);
  static int _count = 0;

  static Future<bool> report(Object msg, Object stack) async {
    logger.severe(msg, stack);
    if (Config.isDebug) return false;
    if (!isNotNullAndEmpty(Config.logHost)) return false;
    if (msg == null) return false;
    // 小于20条，并且错误不能重复
    final msgStr = msg.toString();
    if (_count < 20 && _names[msgStr] == null) {
      try {
        _count++;
        _names[msgStr] = true;
        // TODO 临时屏蔽
        // await _sentry.captureException(
        //   exception: msgStr,
        //   stackTrace: stack,
        // );
        return true;
      } catch (e) {
        print(e);
      }
    }
    return false;
  }

  static void init() {
    // 全局错误捕获 --> 改为bugly处理
    // FlutterError.onError = (details) {
    //   report(details.exception, details.stack);
    // };

    /// 重定向错误界面
    if (kReleaseMode && Config.env == Env.pro) {
      ErrorWidget.builder = (flutterErrorDetails) {
        return GestureDetector(
          onTap: () {
            Get.back();
          },
          child: Container(
            color: Colors.white,
          ),
        );
      };
    }
  }
}
