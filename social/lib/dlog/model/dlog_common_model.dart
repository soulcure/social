import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:uuid/uuid.dart';

class DLogCommonModel {
  String appVersion;
  String buildNumber;
  String deviceId;
  String appSessionId;
  String guildSessionId;
  int loginStartTime;
  int guildStartTime;

  static final DLogCommonModel _instance = DLogCommonModel._();

  factory DLogCommonModel() => _instance;

  DLogCommonModel._() {
    deviceId = Global.deviceInfo?.identifier ?? '';
    appVersion = Global.packageInfo?.version ?? '';
    buildNumber = Global.packageInfo?.buildNumber ?? '';
    appSessionId = const Uuid().v4();
    guildSessionId = const Uuid().v4();
    loginStartTime = 0;
    guildStartTime = 0;
    logger.info('设备ID: $deviceId');
  }

  static DLogCommonModel getInstance() {
    if (_instance.deviceId != Global.deviceInfo?.identifier) {
      _instance.deviceId = Global.deviceInfo?.identifier ?? '';
      logger.info('重新设置设备ID: ${_instance.deviceId}');
    }
    return _instance;
  }

  void resetUserInfo() {
    loginStartTime = 0;
    appSessionId = const Uuid().v4();
  }

  void resetGuildInfo() {
    guildStartTime = 0;
    guildSessionId = const Uuid().v4();
  }
}
