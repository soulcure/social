import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:im/core/config.dart';
import 'package:im/locale/message_keys.dart';

class ApiUrl {
  // 服务
  // static String termsUrl = '${Config.protocolHost}/terms.html';

  // 用户协议
  static String get termsUrl {
    if (Get.locale.languageCode != MessageKeys.zh)
      return '${Config.protocolHost}/terms/terms_en.html';
    return '${Config.protocolHost}/terms/terms.html';
  }

  // 隐私政策
  static String get privacyUrl {
    if (Get.locale.languageCode != MessageKeys.zh)
      return '${Config.protocolHost}/privacy/privacy_en.html';
    return '${Config.protocolHost}/privacy/privacy.html';
  }

  // 服务器公约
  // static String conventionUrl = '${Config.protocolHost}/convention.html';
  static String get conventionUrl {
    if (Get.locale.languageCode != MessageKeys.zh)
      return '${Config.protocolHost}/convention/convention_en.html';
    return '${Config.protocolHost}/convention/convention.html';
  }

  // 支付授权协议
  static String get payAuthUrl {
    // if (Get.locale.languageCode != MessageKeys.zh)
    //   return '${Config.protocolHost}/pay/user-agreement_en.html';
    /// NOTE: 2022/1/17 业务只提供了中文的授权协议
    return '${Config.protocolHost}/pay/user-agreement.html';
  }

  // 反馈
  static String feedbackUrl = '${Config.protocolHost}/feedback.html';

  // 举报服务器
  static String reportUrl = '${Config.protocolHost}/reportServer.html';

  // 个人信息收集清单
  static String get personalInfoListUrl {
    if (Get.locale.languageCode != MessageKeys.zh)
      return '${Config.protocolHost}/personalInfoList/personalInfoList_en.html';
    return '${Config.protocolHost}/personalInfoList/personalInfoList.html';
  }

  // 第3方SDK目录
  static String get commonBillUrl {
    if (Get.locale.languageCode != MessageKeys.zh)
      return '${Config.protocolHost}/commonBill/commonBill_en.html';
    return '${Config.protocolHost}/commonBill/commonBill.html';
  }
}

///自动取消http请求的CancelToken
class AutoCancelToken {
  static Map<AutoCancelType, CancelToken> autoCancelTokenMap = {};

  ///先取消上次的请求，再返回CancelToken，
  static CancelToken get(AutoCancelType type) {
    cancel(type);
    autoCancelTokenMap[type] = CancelToken();
    return autoCancelTokenMap[type];
  }

  ///获取CancelToken
  static CancelToken getOnly(AutoCancelType type) {
    return autoCancelTokenMap[type] = CancelToken();
  }

  ///取消请求
  static void cancel(AutoCancelType type) {
    try {
      if (autoCancelTokenMap[type] != null &&
          !autoCancelTokenMap[type].isCancelled)
        autoCancelTokenMap[type].cancel();
    } catch (_) {}
  }

  ///退出登录时，取消autoCancelTokenMap里的请求
  static void cancelAll() {
    autoCancelTokenMap.forEach((key, value) {
      cancel(key);
    });
    autoCancelTokenMap.clear();
  }
}

///CancelToken的类型，对应http请求
enum AutoCancelType { dmList, myGuild2, search }
