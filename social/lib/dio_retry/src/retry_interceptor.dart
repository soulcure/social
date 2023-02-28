import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

import 'options.dart';

/// An interceptor that will try to send failed request again
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final RetryOptions options;
  final Connectivity connectivity;

  RetryInterceptor(
      {@required this.dio, RetryOptions options, @required this.connectivity})
      : options = options ?? const RetryOptions();

  @override
  Future<void> onError(
    DioError err,
    ErrorInterceptorHandler handler,
  ) async {
    var extra = RetryOptions.fromExtra(err.requestOptions) ?? options;

    final shouldRetry = extra.retries > 0 && await extra.retryEvaluator(err);
    if (!shouldRetry) return handler.reject(err);

    if (extra.retryInterval.inMilliseconds > 0) {
      await Future.delayed(extra.retryInterval);
    }

    /// 网络断开期间阻塞
    //  await ConnectivityService.to.waitUtilConnected();

    // Update options to decrease retry count before new try
    extra = extra.copyWith(retries: extra.retries - 1);
    err.requestOptions.extra = err.requestOptions.extra
      ..addAll(extra.toExtra());

    try {
      /// 网络断开期间阻塞
      final req = await scheduleRequestRetry(err.requestOptions);
      return handler.resolve(req);
    } catch (e) {
      // Let any new error from the retry pass through
      return handler.reject(e);
    }
  }

  ///网络不可用时候阻塞请求，直到网络恢复可用后，发起请求
  Future<Response> scheduleRequestRetry(RequestOptions requestOptions) async {
    final responseCompleter = Completer<Response>();

    await connectivity.checkConnectivity().then((v) {
      if (v != ConnectivityResult.none) {
        responseCompleter.complete(doRequest(requestOptions));
      } else {
        StreamSubscription streamSubscription;
        streamSubscription = connectivity.onConnectivityChanged.listen((v) {
          if (v != ConnectivityResult.none) {
            streamSubscription.cancel();
            responseCompleter.complete(doRequest(requestOptions));
          }
        });
      }
    });
    return responseCompleter.future;
  }

  Future<Response> doRequest(RequestOptions requestOptions) {
    return dio.request(
      requestOptions.path,
      cancelToken: requestOptions.cancelToken,
      data: requestOptions.data,
      onReceiveProgress: requestOptions.onReceiveProgress,
      onSendProgress: requestOptions.onSendProgress,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        sendTimeout: requestOptions.sendTimeout,
        receiveTimeout: requestOptions.receiveTimeout,
        extra: requestOptions.extra,
        headers: requestOptions.headers,
        responseType: requestOptions.responseType,
        contentType: requestOptions.contentType,
        validateStatus: requestOptions.validateStatus,
        receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
        followRedirects: requestOptions.followRedirects,
        maxRedirects: requestOptions.maxRedirects,
        requestEncoder: requestOptions.requestEncoder,
        responseDecoder: requestOptions.responseDecoder,
        listFormat: requestOptions.listFormat,
      ),
    );
  }
}
