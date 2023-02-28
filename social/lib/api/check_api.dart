import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:im/api/entity/check_post_bean.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:oktoast/oktoast.dart';

///Todo:目前的接口请求用到的[apiAccessKey]是放在客户端的，这是一个需要解决的问题
class CheckApi {
  static Dio dio = Dio();

  ///向数美请求审核文字
  static Future postCheckText(String text, String channel,
      {bool showDefaultErrorToast = true}) async {
    if (apiAccessKey == null) return {'riskLevel': 'PASS'};
    try {
      logger.finest("审核文字请求地址 $checkTextUrl");

      if (kIsWeb) {
        final res = await http.post(Uri.parse(checkTextUrl),
            body: jsonEncode(TextBean(apiAccessKey, 'SOCIAL',
                    TextDataBean(text, Global.user.id, channel), 'Buff')
                .toJson()));
        return jsonDecode(res.body);
      } else {
        final timeOut = Http.timeOut * 1000;
        dio.options
          ..sendTimeout = timeOut
          ..receiveTimeout = timeOut
          ..connectTimeout = timeOut;
        final res = await dio.post(checkTextUrl,
            data: TextBean(apiAccessKey, 'SOCIAL',
                    TextDataBean(text, Global.user.id, channel), 'Buff')
                .toJson());
        return jsonDecode(res.data);
      }
    } catch (e) {
      _checkError(e, checkTextUrl);
      rethrow;
    }
  }

  ///向数美请求审核图片
  static Future postCheckImage(List<ImgData> imgList, String channel,
      {bool showDefaultErrorToast = true}) async {
    if (apiAccessKey == null) return null;
    try {
      logger.finest("数审核图片请求地址 $checkImageUrl");
      if (kIsWeb) {
        final res = await http.post(Uri.parse(checkImageUrl),
            body: jsonEncode(ImageBean(apiAccessKey,
                    ImageDataBean(imgList, Global.user.id, channel), 'Buff')
                .toJson()));
        return jsonDecode(res.body);
      } else {
        // 上传图片设置30s超时
        const timeOut = 30 * 1000;
        dio.options
          ..sendTimeout = timeOut
          ..receiveTimeout = timeOut
          ..connectTimeout = timeOut;
        final res = await dio.post(checkImageUrl,
            data: ImageBean(apiAccessKey,
                    ImageDataBean(imgList, Global.user.id, channel), 'Buff')
                .toJson());
        return jsonDecode(res.data);
      }
    } catch (e) {
      _checkError(e, checkImageUrl,
          showDefaultErrorToast: showDefaultErrorToast);
      rethrow;
    }
  }

  static void _checkError(e, String url, {bool showDefaultErrorToast = true}) {
    if (e is DioError) {
      if (showDefaultErrorToast) showToast(networkErrorText);
    }
  }
}

String get checkTextUrl =>
    remoteCheckTextAddress ??
    'https://api-text-gz.fengkongcloud.com/v2/saas/anti_fraud/text';

String get checkImageUrl =>
    remoteCheckImageAddress ??
    'https://api-img-gz.fengkongcloud.com/v2/saas/anti_fraud/imgs';
String remoteCheckImageAddress;
String remoteCheckTextAddress;
String apiAccessKey;
