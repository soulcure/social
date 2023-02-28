import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:im/core/config.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/global.dart';
import 'package:oktoast/oktoast.dart';

class UtilApi {
  static Dio dio = Dio();
  static int timeOut = 5;

  ///WS 重连时如果检测到网络断开，在用此接口请求下服务器看是否是通的。
  static Future<bool> postNetWorkIsAvailabel() async {
    try {
      // https://fanbook.idreamsky.com/apple-app-site-association
      dio.options
        ..responseType = ResponseType.json
        ..sendTimeout = timeOut * 1000
        ..receiveTimeout = timeOut * 1000
        ..connectTimeout = timeOut * 1000;
      final res = await dio.get(
          "${Config.host}/api/ping/check?userId=${Global.user?.id}&time=${DateTime.now().millisecondsSinceEpoch}");
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 对一些特殊接口需要针对code 处理逻辑自定义toast异常情况下用到
  static void catchToastError(Exception e) {
    if (e is DioError) {
      if (kIsWeb) {
        showToast(networkErrorText);
      } else {
        /// 先不提示错误，看看是否可行
        if (e.type == DioErrorType.response) {
          showToast("数据异常，请重试！".tr);
        } else {
          showToast(networkErrorText);
        }
      }
    }
    if (e is TimeoutException) {
      showToast(networkErrorText);
    }
  }

  static Future addConfig(String key, String params,
      {String desc, String expire}) async {
    final res = await Http.request('/api/Config/AddConfig', data: {
      'key': key,
      'params': params,
      'desc': desc,
      'expire': expire,
    });
    return res;
  }

  static Future setConfig(String key, Map params, String desc,
      {String expire}) async {
    final res = await Http.request('/api/Config/SetConfig', data: {
      'key': key,
      'params': params,
      'desc': desc,
      'expire': expire,
    });
    return res;
  }

  static Future updateConfig(String key, String params,
      {String desc, String expire}) async {
    final res = await Http.request('/api/Config/UpdateConfig', data: {
      'key': key,
      'params': params,
      'desc': desc,
      'expire': expire,
    });
    return res;
  }

  static Future getConfig(String key) async {
    final res = await Http.request('/api/Config/GetConfig', data: {'key': key});
    return res;
  }

  static Future delConfig(String key) async {
    final res =
        await Http.request('/api/Config/DeleteConfig', data: {'key': key});
    return res;
  }
}
