/*
* 流附加信息模型
* */
import 'package:fb_live_flutter/live/utils/config/steam_info_config.dart';

/// 使用例子
///   final SteamInfoModel steamInfoModel = SteamInfoModel.fromParam(result);
//   print("steamInfoModel::#${steamInfoModel?.platform}");
//   print("steamInfoModel::#${steamInfoModel?.screenShare}");
//   print("steamInfoModel::#${steamInfoModel?.mirror}");
class SteamInfoModel {
  final bool? mirror;
  final bool? screenShare;
  final String? platform;
  final bool? appIsResume;
  final String? screenDirection;

  SteamInfoModel(
      {this.mirror,
      this.screenShare,
      this.platform,
      this.appIsResume,
      this.screenDirection});

  factory SteamInfoModel.fromParam(String param) =>
      _$SteamInfoModelFromJson(param);

  SteamInfoModel from(String param) => _$SteamInfoModelFromJson(param);
}

/// 修复web【1期】推流显示主播离开
bool isParamNull(String? paramValue) {
  return paramValue == "null" || paramValue == null || paramValue == '';
}

SteamInfoModel _$SteamInfoModelFromJson(String param) {
  final Uri u = Uri.parse("?$param");
  return SteamInfoModel(
    mirror: isParamNull(u.queryParameters[LiveParamKey.mirror])
        ? null
        : u.queryParameters[LiveParamKey.mirror] == "positive",
    screenShare: isParamNull(u.queryParameters[LiveParamKey.screenShare])
        ? null
        : u.queryParameters[LiveParamKey.screenShare] == "open",
    platform: isParamNull(u.queryParameters[LiveParamKey.platform])
        ? null
        : u.queryParameters[LiveParamKey.platform],
    appIsResume: isParamNull(u.queryParameters[LiveParamKey.app])
        ? null
        : u.queryParameters[LiveParamKey.app] == "resume",
    screenDirection:
        isParamNull(u.queryParameters[LiveParamKey.screenDirection])
            ? "V"
            : u.queryParameters[LiveParamKey.screenDirection],
  );
}
