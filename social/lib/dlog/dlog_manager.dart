import 'dart:convert';

import 'package:devicelocale/devicelocale.dart';
import 'package:fb_carrier_info_plugin/fb_carrier_info_plugin.dart';
import 'package:flutter/cupertino.dart';
import 'package:im/dlog/model/dlog_common_model.dart';
import 'package:im/dlog/model/dlog_extension_event_model.dart';
import 'package:im/dlog/model/dlog_user_login_model.dart';
import 'package:im/dlog/model/dlog_user_logout_model.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:system_info/system_info.dart';
import 'package:uuid/uuid.dart';

import 'business/dlog_report_data_manager.dart';
import 'model/dlog_custom_event_model.dart';
import 'model/dlog_device_start_model.dart';
import 'model/dlog_report_model.dart';

class DLogManager with WidgetsBindingObserver {
  static final DLogManager _instance = DLogManager._();

  factory DLogManager() => _instance;

  /// 防止初始化多次调用
  bool isInit = false;

  DLogManager._();

  // 静态、同步、私有访问点
  static DLogManager getInstance() {
    return _instance;
  }

  Future<void> initDLog() async {
    if (isInit) return;
    try {
      isInit = true;

      /// 添加应用生命周期监听
      WidgetsBinding.instance.addObserver(this);

      /// 开启上报服务
      await DLogReportDataManager.instance.startService();

      /// 设备启动事件
      await deviceStart();
    } catch (e) {
      logger.warning(e);
    }
  }

