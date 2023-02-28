import 'package:dio/dio.dart';
import 'package:im/api/entity/oauth_ben.dart';
import 'package:im/core/http_middleware/http.dart';

class OAuthAPI {
  /// 获取三方应用的信息
  static Future<AppInfo> getAppInfo(String clientId) async {
    final res = await Http.dio.get(
      "/open/oauth2/app",
      queryParameters: {"client_id": clientId},
      options: Options(headers: Http.getHeader()),
    );
    if (res?.data == null) return null;
    final app = res.data["app"];
    if (app == null) return null;
    return AppInfo(
        avatarUrl: app["icon"],
        appName: app["name"],
        desc: app["desc"],
        userInfoDesc: app["desc"]['user.info'],
        userLinkDesc: app["desc"]['user.link']);
  }

  /// 确认授权，返回code，三方应用凭借code换取token
  static Future<String> auth(String clientId, {String state}) async {
    String code;
    try {
      /// 调用授权接口，此接口会返回状态码为302，从重定向链接中获取code
      await Http.request(
        "/open/oauth2/authorize?response_type=code&client_id=$clientId&allow=true&state=$state",
        data: {},
      );
    } on DioError catch (e) {
      if (e.response?.statusCode == 302) {
        final redirects = e.response?.headers["location"];
        if (redirects == null || redirects.isEmpty) {
          rethrow;
        }

        /// 获取从定向链接，从此链接中提取code
        final location = redirects.first;
        if (location == null) {
          rethrow;
        }
        final url = Uri.parse(location);
        if (!url.queryParameters.containsKey("code")) {
          rethrow;
        }
        code = url.queryParameters["code"];
      } else {
        rethrow;
      }
    }
    return code;
  }
}
