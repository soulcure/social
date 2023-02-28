import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/hybrid/jpush_util.dart';
import 'package:im/pages/logging/let_log.dart';
import 'package:im/pages/login/login_page.dart';
import 'package:im/pages/login/model/country_model.dart';
import 'package:im/routes.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/random_string.dart';
import 'package:im/widgets/custom/custom_route.dart';
import 'package:im/ws/ws.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:uuid/uuid.dart';

import 'config.dart';
import 'http_middleware/http.dart';

String networkErrorText2 = '网络质量不佳，请稍后重试~'.tr;

class HttpWeb {
  static int timeOut = 15; // 超时时间， 单位s
  static Map<String, String> getHeader(
      {Map<String, dynamic> headers, Map data}) {
    final Map<String, String> headerMap = headers ?? <String, String>{};
    // 内置通用header 发请求的时候再来取token
    final Map commonHeaders = {
      "Nonce": const Uuid().v4(),
      "Timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
      "Authorization": Config.token ?? ""
    };
    if (!kIsWeb) commonHeaders["AppKey"] = Config.appKey;

    // 优先外部传入的header的。commonHeaders覆盖非null
    commonHeaders.forEach((key, value) {
      if (value == null) {
        headerMap[key] = value;
      } else {
        headerMap.putIfAbsent(key, () => value);
      }
    });
    final List signList = ["Nonce", "AppKey", "Timestamp", "Authorization"];
    final Map signMap = Map.from(headerMap);
    signMap.removeWhere((key, value) {
      if (signList.contains(key)) {
        return false;
      } else {
        return true;
      }
    });
    if (data == null) {
      signMap["RequestBody"] = "";
    } else {
      data["transaction"] = RandomString.length(12);
      signMap["RequestBody"] = jsonEncode(data);
    }
    final List<String> keys = List.from(signMap.keys);
    keys.sort((a, b) => a.compareTo(b));
    String signStr = keys.map((e) {
      if (signMap[e] == null) {
        return "$e=";
      } else {
        return "$e=${signMap[e]}";
      }
    }).reduce((v, element) {
      return "$v&$element";
    });
    signStr += "&${Config.appSecret}";
    signStr = Uri.encodeComponent(signStr);
    //遵循RFC-3986标准(https://tools.ietf.org/html/rfc3986)
    // encodeComponent 执行的是 [2396标准]，`-_.!~*'()`不转。[3986标准]`-._~`不转
    // 因此，还需要对 `!*'()`进行转码
    signStr = signStr.replaceAllMapped(RegExp(r"[\!\*\'\(\)]"), (match) {
      final s = match[0];
      // if(s.length == 1){
      //   var i = int.parse(s[0]);
      //   return "%";
      // }
      if (s == "!") return "%21";
      if (s == "*") return "%2A";
      if (s == "'") return "%27";
      if (s == "(") return "%28";
      if (s == ")") return "%29";
      return s;
    });
    // signStr = Uri.encodeQueryComponent(signStr);

    // print("path: $path data:$data");
    // print("signStr: " + signStr);
    final signature = md5.convert(utf8.encode(signStr)).toString();
    headerMap["signature"] = signature;
    // headerMap["Content-Type"] = 'application/json;charset=utf-8';
    return headerMap;
  }

