import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:im/api/data_model/audit_resp.dart';
import 'package:im/core/config.dart';
import 'package:im/global.dart';
import 'package:im/core/http_middleware/interceptor/logging_interceptor.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AuditApi {
  // 这个接口需要在第一时间调用，为了不动之前代码逻辑（http初始化有点延迟)，这里复制http
  // 里面的一些初始化动作
  static Future<AuditRespData> auditStatus() async {
    const int timeOut = 5;
    final Dio dio = Dio();

    dio.interceptors.add(LoggingInterceptor());
    dio.options.baseUrl = Config.auditHost;
    debugPrint('kDebugMode $kDebugMode  Config.auditHost ${Config.auditHost}');
    dio.options
      ..responseType = ResponseType.json
      ..sendTimeout = timeOut * 1000
      ..receiveTimeout = timeOut * 1000
      ..connectTimeout = timeOut * 1000;

    if (!kIsWeb) {
      Global.packageInfo = await PackageInfo.fromPlatform();
      dio.options.headers = {
        HttpHeaders.userAgentHeader:
            "platform:${UniversalPlatform.isIOS ? "ios" : "android"};version:${Global.packageInfo.version};",
      };
    }

    final Response<dynamic> res = await dio.post('/api/common/alipay');
    return AuditResp.fromJson(res.data).data;
  }
}
