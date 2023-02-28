import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/api/check_info_api.dart';
import 'package:im/api/user_api.dart';
import 'package:im/common/extension/future_extension.dart';
import 'package:im/core/config.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/login/model/user_extr_model.dart';
import 'package:im/pay/pay_manager.dart';
import 'package:im/routes.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/invite_code/invite_code_util.dart';
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:im/widgets/dialog/show_bind_dialog.dart';
import 'package:pedantic/pedantic.dart';

enum LoginType {
  /// 普通手机号登录
  LoginTypePhoneNum,

  /// 极光一键登录
  LoginTypeOneKey,

  /// 微信登录
  LoginTypeWX,

  /// apple登录
  LoginTypeApple,
}

class LoginThreshold {
  ///　一键登录/绑定还是手机号登录/绑定，调用login后，都应该走这里处理
  ///
  ///　[resultMap] login api返回结果
  ///  [oneKey] 一键绑定情况，在取消重复绑定时不需要pop page
  ///　[country] CountryModel
  /// [thirdParty] 如果微信重复绑定的时候，需要传此参数过来
  static Future entry(
    BuildContext context,
    Map resultMap, {
    bool oneKey = false,
    String thirdParty = "",
    String country = "",
    LoginType loginType = LoginType.LoginTypePhoneNum,
  }) async {
    Global.user = LocalUser.fromJson(resultMap)..cache();
    // 保存区号
    if (country.isNotEmpty) {
      unawaited(SpService.to.setString(SP.country, country));
    }

    /// 手机验证码登录
    String loginTypeStr = "other_number_login";
    if (loginType == LoginType.LoginTypeOneKey) {
      /// 本机号码一键登录
      loginTypeStr = "oneclick_login";
    } else if (loginType == LoginType.LoginTypeWX) {
      /// 微信授权登录
      loginTypeStr = "wechat_login";
    } else if (loginType == LoginType.LoginTypeApple) {
      /// apple授权登录
      loginTypeStr = "apple_login";
    }
    // 保存token
    Config.token = resultMap['sign'];
    if (kIsWeb) {
      _setCookie(resultMap['sign']);
    } else
      unawaited(SpService.to.setString(SP.token, resultMap['sign']));
    // 保存时间戳
    unawaited(SpService.to
        .setInt(SP.loginTime, DateTime.now().millisecondsSinceEpoch));
    debugPrint('resultMap: $resultMap');
    if (resultMap['binded_data'] != null) {
      final UserBoundData boundData =
          UserBoundData.fromMap(resultMap['binded_data']);
      await _changeBindLogin(
          context, boundData, oneKey, thirdParty, loginTypeStr);
    } else if (resultMap['pre_data'] != null) {
      final UserPreData preData = UserPreData.fromMap(resultMap['pre_data']);
      await _thirdLogin(context, preData, loginTypeStr);
    } else {
      // 上面两个字段都为空走原手机号登录流程
      final bool registerNotComplete = resultMap['n'] == 1 ||
          (Global.user.nickname?.isEmpty ?? true) ||
          (Global.user.gender == 0) ||
          (Global.user.avatar?.isEmpty ?? true);
      await _numberLogin(context, registerNotComplete, loginTypeStr);
    }
  }

  ///　换绑登录流程，微信有可能重复绑定同一个手机
  static Future _changeBindLogin(
    BuildContext context,
    UserBoundData boundData,
    bool oneKey,
    String thirdParty,
    String loginTypeStr,
  ) async {
    debugPrint('boundData: $boundData');
    await BindDialog.show(
      context,
      boundData.oldName,
      boundData.newName,
      onCancel: () {
        if (!oneKey) {
          ///取消绑定，清除账号
          Config.clearToken();
          Get.back();
        }
      },
      onConfirm: () async {
        Loading.show(context);
        try {
          await UserApi.changeBind(thirdParty);
        } catch (e) {
          Loading.hide();
          DLogManager.getInstance().customEvent(
              actionEventId: 'login_status',
              actionEventSubId: '0',
              pageId: 'page_login',
              actionEventSubParam: e?.toString() ?? '',
              extJson: {
                "login_type": loginTypeStr,
                'invite_code': InviteCodeUtil.inviteCode
              });
          return;
        }
        Loading.hide();
        // await Routes.pushHomePage(context);
        Routes.popAndPushHomePage(context).unawaited;
        await _afterLogin(context);
        GlobalState.isHomePageInited.value = true;
        DLogManager.getInstance().customEvent(
            actionEventId: 'login_status',
            actionEventSubId: '1',
            pageId: 'page_login',
            extJson: {
              "login_type": loginTypeStr,
              'invite_code': InviteCodeUtil.inviteCode
            });
      },
    );
  }

