import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:im/core/config.dart';

class FBLiveConfigProvider extends LiveConfigProvider {
  FBLiveConfigProvider._();

  static final FBLiveConfigProvider _instance = FBLiveConfigProvider._();

  static FBLiveConfigProvider get instance => _instance;

  @override
  String get appGroupID => Config.appGroupID;

  @override
  String get broadcastNotificationName => Config.broadcastNotificationName;

  @override
  String get extensionName => Config.extensionName;

  @override
  int get liveAppId => Config.liveAppId;

  @override
  String get liveAppSign => Config.liveAppSign;

  @override
  String get liveHost => Config.liveHost;

  @override
  String get liveWssUrl => Config.liveWssUrl;

  @override
  String get obsExplainUrl => Config.obsExplainUrl;

  @override
  String get protocolHost => Config.protocolHost;

  @override
  bool get openAuthorization => true;
}
