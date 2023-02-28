import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:im/api/user_api.dart';
import 'package:im/core/config.dart';
import 'package:im/services/sp_service.dart';
import 'package:pedantic/pedantic.dart';

class TokenInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.path == UserApi.updateTokenUrl) {
      final String token = response.headers['authorization']?.first;
      if (token != null && token.isNotEmpty) {
        debugPrint("yao token=$token");
        // 保存token
        Config.token = token;
        unawaited(SpService.to.setString(SP.token, token));
        // 保存时间戳
        unawaited(SpService.to
            .setInt(SP.loginTime, DateTime.now().millisecondsSinceEpoch));
      }
    }
    handler.next(response);
  }
}
