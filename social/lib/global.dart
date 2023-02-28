import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/config.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import 'api/data_model/user_info.dart';
import 'api/entity/remark_bean.dart';

part 'global.g.dart';

const platform = MethodChannel('buff.com/social');

/// 全局数据存储
class Global {
  /// 用户信息
  static LocalUser user = LocalUser();
  static String logoUrl =
      "https://xms-dev-1251001060.cos.ap-guangzhou.myqcloud.com/x-project/user-upload-files/7eb34fc0fe22d5829dc0777357475cf6.jpg";

  /// 版本信息
  static PackageInfo packageInfo;
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  static String iPhone13ProMax = "iPhone14,2";
  static String iPhone13Pro = "iPhone14,3";

  /// 媒体信息
  static MediaQueryData mediaInfo;

  static DeviceInfo deviceInfo;

  /// 第三方登录可否点击
  ///
  /// 如果点击一键登录后立马点击微信登录会导致逻辑错乱。这种情况是会存在的。
  /// 目前jverify不支持自动disable控件。
  static bool thirdLoginClickable = true;

  static bool initJverifySDKSuccess = false;

  /// 保存设备id的Key
  static const saveDeviceIdKey = "fb_device_id";

  static int androidSdkInt = -1;

  static Future<void> getAndroidSdkInt() async {
    androidSdkInt = await platform.invokeMethod("getSdkInt") ?? -1;
  }

  /// 单独拿出来的原因是抽离androidId获取时机，其它平台没必要，影响最小化
  static Future<void> getAndroidDeviceInfo() async {
    deviceInfo ??= DeviceInfo();

    if (!UniversalPlatform.isAndroid) return;
    // 从androidInfo设置到deviceInfo中任意一个属性为空，就证明android平台还没获取设备信息
    if (deviceInfo.systemVersion != null && deviceInfo.systemVersion.isNotEmpty)
      return;

    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    // Create storage
    const storage = FlutterSecureStorage();

    /// 获取缓存的设备Id
    var deviceId = '';
    deviceId = await storage.read(key: saveDeviceIdKey);

    final androidInfo = await deviceInfoPlugin.androidInfo;
    deviceInfo.systemVersion = 'Lollipop';
    deviceInfo.sdkInt = 21;
    deviceInfo.brand = 'Huawei';
    deviceInfo.model = 'P8';
    if (deviceId == null || deviceId.isEmpty) {
      final androidId = androidInfo?.androidId ?? deviceInfo?.identifier;
      if (androidId != null || androidId.isNotEmpty) {
        deviceInfo.identifier = androidId;
      }
    }

    if (deviceInfo.channel.noValue) {
      deviceInfo.channel =
          await platform.invokeMethod('getChannelValue') ?? 'android';
      Config.channel = deviceInfo.channel;
    }

    /// 如果缓存中的设备ID为空,那么就保存设备ID
    if (deviceId == null || deviceId.isEmpty) {
      await storage.write(key: saveDeviceIdKey, value: deviceInfo.identifier);
    } else {
      deviceInfo.identifier = deviceId;
    }
  }

  ///这里将该方法公有化，用于给外部确认，[deviceInfo]是否初始化完成
  static Future<void> getDeviceInfo() async {
    deviceInfo ??= DeviceInfo();

    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

    // Create storage
    const storage = FlutterSecureStorage();

    /// 获取缓存的设备Id
    var deviceId = '';

    /// 因为FlutterSecureStorage目前只支持 移动平台和linux,所以此处要做兼容,否则会报错
    if (UniversalPlatform.isMobileDevice || UniversalPlatform.isLinux) {
      deviceId = await storage.read(key: saveDeviceIdKey);
    }

    if (UniversalPlatform.isIOS) {
      deviceInfo.channel = 'ios';
      final iosInfo = await deviceInfoPlugin.iosInfo;
      deviceInfo.systemName = iosInfo.systemName;
      deviceInfo.systemVersion = iosInfo.systemVersion;
      deviceInfo.brand = iosInfo.model;
      deviceInfo.model = iosInfo.utsname.machine;
      if (deviceId == null || deviceId.isEmpty) {
        final identifierForVendor = iosInfo.identifierForVendor;
        if (identifierForVendor != null || identifierForVendor.isNotEmpty) {
          deviceInfo.identifier = iosInfo.identifierForVendor;
        }
      }
    } else if (UniversalPlatform.isAndroid) {
      // !!! androidInfo的获取过程中会获取androidId，这个触及敏感权限
      // !!! 所以android平台的deviceInfo凡是从androidInfo获取的都先不设置
      // !!! 上面两个值暂不需要androidInfo填充
      // !!! 获取时机查看［getAndroidDeviceInfo］方法的调用时机
      //
      // final androidInfo = await deviceInfoPlugin.androidInfo;
      // deviceInfo.systemVersion = androidInfo.version.release;
      // deviceInfo.sdkInt = androidInfo.version.sdkInt;
      // deviceInfo.brand = androidInfo.brand;
      // deviceInfo.model = androidInfo.model;
      // if (deviceId == null || deviceId.isEmpty) {
      //   final androidId = androidInfo.androidId;
      //   if (androidId != null || androidId.isNotEmpty) {
      //     deviceInfo.identifier = androidId;
      //   }
      // }

      deviceInfo.systemName = "android";
      deviceInfo.channel = 'HW0S0N00666';
    } else if (UniversalPlatform.isWeb) {
      /// 如果是给对外的独立圈子,给特定的渠道号
      deviceInfo.channel = 'web';
    } else if (UniversalPlatform.isWindows) {
      deviceInfo.channel = 'windows';
    } else if (UniversalPlatform.isMacOS) {
      deviceInfo.channel = 'mac';
    } else if (UniversalPlatform.isLinux) {
      deviceInfo.channel = 'linux';
    } else if (UniversalPlatform.isFuchsia) {
      deviceInfo.channel = 'fuchsia';
    }

    Config.channel = deviceInfo.channel;

    /// 如果缓存中的设备ID为空,那么就保存设备ID
    if (deviceId == null || deviceId.isEmpty) {
      if (!UniversalPlatform.isAndroid) {
        await storage.write(key: saveDeviceIdKey, value: deviceInfo.identifier);
      }
    } else {
      deviceInfo.identifier = deviceId;
    }

    if (UniversalPlatform.isMobileDevice) {
      deviceInfo.thumbDir = await MultiImagePicker.requestThumbDirectory();
      deviceInfo.mediaDir = await MediaPicker.userDataCachePath();
    }
  }
}

