import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/oauth_ben.dart';
import 'package:im/api/oauth_api.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/utils/deeplink_processor.dart';
import 'package:meta/meta.dart';

class FanbookAuthController extends GetxController {
  final BuildContext context;

  /// 三方应用在fanbook后台申请的client id
  final String clientId;

  /// 三方应用发送请求的唯一标识，授权结束时fanbook会将其原样返回，大小不能超过1k
  final String state;

  /// 获取三方app信息
  Future<AppInfo> getAppInfo;

  final DeepLinkTaskNotifier notifier;

  /// 是否是三方app唤起的
  bool get fromThirdParty => notifier != null;

  FanbookAuthController({
    @required this.context,
    @required this.clientId,
    this.state,
    this.notifier,
  });

  @override
  void onInit() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    getAppInfo = () async {
      return OAuthAPI.getAppInfo(clientId);
    }();
    super.onInit();
  }

  /// 用户确认授权
  Future authConfirmed() async {
    Loading.show(context);

    int errCode;
    String code;
    try {
      /// 获取code
      code = await OAuthAPI.auth(clientId, state: state);
      if (code == null) {
        /// 获取的code无效
        errCode = DeepLinkTaskErrCode.NORMAL;
      } else {
        /// 授权成功
        errCode = DeepLinkTaskErrCode.SUCCESS;
      }
    } on RequestArgumentError {
      errCode = DeepLinkTaskErrCode.AUTH_REQ_FAILED;
    } on DioError catch (e) {
      if (e.response.statusCode == 500) {
        /// 授权验证失败
        errCode = DeepLinkTaskErrCode.AUTH_FAILED;
      } else {
        /// 网络请求失败
        errCode = DeepLinkTaskErrCode.AUTH_REQ_FAILED;
        print("Fanbook Oauth request error: $e");
      }
    } catch (e, s) {
      /// 其他未知异常
      errCode = DeepLinkTaskErrCode.NORMAL;
      print("Fanbook Oauth error: $e:\n$s");
    }
    Loading.hide();

    if (errCode == DeepLinkTaskErrCode.SUCCESS) {
      notifier?.onSuccess(result: code);
    } else {
      notifier?.onError(errCode);
    }

    if (!fromThirdParty) {
      /// 不是通过第三方应用唤起，返回到上个页面
      Navigator.of(Get.context).pop(code);
    }
  }

  /// 用户取消
  void authCancel() {
    if (fromThirdParty) {
      notifier.onError(DeepLinkTaskErrCode.AUTH_CANCEL);
    } else {
      Navigator.of(Get.context).pop();
    }
  }

  void retry() {
    update();
  }
}
