import 'dart:convert';
import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:im/core/config.dart';
import 'package:im/dlog/model/dlog_report_model.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';

class DLogAnalysisService {
  /// 网络请求对象
  Dio _dio;

  /// 网络请求超时时长
  final _timeOut = 10 * 1000; // 超时时间， 单位s

  /// Dlog上报服务器域名 (web的只有正式上报地址)
  static const _hosts = kIsWeb
      ? {
          Env.dev: "http://jdlog-h5.uu.cc/", // 开发环境
          Env.dev2: "https://jdlog-h5.uu.cc/", // 开发环境2
          Env.newtest: "https://jdlog-h5.uu.cc/", // 测试环境
          Env.sandbox: "https://jdlog-test.uu.cc/", // 沙盒环境
          Env.pre: "https://jdlog-h5.uu.cc/", // 预发布环境
          Env.pro: "https://jdlog-h5.uu.cc/", // 正式环境
        }
      : {
          Env.dev: "https://jdlog-test.uu.cc/", // 开发环境
          Env.dev2: "https://jdlog-test.uu.cc/", // 开发环境
          Env.newtest: "https://jdlog-test.uu.cc/", // 测试环境
          Env.sandbox: "https://jdlog-test.uu.cc/", // 沙盒环境
          Env.pre: "https://jdlog-test.uu.cc/", // 预发布环境
          Env.pro: "https://jdlog.uu.cc/", // 正式环境
        };

  /// 获取对应环境地址
  static final String _dlogHost = _hosts[Config.env];

  static final DLogAnalysisService _instance = DLogAnalysisService._internal();

  factory DLogAnalysisService() => _instance;

  ///通用全局单例，第一次使用时初始化
  DLogAnalysisService._internal() {
    if (null == _dio) {
      final BaseOptions options = BaseOptions(
          baseUrl: Config.liveHost,
          connectTimeout: _timeOut,
          sendTimeout: _timeOut,
          receiveTimeout: _timeOut);

      options.contentType = "application/json";

      /// 设置请求头
      if (!kIsWeb)
        options.headers.addAll({
          "Content-Encoding": "gzip",
          "accept-encoding": "gzip, deflate, br",
          "accept": " */*",
        });
      _dio = Dio(options);

      /// 是否代理
      bool useProxy = SpService.to.getBool(SP.useProxy);
      useProxy ??= false;

      /// 代理地址
      final String proxy = SpService.to.getString(SP.proxySharedKey);

      /// 设置代理
      if (useProxy && isNotNullAndEmpty(proxy)) _setProxy(proxy);
    }
  }

  static DLogAnalysisService getInstance({String baseUrl}) {
    if (_instance._dio != null) {
      if (_instance._dio.options.baseUrl != _dlogHost) {
        _instance._dio.options.baseUrl = _dlogHost;
      }
    }
    return _instance;
  }

  // Future _get(String api, {Map<String, dynamic> params}) async {
  //   Response response;
  //   try {
  //     response = await _dio.get(api, queryParameters: params);
  //   } on DioError catch (e) {
  //     final NetError netError = ExceptionHandle.handleException(e);
  //     return _errorDataMap(netError);
  //   }
  //
  //   return response.data;
  // }

  /// post 数据请求
  Future<dynamic> _post(String api, {List<int> params}) async {
    Response response;

    /// 获取数据长度
    final int length = params.length;

    /// 设置请求头content-length
    _dio.options.headers.addAll({"content-length": "$length"});

    /// 将数据转换为数据流
    final streamData = Stream.fromIterable(params.map((e) => [e]));

    if (streamData == null) return;

    /// 发起请求
    response = await _dio.post(api, data: streamData);

    return response.data;
  }

  // 设置系统 http 代理也抓不到 flutter 的包，必须设置 dio 的代理才能抓到。
  void _setProxy(String proxy) {
    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      client.findProxy = (uri) {
        return "PROXY $proxy";
      };
      // 需要校验所有证书：只有有效的根证书才能被信任。
      // CA颁发的证书，被系统成功认证的话，不会走到这个回调；没有成功认证会走到这里。直接返回false,拒绝这些情况的请求。
      // 我们的证书是CA颁发的，被系统认证的。因此能够正常访问。
      client.badCertificateCallback = (cert, host, port) {
        // return false;
        return true;
      };

      return null;
    };
  }

  /// 数据上报请求接口
  Future<void> request(List<DLogReportModel> list) async {
    if (UniversalPlatform.isMobileDevice) {
      await mobileRequest(list);
    } else {
      await nonMobileRequest(list);
    }
  }

  /// 数据上报请求接口
  Future<void> mobileRequest(List<DLogReportModel> list) async {
    if (list == null || list.isEmpty) return;
    final paramList = [];

    /// 遍历请求数据
    for (final model in list) {
      final item = jsonDecode(model.dlogContent);
      if (item != null && item.isNotEmpty) {
        paramList.add(item);
      }
    }

    if (paramList == null || paramList.isEmpty) return;

    /// 请求参数转为json字符串
    final jsonString = jsonEncode(paramList);

    if (jsonString == null || jsonString.isEmpty) return;

    /// utf8编码
    final utf8Data = utf8.encode(jsonString);

    if (utf8Data == null || utf8Data.isEmpty) return;

    /// 进行数据gzip压缩
    final zipDataList = GZipCodec().encode(utf8Data);

    if (zipDataList == null || zipDataList.isEmpty) return;

    /// 发起请求
    await _post("", params: zipDataList);
  }

  /// 数据上报请求接口
  Future<void> nonMobileRequest(List<DLogReportModel> list) async {
    if (list == null || list.isEmpty) return;
    final paramList = [];

    /// 遍历请求数据
    for (final model in list) {
      final item = jsonDecode(model.dlogContent);
      if (item != null && item.isNotEmpty) {
        paramList.add(item);
      }
    }

    if (paramList == null || paramList.isEmpty) return;

    /// 请求参数转为json字符串
    final jsonString = jsonEncode(paramList);

    if (jsonString == null || jsonString.isEmpty) return;

    /// 发起请求
    await _nonMobilePost("", params: jsonString);
  }

  /// post 数据请求
  Future<dynamic> _nonMobilePost(String api, {String params}) async {
    Response response;

    /// 发起请求
    response = await _dio.post(api, data: params);
    return response.data;
  }
}
