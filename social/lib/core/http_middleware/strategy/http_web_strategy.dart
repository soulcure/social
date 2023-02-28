import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:im/api/user_api.dart';
import 'package:im/core/http_middleware/interceptor/channel_mutex_interceptor.dart';
import 'package:im/core/http_middleware/interceptor/header_interceptor.dart';
import 'package:im/core/http_middleware/interceptor/text_interceptor.dart';
import 'package:im/dio_retry/src/options.dart';
import 'package:im/dio_retry/src/retry_interceptor.dart';
import 'package:im/services/sp_service.dart';
import 'package:pedantic/pedantic.dart';

import '../../config.dart';
import 'http_strategy.dart';

class WebHttpStrategy implements HttpStrategy {
  @override
  void init(Dio dio, int timeOut) {
    dio.interceptors.add(InterceptorsWrapper(onResponse: (res, handler) {
      if (res.requestOptions.path == UserApi.updateTokenUrl) {
        final String token = res.headers['authorization']?.first;
        if (token != null && token.isNotEmpty) {
          // 保存token
          Config.token = token;
          unawaited(SpService.to.setString(SP.token, token));
          // 保存时间戳
          unawaited(SpService.to
              .setInt(SP.loginTime, DateTime.now().millisecondsSinceEpoch));
        }
      }
      handler.resolve(res);
    }));

    dio.interceptors
      ..add(TextCheckerInterceptor())
      ..add(ChannelMutexInterceptor())
      ..add(HeaderInterceptor())
      ..add(RetryInterceptor(
          dio: dio,
          options: RetryOptions.noRetry(),
          connectivity: Connectivity()));
    dio.options.baseUrl = Config.host;
    dio.options
      ..responseType = ResponseType.json
      ..sendTimeout = timeOut * 1000
      ..receiveTimeout = timeOut * 1000
      ..connectTimeout = timeOut * 1000;
  }

  @override
  Future<Response> post(
      {Dio dio,
      int timeOut,
      String path,
      Map data,
      CancelToken cancelToken,
      Options options}) {
    return dio
        .post(path, data: data, cancelToken: cancelToken, options: options)
        .timeout(Duration(seconds: timeOut));
  }
}