  ///　第三方(微信)登录然后绑定未注册过的手机号后的流程处理
  static Future _thirdLogin(
    BuildContext context,
    UserPreData preData,
    String loginTypeStr,
  ) async {
    debugPrint('userPreData: $preData');
    bool passed = false;
    //　检测微信昵称是否合法
    if (preData.nickname != null) {
      Loading.show(context);
      passed = await CheckUtil.startCheck(
          TextCheckItem(preData.nickname, TextChannelType.NICKNAME));
      Loading.hide();
    }
    if (!preData.isNotEmpty() || preData.gender == 0 || !passed) {
      // 第三方信息有空，或者性别未确定，昵称不合法都要进资料修改页面
      Global.user.nickname = preData.nickname;
      Global.user.gender = preData.gender;
      Global.user.avatar = preData.avatar;
      unawaited(Routes.pushLoginModifyUserInfoPage(context));
    } else {
      // 合法直接更新进入主页
      await _updateUserInfo(context, Global.user.id, preData.nickname,
          preData.avatar, preData.gender);
    }
    await _afterLogin(context);

    DLogManager.getInstance().customEvent(
        actionEventId: 'login_status',
        actionEventSubId: '1',
        pageId: 'page_login',
        extJson: {
          "login_type": loginTypeStr,
          'invite_code': InviteCodeUtil.inviteCode
        });
  }

  /// 原手机号登录方式登录后处理流程
  static Future _numberLogin(
    BuildContext context,
    bool newUser,
    String loginTypeStr,
  ) async {
    /// todo 优化审核后去掉，临时加在这里解决头像不审核问题
    await CheckInfoApi.postCheckInfo(context);
    // 新用户跳转到修改信息页
    if (newUser) {
      await Routes.pushLoginModifyUserInfoPage(context);
    } else {
      // unawaited(Routes.pushHomePage(context, queryString: webUtil.getQuery()));
      // unawaited(
      // Routes.popAndPushHomePage(context, queryString: webUtil.getQuery()));

      Routes.popAndPushHomePage(context, queryString: webUtil.getQuery())
          .unawaited;
    }
    await _afterLogin(context);
    GlobalState.isHomePageInited.value = true;

    DLogManager.getInstance().customEvent(
        actionEventId: 'login_status',
        actionEventSubId: '1',
        pageId: 'page_login',
        extJson: {
          "login_type": loginTypeStr,
          'invite_code': InviteCodeUtil.inviteCode
        });
  }

  static Future _afterLogin(BuildContext context) async {
    await CheckInfoApi.postCheckInfo(context);

    /// 用户登录成功后,开始苹果支付监听(为了用户补单)
    unawaited(PayManager.startObservingPaymentQueue());

    /// 登录成功数据上报
    unawaited(DLogManager.getInstance().userLogin());
  }

  static Future<void> _updateUserInfo(BuildContext context, String userId,
      String nickname, String avatar, int gender) async {
    Loading.show(context);
    try {
      await UserApi.updateUserInfo(userId, nickname, avatar, gender);
      DLogManager.getInstance().customEvent(
          actionEventId: 'register_info_status',
          actionEventSubId: '1',
          pageId: 'page_register_info',
          extJson: {"invite_code": InviteCodeUtil.inviteCode});
    } catch (e) {
      Loading.hide();
      DLogManager.getInstance().customEvent(
          actionEventId: 'register_info_status',
          actionEventSubId: '0',
          actionEventSubParam: e?.toString(),
          pageId: 'page_register_info',
          extJson: {"invite_code": InviteCodeUtil.inviteCode});
      return;
    }
    Loading.hide();
    // await Routes.pushHomePage(context);
    Routes.popAndPushHomePage(context).unawaited;
    await Global.user.update(
      nickname: nickname,
      avatar: avatar,
      gender: gender,
    );
    GlobalState.isHomePageInited.value = true;
  }

  static void _setCookie(String token) {
    final int day = (SpService.to.getBool(SP.rememberPwd) ?? false) ? 30 : null;
    const tokenKey = 'token';
    // 设置当前域名token
    webUtil.setCookie(tokenKey, token, secure: !Config.isDebug, expires: day);
    // 设置一级域名token
    webUtil.setCookie(
      tokenKey,
      token,
      secure: !Config.isDebug,
      domain: '.${Config.webDomain}',
      path: '/',
      expires: day,
    );
  }
}
