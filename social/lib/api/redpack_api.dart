import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/redpack/open_pack/models/open_redpack_collected_info_model.dart';
import 'package:im/app/modules/redpack/send_pack/data/grab_redpack_resp.dart';
import 'package:im/app/modules/redpack/send_pack/data/send_redpack_resp.dart';
import 'package:im/core/config.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/http_middleware/interceptor/logging_interceptor.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/utils.dart';
import 'package:oktoast/oktoast.dart';

enum BindType {
  // 重复绑定
  repeat,
  // 支付宝已被绑定
  bound,
  // 绑定成功
  success,
  // 绑定失败
  fail,
  // 服务器异常
  serverFail,
}

extension BindTypeEx on BindType {
  String get value => [
        '重复绑定，请先解绑',
        '已有绑定信息，请刷新界面',
        '绑定成功',
        '绑定失败，请重试',
        '网络质量不佳，请重试',
      ][index];
}

enum SendCodeType {
  // 验证码正确
  success,
  // 验证码错误
  fail,
  // 服务器异常
  serverFail,
}

extension SendCodeTypeEx on SendCodeType {
  String get value => [
        '验证码正确',
        '验证码不正确，请重新输入',
        '网络质量不佳，请重试',
      ][index];
}

class ResData {
  final Object type;
  final String data;

  ResData(this.type, this.data);
}

class RedPackAPI {
  ///获取支付宝授权前所需的服务码
  static Future<ResData> getAlipayAuthInfo(String code) async {
    SendCodeType sendCodeType = SendCodeType.success;

    final res = await Http.request(
      "/api/RedBag/GetInfoStr",
      data: {
        'code': code,
      },
    ).catchError((e, s) {
      if (e is RequestArgumentError) {
        if (e.code == 1018) {
          sendCodeType = SendCodeType.fail;
        }
      } else {
        logger.severe('/api/RedBag/GetInfoStr error', e, s);
        sendCodeType = SendCodeType.serverFail;
      }
    });

    String resultData;
    if (sendCodeType == SendCodeType.success) {
      if (res is Map && res['infoStr'] != null) {
        resultData = res['infoStr'];
      } else {
        sendCodeType = SendCodeType.fail;
      }
    }

    return Future.value(ResData(sendCodeType, resultData));
  }

  ///获取支付宝授权的签名
  static Future getAliAuthCode(String code) async {
    final res =
        await Http.request("/api/RedBag/GetInfoStr", data: {"code": code});
    return res;
  }

  ///发红包（参数：服务器id、频道id、金额、红包数量）
  /// type: 1 群拼手气红吧 ,2群普通红包，3私信红包
  /// words: 红包祝福语
  /// picture: 红包封面图片的picture
  static Future<SendRedPackResp> sendRedPack(
    String guildId,
    String channelId,
    double money,
    int num,
    int type,
    String words,
    String picture,
    String quoteL1,
    String quoteL2,
  ) async {
    final res = await Http.request(
      "/api/RedBag/startRedBag",
      options: Options(
        sendTimeout: 5000,
        receiveTimeout: 5000,
      ),
      showDefaultErrorToast: true,
      data: {
        "guild_id": guildId,
        "channel_id": channelId,
        "money": money,
        "num": num,
        "redbag_type": type,
        "words": words,
        "picture": picture,
        "quote_l1": quoteL1,
        "quote_l2": quoteL2,
      },
    ).catchError((e) {
      logger.severe("sendRedPack e=$e");
      return null;
    });

    if (res is Map) {
      return SendRedPackResp.fromMap(res);
    }

    return null;
  }

  ///抢红包(参数：服务器id、频道id、红包秘钥)
  static Future<GrabRedPackResp> grabRedPacketKey(
      String guildId, String channelId, String forder) async {
    const path = "/api/RedBag/getRedBag";
    final data = {
      "guild_id": guildId,
      "channel_id": channelId,
      "forder": forder,
    };

    final res =
        await httpPost(path, data, true, ignoreCodes: [3008]).catchError((e) {
      logger.severe("$path e=$e");
      if (e is RequestArgumentError) {
        /// NOTE: 2022/1/19 入乡随俗，抛业务码让调用者进行业务操作
        throw e;
      }
    });
    if (res is Map) {
      return GrabRedPackResp.fromMap(res);
    }
    return null;
  }

