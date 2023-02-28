import 'package:im/core/http_middleware/http.dart';
import 'entity/invite_code.dart';

class InviteApi {
  static Future<String> getInviteUrl(Map params) async {
    final res = await Http.request(
      '/api/invite/GetCode',
      showDefaultErrorToast: true,
      data: params,
    );
    return res != null ? res['url'] : null;
  }

  static Future<EntityInviteUrl> getInviteInfo(Map params) async {
    Map res = await Http.request(
      '/api/invite/code',
      data: params,
    );
    if (res != null && params['type'] == 2) {
      final content = EntityInviteUrl.fromJson(res);
      if (content.url == null ||
          ((content.expire == '0' || content.number == '0') &&
              params['number'] != null)) {
        params['type'] = 1;
        if (params['number'] == null) {
          params['number'] = -1;
        }
        if (params['time'] == null) {
          params['time'] = -1;
        }
        res = await Http.request(
          '/api/invite/code',
          data: params,
        );
      }
    }
    return res != null ? EntityInviteUrl.fromJson(res) : null;
  }

  static Future getCodeInfo(String code,
      {bool showDefaultErrorToast = false,
      bool autoRetryIfNetworkUnavailable = false}) {
    return Http.request('/api/invite/codeInfo',
        showDefaultErrorToast: showDefaultErrorToast,
        data: {'c': code},
        autoRetryIfNetworkUnavailable: autoRetryIfNetworkUnavailable);
  }

  /// 取消邀请码
  static Future giveUpCode(String code,
      {bool showDefaultErrorToast = false,
      bool autoRetryIfNetworkUnavailable = false}) {
    return Http.request('/api/invite/cancel',
        showDefaultErrorToast: showDefaultErrorToast,
        data: {'code': code},
        autoRetryIfNetworkUnavailable: autoRetryIfNetworkUnavailable);
  }

  /// 邀请码管理例表
  /// eg: params : {'guild_id': 'xxxx', 'page': 0, 'size': 50}
  static Future getCodeList(Map params,
      {bool showDefaultErrorToast = false,
      bool autoRetryIfNetworkUnavailable = false}) {
    return Http.request('/api/invite/guildList',
        showDefaultErrorToast: showDefaultErrorToast,
        data: params,
        autoRetryIfNetworkUnavailable: autoRetryIfNetworkUnavailable);
  }

  /// 邀请码已邀请例表
  /// eg: params : {'code': 'xxxx', 'page': 0, 'size': 50}
  static Future getCodeInvitedList(Map params,
      {bool showDefaultErrorToast = false,
      bool autoRetryIfNetworkUnavailable = false}) {
    return Http.request('/api/invite/userlist',
        showDefaultErrorToast: showDefaultErrorToast,
        data: params,
        autoRetryIfNetworkUnavailable: autoRetryIfNetworkUnavailable);
  }

  /// 生成直播间分享链接
  /// @param channelId: 直播频道id
  /// @param type: 2: 根据配置现在是否有, 1: 保存新的配置
  /// @param time: -1: 不限时间
  /// @param number: -1: 不限次数
  static Future getLiveInviteUrl({
    String channelId,
    int type = 1,
    int time = -1,
    int number = -1,
  }) {
    return Http.request("/api/live/invite", data: {
      "channel_id": channelId,
      "type": type,
      "time": time,
      "number": number,
    });
  }
}
