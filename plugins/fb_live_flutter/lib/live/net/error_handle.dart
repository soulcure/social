import 'dart:io';

import 'package:dio/dio.dart';

class ExceptionHandle {
  static const int success = 200;
  static const int success_not_content = 204;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int not_found = 404;

  static const int net_error = 1000;
  static const int parse_error = 1001;
  static const int socket_error = 1002;
  static const int http_error = 1003;
  static const int timeout_error = 1004;
  static const int cancel_error = 1005;
  static const int unknown_error = 9999;

  static const Map reqErrorText = {
    socket_error: '网络异常，请检查你的网络！',
    http_error: '服务器异常！',
    parse_error: '数据解析错误！',
    net_error: '网络异常，请检查你的网络！',
    timeout_error: '连接超时！',
    cancel_error: '取消请求',
    unknown_error: '未知异常',
  };

  /*
  * 是否请求异常
  * */
  static bool isReqError(int code) {
    if (code == socket_error) {
      return true;
    }
    if (code == http_error) {
      return true;
    }
    if (code == parse_error) {
      return true;
    }
    if (code == net_error) {
      return true;
    }
    if (code == timeout_error) {
      return true;
    }
    if (code == cancel_error) {
      return true;
    }
    if (code == unknown_error) {
      return true;
    }
    return false;
  }

  static NetError handleException(DioError error) {
    if (error is DioError) {
      if (error.type == DioErrorType.other ||
          error.type == DioErrorType.response) {
        final dynamic e = error.error;
        if (e is SocketException) {
          return NetError(socket_error, reqErrorText[socket_error]);
        }
        if (e is HttpException) {
          return NetError(http_error, reqErrorText[http_error]);
        }
        if (e is FormatException) {
          return NetError(parse_error, reqErrorText[parse_error]);
        }
        return NetError(net_error, reqErrorText[net_error]);
      } else if (error.type == DioErrorType.connectTimeout ||
          error.type == DioErrorType.sendTimeout ||
          error.type == DioErrorType.receiveTimeout) {
        //  连接超时 || 请求超时 || 响应超时
        return NetError(timeout_error, reqErrorText[timeout_error]);
      } else if (error.type == DioErrorType.cancel) {
        return NetError(cancel_error, reqErrorText[cancel_error]);
      } else {
        return NetError(unknown_error, reqErrorText[unknown_error]);
      }
    } else {
      return NetError(unknown_error, reqErrorText[unknown_error]);
    }
  }
}

class NetError {
  int code;
  String msg;

  NetError(this.code, this.msg);
}
