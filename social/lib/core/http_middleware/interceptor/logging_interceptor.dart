import 'package:dio/dio.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/logging/let_log.dart';

class LoggingInterceptor extends Interceptor {
  final Map<String, DateTime> _map = {};

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    _map[options.headers["Nonce"]] = DateTime.now();
    LoggerPage.net(options.path, data: options.data);
    logger.fine("[HTTP] ${options.path} start");
    super.onRequest(options, handler);
  }

  @override
  void onError(
    DioError err,
    ErrorInterceptorHandler handler,
  ) {
    final t = _map[err.requestOptions.headers["Nonce"]];
    logger.fine(
        "[HTTP] ${err.requestOptions.path} error in ${DateTime.now().difference(t).inMilliseconds}ms");
    LoggerPage.endNet(err.requestOptions.path, status: 400);
    super.onError(err, handler);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    final t = _map[response.requestOptions.headers["Nonce"]];
    logger.fine(
        "[HTTP] ${response.requestOptions.path} done in ${DateTime.now().difference(t).inMilliseconds}ms");

    LoggerPage.endNet(response.requestOptions.path,
        data: response.data,
        headers: response.headers,
        status: response.statusCode);
    super.onResponse(response, handler);
  }
}
