// import 'package:fb_live_flutter/live/api/fblive_provider.dart';
//
// /// 配置类
// class ConfigProviderDev extends LiveConfigProvider {
//   /// 直播模块使用的appId
//   @override
//   int get liveAppId => 82783276;
//
//   /// 直播模块使用的app签名
//   @override
//   String get liveAppSign =>
//       "7a29730dc10b87daa8f7db3f30e572dc889f6407c7031aee1716519074c90721";
//
//   /// 直播模块的api请求地址
//   // static String liveHost = "https://test.faceuu.com";
//   @override
//   String get liveHost => "https://fbapi.zeinn.net";
//
//   // static String liveHost = "https://test.faceuu.net";
//   // static String liveHost = "https://live.fanbook.mobi";
//
//   /// web端zego wss socket 地址
//   @override
//   String get liveWssUrl => "wss://webliveroom-test.zego.im/ws";
//
//   bool liveIsTestEnv = true;
//
//   /// obs-查看详情Url【obs软件配置说明】
//   @override
//   String get obsExplainUrl => "https://fbh5.zeinn.net/live/explain";
//
//   /// 引流浮层链接地址-有权限
//   String get liveShareAuthUrl => "https://fanbook.mobi/live";
//
//   /// 引流浮层下载地址-无权限
//   String get liveShareDownAppUrl => "https://fanbook.mobi";
//
//   /// 直播分享弹窗地址
//   String liveShareUrl = "https://fanbook.mobi/live";
//
//   @override
//   String get protocolHost => 'fanbook-test.fanbook.mobi';
//
//   String get rtmpPublish2 => 'rtmp://r.ossrs.net/live/livestream';
//
//   @override
//   String get appGroupID => "group.fanbook.live.ios";
//
//   @override
//   String get extensionName => "FBScreenShareExtention";
//
//   @override
//   String get broadcastNotificationName =>
//       "ZGFinishReplayKitBroadcastNotificationName";
//
//   /// 跳转【商品列表/优惠券】是否开启有赞授权
//   /// tip：观众点击订单/购物车等转到有赞时，需要授权，我们自己需要在程序里添加一个开关授权检测的配置。
//   /// 只有这里有设置值，fb集成需要设置为true
//   @override
//   bool get openAuthorization => false;
// }