  ///绑定支付宝账号(参数：支付宝授权码)
  static Future<ResData> bindUid(String authCode, bool isFirst) async {
    BindType bindType = BindType.success;

    final res = await Http.request(
      "/api/RedBag/BindUid",
      isOriginDataReturn: true,
      data: {
        "auth_code": authCode,
        "again": isFirst ? 0 : 1,
      },
    ).catchError((e, s) {
      logger.severe('/api/RedBag/BindUid error', e, s);
      bindType = BindType.serverFail;
    });

    String data;
    if (bindType == BindType.success) {
      if (res is Map) {
        if (res['status'] == false) {
          if (res['code'] == 3010 && res['data'] != null) {
            /// NOTE: 2022/1/8 3010代表被其他用户绑定，需要用户确认换绑
            data = res['data']['other_nickname'];
            bindType = BindType.bound;
          } else if (res['code'] == 3013) {
            bindType = BindType.repeat;
          } else {
            bindType = BindType.fail;
          }
        }
      } else {
        bindType = BindType.fail;
      }
    }

    return ResData(bindType, data);
  }

  ///检测是否绑定支付宝
  static Future<String> checkBindAliPay() async {
    final res = await Http.request(
      "/api/RedBag/CheckBind",
      data: {"user_uid": Global.user.id},
    ).catchError((e) {
      logger.severe("checkBindAliPay e=$e");
      return null;
    });
    if (res is Map) {
      return res['alipay_uid'] as String;
    }
    return null;
  }

  /// 获取抢到红包的用户列表
  static Future<OpenRedPackCollectedInfoModel> getOpenRedPackRecord(
      String redPackId, String lastRedPackId) async {
    final res = await Http.request("/api/RedBag/GetRedBagRecord",
            data: {"forder": redPackId, "last_sub_forder": lastRedPackId})
        .catchError((e) {
      logger.severe("openRedPackRecord e=$e");
      return null;
    });
    if (res is Map) {
      return OpenRedPackCollectedInfoModel.fromJson(res);
    }
    return null;
  }

  /// 获取绑定支付宝信息
  static Future<String> getBindAlipayInfo() async {
    final res = await Http.request(
      "/api/RedBag/GetMyBind",
    ).catchError((e, s) {
      logger.severe('/api/RedBag/GetMyBind error', e, s);
      showToast('网络质量不佳，请重试');
    });

    if (res is Map) {
      return res['nickname'];
    } else {
      return null;
    }
  }

  /// 解除支付宝绑定信息
  static Future<String> unbindAlipay(String code) async {
    final res = await Http.request(
      "/api/RedBag/UnBindUid",
      data: {
        'code': code,
      },
    ).catchError((e, s) {
      if (e is RequestArgumentError) {
        if (e.code == 1018) {
          showToast('验证码输入错误，请重试');
        }
      } else {
        logger.severe('/api/RedBag/UnBindUid error', e, s);
        showToast('网络质量不佳，请重试');
      }
    });

    if (res is Map && res['alipay_uid'] != null) {
      return res['alipay_uid'].toString();
    } else {
      return null;
    }
  }

  ///发起表态的http请求
  static Future httpPost(String path, Map data, bool showDefaultErrorToast,
      {List<int> ignoreCodes}) async {
    final BaseOptions baseOptions = BaseOptions(
      connectTimeout: 5000,
      baseUrl: Config.host,
      headers: {
        HttpHeaders.userAgentHeader:
            "platform:${Global.deviceInfo.systemName.toLowerCase()};channel:${Config.channel};version:${Global.packageInfo.version};",
      },
    );

    final dio = Dio(baseOptions); //dio 构造为 factory 可以直接使用
    dio.interceptors.add(LoggingInterceptor());

    final options = Options();
    options
      ..responseType = ResponseType.json
      ..sendTimeout = 5000
      ..receiveTimeout = 5000;
    options.headers = Http.getHeader(headers: options.headers, data: data);

    ///添加代理
    final String proxy = SpService.to.getString(SP.proxySharedKey);
    if (Http.useProxy && isNotNullAndEmpty(proxy)) Http.setProxy(dio, proxy);

    final response = await dio
        .post(path, data: data, options: options)
        .onError((error, stackTrace) {
      return null;
    });
    if (response == null) {
      showToast("系统繁忙，请稍后重试".tr);
    } else if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map resData = response.data;
      if (resData["status"] == true) {
        return resData["data"];
      } else {
        final String message = resData["message"];
        final errorMes = errorCode2Message[message] ?? resData["desc"];

        if (showDefaultErrorToast && errorMes.hasValue) {
          /// NOTE: 2022/1/20 如果要Toast则忽略错误码
          if (ignoreCodes == null ||
              !ignoreCodes.contains(int.parse(message))) {
            showToast(errorMes);
          }
        } else {
          showToast("系统繁忙，请稍后重试".tr);
        }

        throw RequestArgumentError(int.parse(message),
            message: resData["desc"] ?? errorMes);
      }
    }
  }
}