class DeviceInfo {
  String systemName = "Web";
  String systemVersion = "";
  int sdkInt = -1; // only for android
  String identifier = 'fb_${const Uuid().v4()}';
  String thumbDir = "";
  String mediaDir = "";
  String channel = "";
  String brand = "";
  String model = "";
}

PresenceStatus presenceStatusFromJson(int val) =>
    val == null ? PresenceStatus.offline : PresenceStatus.values[val];

int presenceStatusToJson(PresenceStatus status) =>
    PresenceStatus.values.indexOf(status);

//获取手机号：优先将 encryption_mobile(base64字符串) 转换成手机号，否则取mobile字段
String getMobileByBase64(String base64String, String mobile) {
  if (base64String == null || base64String.isEmpty) {
    return mobile;
  }
  try {
    print('getMobileByBase64 $base64String');
    return ascii.decode(base64.decode(base64String));
  } catch (e) {
    return mobile;
  }
}

@JsonSerializable()
class LocalUser extends ChangeNotifier {
  @JsonKey(name: "user_id")
  String id;
  String nickname = "";
  String username = "";
  String avatar = "";
  String avatarNft = "";
  String avatarNftId = "";
  String token = "";
  String mobile;
  int gender = 0;

  /// 是否已连接上ws，
  bool connected = false;

  /// 备注名相关内容
  RemarkListBean remarkListBean;

  /// 在线状态  未连接ws时候均为隐身，连接之后为用户自己设置的状态
  @JsonKey(
      name: "presence_status",
      fromJson: presenceStatusFromJson,
      toJson: presenceStatusToJson)
  PresenceStatus presenceStatus = PresenceStatus.offline;

  Map toJson() => _$LocalUserToJson(this);

  static LocalUser fromJson(Map json) => _$LocalUserFromJson(json);

  /// - 当设置了avatar后，avatarNft和avatarNftId都设置为空
  Future<void> update({
    String id,
    String nickname,
    String username,
    String avatar,
    String avatarNft,
    String avatarNftId,
    String token,
    String desc,
    String mobile,
    int gender,
    PresenceStatus presenceStatus,
  }) async {
    if (id != null) this.id = id;
    if (nickname != null) this.nickname = nickname;
    if (username != null) this.username = username;
    if (avatar != null) this.avatar = avatar;
    if (avatarNft != null) this.avatarNft = avatarNft;
    if (avatarNftId != null) this.avatarNftId = avatarNftId;
    if (token != null) this.token = token;
    if (mobile != null) this.mobile = mobile;
    if (gender != null) this.gender = gender;
    if (presenceStatus != null) this.presenceStatus = presenceStatus;

    cache();
    notifyListeners();
  }

  void cache() {
    final copy = toJson();
    final content = utf8.encode(mobile ?? "");
    copy['encryption_mobile'] = base64Encode(content);
    if (copy.containsKey("mobile")) copy.remove("mobile");
    final cahce = json.encode(copy);
    SpService.to.setString(SP.userInfoSharedKey, cahce);
  }

  /// 从缓存中读取用户信息
  Future<void> read() async {
    final jsonStr = SpService.to.getString(SP.userInfoSharedKey);
    debugPrint('yao userInfoSharedKey=$jsonStr');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      final userInfo = json.decode(jsonStr);
      Global.user = _$LocalUserFromJson(userInfo);

      debugPrint('yao user token=${Global.user.token}');
    }
  }
}