  ///生命周期变化时回调
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    try {
      if (state == AppLifecycleState.resumed) {
        userLogin();
        guildLogin();
      } else if (state == AppLifecycleState.paused) {
        /// 此处guildLogout需要放在userLogout前面
        /// 因为内部有sessionId维护
        guildLogout();
        userLogout();
      }
    } catch (e) {
      logger.severe(e);
    }
  }

  /// 设备启动
  Future<void> deviceStart() async {
    try {
      final DLogDeviceStartModel model = DLogDeviceStartModel();
      model.sysLang = await Devicelocale.currentLocale;

      String operator = "00";
      if (UniversalPlatform.isMobileDevice) {
        final operatorType = await FbCarrierInfoPlugin.operatorType;
        if (operatorType == '1') {
          operator = '01';
        } else if (operatorType == '2') {
          operator = '02';
        } else if (operatorType == '3') {
          operator = '03';
        }
      }

      model.operator = operator;
      if (UniversalPlatform.isMobileDevice) {
        model.network = await FbCarrierInfoPlugin.netWorkType;
      }
      const int MEGABYTE = 1024 * 1024;

      try {
        final memoryMb = SysInfo.getTotalPhysicalMemory() ~/ MEGABYTE;
        model.memoryMb = memoryMb.toString();
      } catch (e) {
        model.memoryMb = '';
      }
      final mapData = model.toJson();

      reportDataWithModel(mapData);
    } catch (e) {
      logger.warning(e);
    }
  }

  /// 用户登录
  Future<void> userLogin({Map map}) async {
    try {
      DLogCommonModel.getInstance().loginStartTime =
          DateTime.now().millisecondsSinceEpoch;
      final DLogUserLoginModel model = DLogUserLoginModel();
      model.loginLogType = "app_login";
      model.extJson = map ?? {};
      final mapData = model.toJson();

      if (model.userId == null || model.userId.isEmpty) return;
      reportDataWithModel(mapData);
    } catch (e) {
      logger.warning(e);
    }
  }

  /// 用户登出
  void userLogout({Map map}) {
    try {
      /// 登录手机时间戳
      var loginStartTime = DLogCommonModel.getInstance().loginStartTime;
      if (loginStartTime == 0) {
        loginStartTime = DateTime.now().millisecondsSinceEpoch;
        logger.severe('loginStartTime 为 0');
      }

      /// 当前手机时间戳
      final int currentTimeStamp = DateTime.now().millisecondsSinceEpoch;

      /// 登录到登出事件的时间间隔
      final int onlineDuration = (currentTimeStamp - loginStartTime) ~/ 1000;

      if (onlineDuration < 0) {
        logger.warning('用户登录到登出时间间隔出现异常');
      }
      final DLogUserLogoutModel model = DLogUserLogoutModel();
      model.logoutLogType = "app_logout";
      model.onlineDuration = onlineDuration;
      model.extJson = map ?? {};

      final mapData = model.toJson();

      if (model.userId == null || model.userId.isEmpty) return;
      reportDataWithModel(mapData);

      /// 重置用户信息,一定要放在上报最后
      DLogCommonModel.getInstance().resetUserInfo();
    } catch (e) {
      logger.warning(e);
    }
  }

  /// 服务器登录
  Future<void> guildLogin({Map map}) async {
    try {
      final selectedChatTarget = ChatTargetsModel.instance?.selectedChatTarget;
      if (selectedChatTarget.runtimeType != GuildTarget) {
        return;
      }
      DLogCommonModel.getInstance().guildStartTime =
          DateTime.now().millisecondsSinceEpoch;
      final DLogUserLoginModel model = DLogUserLoginModel();
      model.loginLogType = "guild_login";
      model.guildSessionId =
          DLogCommonModel.getInstance()?.guildSessionId ?? '';
      model.guildId = ChatTargetsModel.instance?.selectedChatTarget?.id ?? '';
      model.extJson = map ?? {};
      final mapData = model.toJson();

      if (model.userId == null || model.userId.isEmpty) return;
      if (model.guildId == null || model.guildId.isEmpty) return;
      reportDataWithModel(mapData);
    } catch (e) {
      logger.warning(e);
    }
  }

  /// 服务器登出
  void guildLogout({Map map}) {
    try {
      final selectedChatTarget = ChatTargetsModel.instance?.selectedChatTarget;
      if (selectedChatTarget.runtimeType != GuildTarget) {
        return;
      }

      /// 服务器上线时间戳
      var guildStartTime = DLogCommonModel.getInstance().guildStartTime;

      if (guildStartTime == 0) {
        guildStartTime = DateTime.now().millisecondsSinceEpoch;
        logger.severe('guildStartTime 为 0');
      }

      /// 当前手机时间戳
      final int currentTimeStamp = DateTime.now().millisecondsSinceEpoch;

      /// 进入到离开服务器事件的时间间隔
      final int onlineDuration = (currentTimeStamp - guildStartTime) ~/ 1000;

      if (onlineDuration < 0) {
        logger.warning('用户登录到登出时间间隔出现异常');
      }
      final DLogUserLogoutModel model = DLogUserLogoutModel();
      model.logoutLogType = "guild_logout";
      model.guildSessionId =
          DLogCommonModel.getInstance()?.guildSessionId ?? '';
      model.guildId = ChatTargetsModel.instance?.selectedChatTarget?.id ?? '';
      model.onlineDuration = onlineDuration;
      model.extJson = map ?? {};

      final mapData = model.toJson();
      if (model.userId == null || model.userId.isEmpty) return;
      if (model.guildId == null || model.guildId.isEmpty) return;
      reportDataWithModel(mapData);

      /// 重置服务器数据上报信息,一定要放在上报最后
      DLogCommonModel.getInstance().resetGuildInfo();
    } catch (e) {
      logger.warning(e);
    }
  }

  /// 自定义事件
  void customEvent(
      {String actionEventId = '',
      String actionEventSubId = '',
      String actionEventSubParam = '',
      String pageId = '',
      Map extJson}) {
    try {
      final DLogCustomEventModel model = DLogCustomEventModel();
      model.actionEventId = actionEventId ?? '';
      model.actionEventSubId = actionEventSubId ?? '';
      model.actionEventSubParam = actionEventSubParam ?? '';
      model.pageId = pageId ?? '';
      model.extJson = extJson ?? {};

      final mapData = model.toJson();
      reportDataWithModel(mapData);
    } catch (e) {
      logger.warning(e);
    }
  }

  /// 客户端自定义扩展事件
  void extensionEvent({@required String logType, Map extJson}) {
    try {
      final DLogExtensionEventModel model = DLogExtensionEventModel();
      model.logType = logType ?? '';
      model.extJson = extJson ?? {};
      final mapData = model.toJson();
      reportDataWithModel(mapData);
    } catch (e) {
      logger.warning(e);
    }
  }

  /// 数据上报接口
  void reportDataWithModel(Map mapData) {
    try {
      if (mapData == null || mapData.isEmpty) return;

      /// 序列化成json字符串
      final jsonString = jsonEncode(mapData);

      final DLogReportModel reportModel = DLogReportModel();
      reportModel.dlogContent = jsonString;

      if (reportModel == null) {
        return;
      }
      reportModel.dlogContentID = const Uuid().v4();

      DLogReportDataManager.instance.addReportData(reportModel);
    } catch (e) {
      logger.warning(e);
    }
  }
}
