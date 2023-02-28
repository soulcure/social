import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/widgets/toast.dart';
import 'package:oktoast/oktoast.dart';

class BlackListApi {
  static const String BlackList = '/api/guild/blackList'; //黑名单列表
  static const String BlackRelieve = '/api/guild/blackRelieve'; //只解除黑名单

  static Future<Map> getBlackList(String guildId, int page, int pageSize,
      {CancelToken token}) async {
    try {
      final data = {
        'guild_id': guildId,
        'page': page,
        'pageSize': pageSize,
      };
      return await Http.request(BlackList, data: data, cancelToken: token);
    } catch (e) {
      print(e);
    }
    return null;
  }

  ///移除黑名单
  static Future<bool> removeBlackList(String guildId, String userId,
      {CancelToken token}) async {
    return _optionBlackList(guildId, userId, 0, token: token);
  }

  static Future<bool> _optionBlackList(String guildId, String userId, int type,
      {CancelToken token}) async {
    final data = {
      'guild_id': guildId,
      'relieve_user_id': userId,
      'is_relieve': type, //0为解禁
    };
    final res = await Http.request(BlackRelieve,
            data: data,
            showDefaultErrorToast: true,
            isOriginDataReturn: true,
            cancelToken: token)
        .catchError((e) => null);

    if (res is Map) {
      final desc = res['desc'] as String;
      if (res['code'] == 1000) {
        Toast.iconToast(icon: ToastIcon.success, label: '解除成功'.tr);
        return true;
      } else {
        if (desc.hasValue) showToast(desc);

        if (res['code'] == 1108) return true;
      }
    }
    return false;
  }
}