  /// 发送消息请求
  static Future request(String path,
      {Map data,
      bool showDefaultErrorToast = false,
      bool isOriginDataReturn = false, //是否源数据返回
      bool isContentType = true, // 是否设置设置json 请求类型
      bool isReturnString = false,
      String method = "post"}) async {
    String url = Config.host + path; // 请求url
    dynamic res;
    final Map<String, String> _header = {};
    getHeader(data: data).forEach((key, value) {
      _header[key] = value;
    });
    // print('header参数为$_header');
    // print('showDefaultErrorToast参数为$showDefaultErrorToast');
    // print('请求参数为$data');
    if (isContentType) {
      _header['Content-Type'] = 'application/json;charset=utf-8'; // 设置json 请求类型
    }

    try {
      if (method == 'post') {
        res = await http
            .post(
              Uri.parse(url),
              body: jsonEncode(data),
              headers: _header,
            )
            .timeout(Duration(seconds: timeOut));
      }
      if (method == 'get') {
        if (data != null && data.isNotEmpty) {
          final StringBuffer sb = StringBuffer("?");
          data.forEach((key, value) {
            sb.write("$key" "=" "$value" "&");
          });
          String dataStr = sb.toString();
          dataStr = dataStr.substring(0, dataStr.length - 1);
          url += dataStr;
        }
        res = await http
            .get(
              Uri.parse(url),
              headers: _header,
            )
            .timeout(Duration(seconds: timeOut));
      }

      if (res == null) return null;
      if (res != null)
        LoggerPage.endNet(path,
            data: res?.body, headers: res?.headers, status: res?.statusCode);
      final resData = jsonDecode(res.body);
      if (isOriginDataReturn) {
        return resData;
      } else if (resData["status"] == true) {
        return resData["data"];
      } else {
        final errorMes =
            errorCode2Message[resData["message"]] ?? resData["desc"];
        if (showDefaultErrorToast) showToast(errorMes);
      }
    } on RequestArgumentError catch (e) {
      if ((e.code == 1042 || e.code == 1043 || e.code == 903) &&
          path != '/api/user/ct' &&
          path != '/api/user/login' &&
          path != '/api/common/verification') {
        // 退出登录
        print('退出登录'.tr);
        await _logout(error: e);
      }
      rethrow;
    } catch (e) {
      //  if (e is DioError) {
      //   final String error =
      //       "${e.toString()} (path:${Config.host + path} params:${e.request.data})";
      //   if (e.response != null)
      //     Logger.endNet(path,
      //         data: e.response.data,
      //         headers: e.response.headers,
      //         status: e.response.statusCode);

      //   ///因为在拦截器中对文字进行了审核处理，这里的判断是避免当审核不通过时同时弹出两个提示框
      //   if (e.type != DioErrorType.CANCEL && showDefaultErrorToast) {
      //     if (kIsWeb) {
      //       _showError(networkErrorText2, error);
      //     } else {
      //       /// 先不提示错误，看看是否可行
      //       if (e.type == DioErrorType.RESPONSE) {
      //         _showError(networkErrorText, error);
      //       } else {
      //         _showError('数据异常，请重试！'.tr, error);
      //       }
      //     }
      //   }
      // }
      if (e is TimeoutException) {
//        final String error =
//            "${e.toString()} (path:${Config.host + path} params:$data)";
//        _showError(networkErrorText, error);
        showToast(networkErrorText2);
      }

      rethrow;
    }
  }

  static Future<void> _logout({RequestArgumentError error}) async {
    if (Routes.currentRoute == loginRoute) return;
    Routes.currentRoute = loginRoute;
    Config.permission = null;

    /// deleteAlias 有可能不生效，所以用这种方式
    JPushUtil.setAlias(RandomString.length(12));
    final String mobile = Global.user.mobile;
    Ws.instance.close();
    CountryModel country;
    final countryString = SpService.to.getString(SP.country);
    if (countryString != null && countryString.isNotEmpty) {
      final map = json.decode(countryString);
      country = CountryModel.fromMap(map);
    }

    final alterInfo = (error?.code == 903) ? error.message : '登录已过期，请重新登录'.tr;

    /// 退出登录
    unawaited(
      Global.navigatorKey.currentState
          .pushAndRemoveUntil(
              CustomRoute(
                LoginPage(
                  mobile: mobile,
                  country: country,
                  alertInfo: alterInfo,
                ),
                settings: const RouteSettings(name: loginRoute),
              ),
              (route) => route == null)
          .then((value) {
        if (error?.code == 903) showToast('登录已失效'.tr);
      }),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      Global.user = LocalUser()..cache();
      SpService.to.remove(SP.defaultChatTarget);
      if (kIsWeb) {
//        ChatTargetsModel.instance.directMessageListTarget = DirectMessageListTarget();
        // 暂时清理这4个，全部清除会出问题，暂时没时间找
        Db.remarkBox.clear();
        Db.remarkListBox.clear();
        Db.dmListBox.clear();
        Db.channelBox.clear();
        Db.guildBox.clear();
        Db.friendListBox.clear();
      }
      JPush()
        ..clearAllNotifications()
        ..setBadge(0);
      JPushUtil.clearAllNotification();
      print('push');
    });
  }
}
