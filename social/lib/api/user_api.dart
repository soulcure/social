import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:im/api/entity/guild_folder.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/config.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/global.dart';
import 'package:im/utils/fb_encryption.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:oktoast/oktoast.dart';

import 'data_model/user_info.dart';

class UserApi {
  static String updateTokenUrl = '/api/common/ctk';

  static Future<List<UserInfo>> getUserInfo(List<String> ids,
      {String guildId, bool autoRetryIfNetworkUnavailable = false}) async {
    try {
      final List result = await Http.request(
        "/api/user/getUser",
        data: {
          "user_ids": ids.join(","),
          if (guildId != null) "guild_id": guildId,
        },
        autoRetryIfNetworkUnavailable: autoRetryIfNetworkUnavailable,
      );
      if (result == null || result.isEmpty) return null;
      return result.map((e) => UserInfo.fromJson(e)).toList();
    } on RequestArgumentError catch (_) {
      return const [];
    }
  }

  static Future<Map<String, List<UserInfo>>> getUserInfoForGuild(
      Map<String, Set<String>> idsMap,
      {bool autoRetryIfNetworkUnavailable = false}) async {
    final Map<String, List<UserInfo>> returnMap = {};
    final Map<String, List<String>> params = idsMap.map((key, value) {
      return MapEntry(key, value.toList(growable: false));
    });
    // debugPrint('getChat gu http - idsMap: $idsMap');
    final result = await Http.request(
      "/api/guildUser/getUser",
      data: {'guild_users': params},
      autoRetryIfNetworkUnavailable: autoRetryIfNetworkUnavailable,
    );
    if (result == null) return returnMap;
    if (result is Map && result.isNotEmpty) {
      result.forEach((key, value) {
        try {
          final gId = key as String;
          final List<UserInfo> list = [];
          final dataList = value as List;
          // debugPrint('getChat gu http - key: $gId');
          if (dataList != null && dataList.isNotEmpty) {
            // debugPrint('getChat gu http - length: ${dataList.length}');
            dataList.forEach((d) {
              // debugPrint('getChat gu http - json: $d');
              final user = UserInfo.fromJson(d);
              if (user.gnick.hasValue) {
                user.updateGuildNickNames({gId: user.gnick}, needSave: false);
              }
              list.add(user);
            });
            returnMap[gId] = list;
          }
        } catch (e) {
          debugPrint('getChat gu http - error: $e');
        }
      });
    }
    return returnMap;
  }

  // 22/04/14 新增 nft 头像
  static Future updateUserInfo(
    String userId,
    String nickname,
    String avatar,
    int gender, {
    String avatarNftId,
  }) {
    return Http.request("/api/user/updateInfo",
        showDefaultErrorToast: true,
        data: {
          "user_id": userId,
          "nickname": nickname,
          "avatar": avatar,
          "gender": gender,
          "avatar_nft_id": avatarNftId,
        });
  }

  static Future changeOnlineStatus(String userId, int status) {
    return Http.request("/api/user/onlineStatus", data: {
      "user_id": userId,
      "status": status,
    });
  }

  static Future sendCaptcha(int mobile, String device, String areaCode,
      {String codeType}) {
    return Http.request("/api/common/verification",
        showDefaultErrorToast: true,
        data: {
          "mobile": fbEncrypt(mobile.toString()),
          "device": device,
          "area_code": areaCode,
          "code_type": codeType, // 用于区分不同类型的短信验证
          "encrypt_type": "FBE",
        });
  }

  static Future login(int mobile, String code, String device, String areaCode,
      {String thirdParty = ""}) async {
    // 登录后的接口需要用到deviceInfo的信息，所以这里获取一下，方法内部已经做了平台兼容处理
    await Global.getAndroidDeviceInfo();
    return Http.request("/api/user/login", showDefaultErrorToast: true, data: {
      "type": "mobile",
      "third_party": thirdParty,
      "mobile": fbEncrypt(mobile.toString()),
      "code": fbEncrypt(code),
      "device": device,
      "area_code": areaCode,
      "encrypt_type": "FBE",
    });
  }

  static Future loginOneKey(String loginToken, {String thirdParty = ""}) async {
    await Global.getAndroidDeviceInfo();
    final String device = getPlatform();
    return Http.request("/api/user/login", showDefaultErrorToast: true, data: {
      "type": "JiGuang",
      "third_party": thirdParty,
      "loginToken": loginToken,
      "device": device,
    });
  }

  static Future loginWx(String code) {
    return Http.request(
      "/api/user/loginwx",
      showDefaultErrorToast: true,
      data: {
        "code": code,
      },
    );
  }

