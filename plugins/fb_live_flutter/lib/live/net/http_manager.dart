import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:oktoast/oktoast.dart';

import 'error_handle.dart';

class HttpManager {
  static final HttpManager _instance = HttpManager._internal();
  Dio? _dio;

  static const CODE_SUCCESS = 200;
  static const CODE_TIME_OUT = -1;

  static String? token;

  /// 自定义Header

  factory HttpManager() => _instance;

  ///通用全局单例，第一次使用时初始化
  HttpManager._internal() {
    if (null == _dio) {
      _dio = Dio(BaseOptions(
        baseUrl: configProvider.liveHost,
        connectTimeout: 5000,
        receiveTimeout: 10000,
      ));
      _dio!.interceptors.add(fbApi.loggingInterceptor);
    }
  }

  static HttpManager getInstance({String? baseUrl}) {
    if (baseUrl == null) {
      return _instance._normal();
    } else {
      return _instance._baseUrl(baseUrl);
    }
  }

  //用于指定特定域名
  HttpManager _baseUrl(String baseUrl) {
    if (_dio != null) {
      _dio!.options.baseUrl = baseUrl;
    }

    return HttpManager();
  }

  //一般请求，默认域名
  HttpManager _normal() {
    if (_dio != null) {
      if (_dio!.options.baseUrl != configProvider.liveHost) {
        _dio!.options.baseUrl = configProvider.liveHost;
      }
    }
    return HttpManager();
  }

  ///通用的GET请求
  Future get(String api,
      {Map<String, dynamic>? params,
      bool withLoading = true,
      bool isToastShow = true}) async {
    Response response;

    final String? mapKay = fbApi.getToken();
    final Map<String, String?> headMap = {"Authentication": mapKay};
    _dio!.options.headers.addAll(headMap);
    try {
      response = await _dio!.get(api, queryParameters: params);
    } on DioError catch (e) {
      final NetError netError = ExceptionHandle.handleException(e);
      return _errorDataMap(netError);
    }

    fbApi.fbLogger.info('[$api]response: ${json.encode(response.data)} \n');

    if (isToastShow) {
      toastShow(response);
    }
    return response.data;
  }

  ///通用的POST请求
  Future post(String api,
      {Map<String, dynamic>? params,
      bool withLoading = true,
      bool isToastShow = true}) async {
    Response response;
    final ConnectivityResult connectivityResult =
        await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      myToast("请检查网络配置");
    }
    final String? mapKay = fbApi.getToken();
    final Map<String, String?> headMap = {"Authentication": mapKay};
    _dio!.options.headers.addAll(headMap);
    try {
      response = await _dio!.post(api, data: params);
    } on DioError catch (e) {
      final NetError netError = ExceptionHandle.handleException(e);
      return _errorDataMap(netError);
    }

    fbApi.fbLogger.info('[$api]response: ${json.encode(response.data)} \n');

    if (isToastShow) {
      toastShow(response);
    }
    return response.data;
  }

  /*
  * 接口错误消息提示
  * */

  /// 接口的错误提示写成方法，在场景使用方法时配置是否提示的参数。
  void toastShow(Response response) {
    if (response.data is Map &&
        response.data['code'] != null &&
        response.data['code'] != 200) {
      final String? msg = response.data['msg'];

      /// 【优惠卷】登录账号开播，每次开播，立马点优惠卷设置，会弹出提示信息“绑定数据失败”，过了一会又正常了
      /// 【2021 11.21】
      final bool isNotTip =
          msg == "请求数据绑定失败" || msg!.contains("绑定数据失败") || msg.contains("资源不存在");
      if (isNotTip) {
        return;
      }

      /// 先清除，防止与加载中层叠
      dismissAllToast();

      if (response.data['code'] == 701) {
        myToast('已经领取过了，去使用吧');
      } else if (response.data['code'] == 700) {
        myToast('已抢光，下次早点来');
      } else {
        myToast(msg);
      }
    }
  }

  Future upload(String api, {required String imagePath}) async {
    final FormData formData =
        FormData.fromMap({"file": await MultipartFile.fromFile(imagePath)});
    Response response;
    try {
      final String? mapKay = fbApi.getToken();
      final Map<String, String?> headMap = {"Authentication": mapKay};
      _dio!.options.headers.addAll(headMap);
      response = await _dio!.post(api, data: formData);
    } on DioError catch (e) {
      final NetError netError = ExceptionHandle.handleException(e);
      return _errorDataMap(netError);
    }

    fbApi.fbLogger.info('[$api]response: ${json.encode(response.data)} \n');

    toastShow(response);
    return response.data;
  }

  Future webUpload(String api, {required Map fileMap}) async {
    final String? filename = fileMap['fileName']; // 文件名
    final MultipartFile file = MultipartFile.fromBytes(
        fileMap['fileStream'].toList(),
        filename: filename);
    final FormData formData = FormData.fromMap({"file": file});
    Response response;
    try {
      final String? mapKay = fbApi.getToken();
      final Map<String, String?> headMap = {"Authentication": mapKay};
      _dio!.options.headers.addAll(headMap);
      response = await _dio!.post(api, data: formData);
    } on DioError catch (e) {
      final NetError netError = ExceptionHandle.handleException(e);
      return _errorDataMap(netError);
    }

    fbApi.fbLogger.info('[$api]response: ${json.encode(response.data)} \n');

    return response.data;
  }

  Map<String, dynamic> _errorDataMap(NetError netError) {
    final Map<String, dynamic> dataMap = {};
    dataMap["code"] = netError.code;
    dataMap["msg"] = netError.msg;
    return dataMap;
  }
}
