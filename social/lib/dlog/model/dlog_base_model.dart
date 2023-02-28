import 'package:date_format/date_format.dart';

// import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/utils/universal_platform.dart';

import '../../global.dart';
import 'dlog_common_model.dart';

class DLogBaseModel {
  String logType;
  String clientTime;
  String userId;
  String appVersion;
  String buildNumber;
  String channel;
  String platform;
  String deviceId;
  String appSessionId;

  DLogBaseModel() {
    clientTime = formatDate(
        DateTime.now(), [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn, ':', ss]);
    userId = Global.user?.id;
    platform = '';
    if (UniversalPlatform.isIOS) {
      platform = '0';
    } else if (UniversalPlatform.isAndroid) {
      platform = '1';
    } else if (UniversalPlatform.isWeb) {
      platform = '2';
    } else if (UniversalPlatform.isWindows) {
      platform = '3';
    } else if (UniversalPlatform.isMacOS) {
      platform = '4';
    } else if (UniversalPlatform.isLinux) {
      platform = '5';
    } else if (UniversalPlatform.isFuchsia) {
      platform = '6';
    }
    appVersion = DLogCommonModel.getInstance().appVersion;
    buildNumber = DLogCommonModel.getInstance().buildNumber;
    channel = Global.deviceInfo?.channel;
    deviceId = DLogCommonModel.getInstance().deviceId;
    appSessionId = DLogCommonModel.getInstance().appSessionId;
  }

  Map<String, dynamic> toJson() => {
        'log_type': logType ?? '',
        'client_time': clientTime ?? '',
        'user_id': userId ?? '',
        'app_version': appVersion ?? '',
        'build_number': buildNumber ?? '',
        'channel': channel ?? '',
        'platform': platform ?? '',
        'device_id': deviceId ?? '',
        'app_session_id': appSessionId ?? '',
      };
}