  static Future loginApple(Map<String, String> data) {
    return Http.request(
      "/api/user/loginapple",
      showDefaultErrorToast: true,
      data: data,
    );
  }

  static Future changeBind(String thirdParty) {
    return Http.request(
      "/api/user/changebind",
      showDefaultErrorToast: true,
      data: {
        "third_party": thirdParty,
      },
    );
  }

  static Future updateSetting({
    bool defaultGuildsRestricted,
    Map<String, bool> friendSourceFlags,
    List<String> restrictedGuilds,
    List<String> mutedChannels,
    bool notificationMute,
    List<GuildFolder> guildFolders,
  }) {
    final Map<String, dynamic> data = {
      'user_id': Global.user.id,
      'default_guilds_restricted': defaultGuildsRestricted,
      'friend_source_flags': friendSourceFlags,
      'restricted_guilds': restrictedGuilds,
      'notification_mute': notificationMute,
      'guild_folders': guildFolders,
    };
    if (mutedChannels != null) {
      data['mute'] = {'channel': mutedChannels};
    }
    data.removeWhere((key, value) => value == null);
    return Http.request(
      "/api/userSetting/setting",
      showDefaultErrorToast: true,
      data: data,
    );
  }

  static Future getSetting() {
    return Http.request("/api/userSetting/get", data: {
      "user_id": Global.user.id,
    });
  }

  /// type: [video|channel|guild]
  static Future<bool> getAllowRoster(String type) async {
    if (Config.permission != null) {
      return Config.permission[type];
    }
    try {
      final base64Str = await Http.request('/api/common/allow_v2');
      if (base64Str == null) return false;

      final Uint8List gzipBytes = base64.decode(base64Str);
      String value = '';
      if (kIsWeb) {
        value = webUtil.gzip(gzipBytes);
      } else {
        final Uint8List asciiBytes = gzip.decode(gzipBytes);
        value = ascii.decode(asciiBytes);
      }
      final Map json = jsonDecode(value);
      Config.permission = json;
      return json[type];
    } catch (e) {
      return false;
    }
  }

  static Future checkToken(String authorization, {int sendTimeout = 3000}) {
    return Http.request('/api/user/ct',
        options: Options(
            sendTimeout: sendTimeout,
            headers: {'Authorization': authorization}));
  }

  static Future updateToken() {
    return Http.request(UserApi.updateTokenUrl,
        options: Options(
            headers: {'Content-Type': 'application/x-www-form-urlencoded'}));
  }

  static Future delJPushAlias() async {
    final res = await Http.request("/api/user/delAlias");
    return res;
  }

  /// 根据user_id查看实名认证结果 1000，实名认证通过，1105，没通过
  static Future<int> checkByUid(String userId) async {
    dynamic res;
    res = await Http.request('/api/ID/CheckByUid',
        data: {
          "user_id": userId,
        },
        showDefaultErrorToast: true,
        isOriginDataReturn: true);
    return res['code'];
  }

  /// 根据user_id查看问卷填写 1000，填写了问卷，1109，没填写问卷
  static Future<int> checkQTForm(String userId) async {
    dynamic res;
    res = await Http.request(
      '/api/ID/CheckQTForm',
      data: {
        "user_id": userId,
      },
      isOriginDataReturn: true,
    );
    return res['code'];
  }

  ///上报问卷完成状态
  static Future<int> completeQTForm(String userId) async {
    dynamic res;
    res = await Http.request('/api/ID/CompleteQTForm',
        data: {
          "user_id": userId,
        },
        showDefaultErrorToast: true,
        isOriginDataReturn: true);
    return res['code'];
  }

  ///fixme: 数字钱包实名认证
  static Future<bool> walletVerified(
    String mobile,
    String code,
    String userName,
    String idNumber,
  ) async {
    final res = await Http.request(
      '/api/wallet/open',
      data: {
        "mobile": fbEncrypt(mobile),
        "code": fbEncrypt(code),
        "id_name": fbEncrypt(userName),
        "id_number": fbEncrypt(idNumber),
        "encrypt_type": "FBE",
      },
      isOriginDataReturn: true,
    ).onError((error, stackTrace) => null);
    if (res == null) {
      showToast("网络质量不佳，请重试".tr);
      return false;
    } else if (res['status'] != null && res['status'] == false) {
      //  错误码：8004为认证成功（通过后再次请求认证时返回的结果）
      final int code = res['code'] as int ?? 0;
      if (code == 8004) {
        return true;
      }
      showToast(res['desc'] as String ?? "服务器开小差了~".tr);
      return false;
    }
    return true;
  }
}
