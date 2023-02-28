import 'dart:async';
import 'dart:convert';

import 'package:im/core/config.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/home_page.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/tool/url_handler/live_link_handler.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/invite_code/invite_code_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:openinstall_flutter_plugin/openinstall_flutter_plugin.dart';

class Openinstall {
  static void init() {
    if (UniversalPlatform.isMacOS) return;

    final _openinstallFlutterPlugin = OpeninstallFlutterPlugin();
    // 用来记录wake方法是否执行过
    var wakeupIsDone = false;

    /// 获取安装时的参数(此接口只返回第一次安装时的参数,
    /// 通过其他链接打开返回的也是第一次安装的参数)
    Future<dynamic> installHandler(Map<String, dynamic> data) async {
      try {
        /// 首先判断携带参数安装方法是否有数据
        if (data != null && data['bindData'] != null) {
          logger.info('openInstall installHandler data :$data');

          /// 已经通过唤醒获取过参数就不错任何处理了
          if (wakeupIsDone) {
            logger.info('openInstall installHandler wakeupIsDone 为 true');
            return;
          }
          dispatchEvent(data, 'installHandler');
        } else {
          logger.warning('openInstall installHandler bindData 为空');
        }
      } catch (e) {
        logger.warning('openInstall 异常 installHandler e :$e');
      }
    }

    /// 获取唤醒参数(快速下载和一键跳转)
    Future wakeupHandler(Map<String, dynamic> data) async {
      try {
        if (data != null && data['bindData'] != null) {
          wakeupIsDone = true;
          dispatchEvent(data, 'wakeupHandler');
        } else {
          logger.warning('openInstall wakeupHandler bindData 为空');
        }
      } catch (e) {
        logger.warning('openInstall 异常 wakeupHandler e :$e');
      }
    }

    /// 初始化 openInstall
    _openinstallFlutterPlugin.init(wakeupHandler);

    /// 是否首次打开app
    final isFirstOpenApp = !SpService.to.containsKey(SP.isFirstOpenApp);
    GlobalState.isFirstOpenApp = isFirstOpenApp;

    /// 首次,通过installHandler获取安装参数
    if (isFirstOpenApp) {
      _openinstallFlutterPlugin.install(installHandler);
      SpService.to.setBool(SP.isFirstOpenApp, false);
    }
    logger.info('openInstall初始化');
  }

  /// openInstall事件分发
  /// 原有的邀请码/链接功能没有加入scene值，后续为作区分，可在接入openInstall时添加场景值
  /// 1.邀请码/链接功能 scene  null
  /// 2.直播分享链接且无邀请码/链接(即无服务器分享权限时) scene 'live'
  /// ...
  static void dispatchEvent(Map<String, dynamic> data, String flag) {
    logger.info('openInstall data :$data flag: $flag');
    if (data['bindData'] == null || data['bindData'].isEmpty) return;
    final Map<String, dynamic> params = jsonDecode(data['bindData']);
    if (params == null || params.isEmpty) return;
    if (params['scene'] == 'live') {
      liveShareWithoutInviteHandler(params);
    } else {
      inviteHandler(params);
    }
  }

  /// 处理原有的邀请码/链接的情况
  static void inviteHandler(Map<String, dynamic> params) {
    try {
      final scheme = Uri.parse(Config.webLinkPrefix).scheme;
      final host = Uri.parse(Config.webLinkPrefix).host;
      final uri = Uri(
        scheme: scheme,
        host: host,
        path: params['c'],
        queryParameters: params,
      );
      final url = uri.toString();
      logger.info('openInstall 进入 homePageParams url : $url');
      HomePage.inviteStream
          .add(InviteUrlStream(url, InviteURLFrom.openInstall));
      InviteCodeUtil.setInviteCode(url);
    } catch (e) {
      logger.warning('openInstall解析邀请链接出错 ${e.toString()}');
    }
  }

  /// 处理直播分享链接，且无邀请码/链接的情况
  static void liveShareWithoutInviteHandler(Map<String, dynamic> params) {
    // 参数中url经过了编码，需解码处理
    final liveUrl = Uri.decodeComponent(params['liveUrl'] ?? '');
    LiveLinkHandler().handle(liveUrl);
  }
}
