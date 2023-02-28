import 'package:flutter/material.dart';
import 'package:im/core/openinstall.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/global.dart';
import 'package:im/pages/login/jverify_util.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/show_protocals_popup.dart';
import 'package:im/utils/universal_platform.dart';

class SensitiveSDKUtil {
  /// 用户同意相关协议后初始化相关敏感SDK
  ///
  /// 后续添加相关SDK，需先考虑使用插件检测是否存在敏感信息的获取，然后放在这个方法内处理
  /// 动此逻辑需要注意 [initDLog] 这个方法,app生命周期内只能调用一次
  static Future<void> handleEvents() async {
    if (!UniversalPlatform.isMobileDevice) return;
    // 1.openinstall会获取android mac地址
    Openinstall.init();
    // 2.androidinfo会获取androidId
    await Global.getAndroidDeviceInfo();
    // 3.一键登录会获取手机IMEI
    await JVerifyUtil.init();

    if (UniversalPlatform.isAndroid) await DLogManager.getInstance().initDLog();
  }

  /// 在登录页显式弹窗，让用户选择隐私政策同意与否
  ///
  /// 分下面两种情况
  /// 前提：若能进入主页or调用到login接口，则证明用户一定是在显式弹窗中同意了协议or在登录页中
  /// check了隐私协议box
  /// 1.同意，直接初始化相关SDK，再处理其它业务，如拉起一键登录(前提是一键登录环境满足);
  /// 2.拒绝，相关SDK的初始化工作会滞后
  ///   a.openinstall & 一键登录初始化需要时间，所以放在HomePage的initState中
  ///   b.androidInfo不耗时且登录后调用的接口需要androidInfo填充接口请求头信息，所以初始化
  /// 工作放在了login这个接口中
  static Future<void> request(BuildContext context) async {
    if (!UniversalPlatform.isMobileDevice) return;

    final cacheAgreedStatus = SpService.to.getBool(SP.agreedProtocals) ?? false;
    if (!cacheAgreedStatus) {
      // final bool agreed = await ProtocolDialog.show(context);
      final bool agreed = await showProtocalsPopup(context);
      if (agreed) await handleEvents();
    }
  }
}
