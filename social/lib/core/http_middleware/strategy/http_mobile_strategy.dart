import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:im/core/http_middleware/interceptor/channel_mutex_interceptor.dart';
import 'package:im/core/http_middleware/interceptor/logging_interceptor.dart';
import 'package:im/core/http_middleware/interceptor/text_interceptor.dart';
import 'package:im/core/http_middleware/interceptor/token_interceptor.dart';
import 'package:im/dio_retry/src/options.dart';
import 'package:im/dio_retry/src/retry_interceptor.dart';

import '../../../global.dart';
import '../../config.dart';
import '../interceptor/header_interceptor.dart';
import 'http_strategy.dart';

class MobileHttpStrategy implements HttpStrategy {
  @override
  void init(Dio dio, int timeOut) {
    dio.interceptors
      ..add(TokenInterceptor())
      ..add(ChannelMutexInterceptor())
      ..add(TextCheckerInterceptor())
      ..add(LoggingInterceptor())
      //..add(HeaderInterceptor())
      ..add(RetryInterceptor(
          dio: dio,
          options: RetryOptions.noRetry(),
          connectivity: Connectivity()));

    ///添加拦截器，开发和测试环境打印http请求详细日志
    final bool show =
        Config.env == Env.newtest || Config.env == Env.dev || true;
    if (show) {
      //开发测试环境显示http详细日志
      dio.interceptors
          .add(LogInterceptor(requestBody: show, responseBody: show));
    }

    dio.options.baseUrl = Config.host;
    dio.options
      ..responseType = ResponseType.json
      ..sendTimeout = timeOut * 1000
      ..receiveTimeout = timeOut * 1000
      ..connectTimeout = timeOut * 1000;

    ///这里的[deviceInfo]可能尚未初始化完成，导致[channel]的值传入的是默认值，所以需要等待初始化完成
    Global.getDeviceInfo().then((value) {
      dio.options.headers = {
        HttpHeaders.userAgentHeader:
            "platform:${Global.deviceInfo.systemName.toLowerCase()};channel:${Config.channel};version:${Global.packageInfo.version};",
      };
    });
  }

  @override
  Future<Response> post(
      {Dio dio,
      int timeOut,
      String path,
      Map data,
      CancelToken cancelToken,
      Options options}) {
    print('post http path. $path');
    return dio.post(path,
        data: data, cancelToken: cancelToken, options: options);
  }
}
