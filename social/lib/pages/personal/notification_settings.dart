import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/api/user_api.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/config.dart';
import 'package:im/db/db.dart';
import 'package:im/loggers.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/link_tile.dart';
import 'package:notification_permissions/notification_permissions.dart';

class NotificationSettings extends StatefulWidget {
  @override
  _NotificationSettingsState createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings>
    with WidgetsBindingObserver {
  /// 通知权限状态
  Future<String> permissionStatusFuture;

  /// 是否打开通知勿扰
  bool isOpenMessageNotification = false;

  /// 是否显示通知勿扰入口
  bool isShowNotification = false;

  final permGranted = "granted";
  final permDenied = "denied";
  final permUnknown = "unknown";
  final permProvisional = "provisional";

  @override
  void initState() {
    try {
      /// 是否有关闭通知勿扰入口权限
      isShowNotification = Config.permission['notices_setting'] ?? false;
      permissionStatusFuture = getCheckNotificationPermStatus();

      isOpenMessageNotification =
          Db.userConfigBox.get(UserConfig.notificationMuteKey) ?? false;
      init();
    } catch (e) {
      isShowNotification = false;
    }
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  Future<void> init() async {
    final userNotificationSetting = await UserApi.getSetting();
    isOpenMessageNotification =
        userNotificationSetting['notification_mute'] ?? false;
    await UserConfig.update(notificationMute: isOpenMessageNotification);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: const MyAppBar(title: Text('消息通知'.tr)),
      appBar: CustomAppbar(
        title: '消息通知'.tr,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView(
        children: [
          const SizedBox(
            height: 10,
          ),
          Column(
            children: [
              FutureBuilder(
                  future: permissionStatusFuture,
                  builder: (context, snapshot) {
                    var titleDesc = '';
                    if (snapshot.hasData && snapshot.data == permGranted) {
                      if (UniversalPlatform.isIOS) {
                        titleDesc = '若需要关闭系统通知，请在设备的“设%s置%s”-“%s通知%s”中进行修改'
                            .trArgs([nullChar, nullChar, nullChar, nullChar]);
                      } else if (UniversalPlatform.isAndroid) {
                        titleDesc = '若需要关闭系统通知，请在设备的“设%s置%s”-“%s通知管%s理”%s中修改'
                            .trArgs([
                          nullChar,
                          nullChar,
                          nullChar,
                          nullChar,
                          nullChar
                        ]);
                      }

                      return Column(
                        children: [
                          LinkTile(
                            context,
                            Text('接收消息通知'.tr,
                                style: const TextStyle(
                                    color: Color(0xFF1F2125), fontSize: 16)),
                            trailing: Text('已开启'.tr),
                            showTrailingIcon: false,
                          ),
                          sizeHeight10,
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                            child: Text(
                              titleDesc.tr,
                              style: const TextStyle(
                                  color: Color(0xFF8F959E), fontSize: 14),
                            ),
                          ),
                        ],
                      );
                    }

                    if (UniversalPlatform.isIOS) {
                      titleDesc =
                          '请在系统设置中找到“%s Fanbook%s”，进入“%s通知%s”并打开%s“允%s许通%s知”%s'
                              .trArgs([
                        nullChar,
                        nullChar,
                        nullChar,
                        nullChar,
                        nullChar,
                        nullChar,
                        nullChar,
                        nullChar
                      ]);
                    } else if (UniversalPlatform.isAndroid) {
                      titleDesc =
                          '点击前往系统中的“%s Fanbook%s”%s消息通知设置，请打开%s“%s允许通知%s”%s'
                              .trArgs([
                        nullChar,
                        nullChar,
                        nullChar,
                        nullChar,
                        nullChar,
                        nullChar,
                        nullChar
                      ]);
                    }

                    return Column(
                      children: [
                        LinkTile(
                          context,
                          Text(
                            '接收消息通知'.tr,
                            style: const TextStyle(
                                color: Color(0xFF1F2125), fontSize: 16),
                          ),
                          trailing: Text('已关闭，前往开启'.tr),
                          onTap: () {
                            // 打开权限入口设置推送通知开关
                            NotificationPermissions
                                    .requestNotificationPermissions()
                                .then((_) {
                              // 设置完权限后,获取权限状态
                              setState(() {
                                permissionStatusFuture =
                                    getCheckNotificationPermStatus();
                              });
                            });
                          },
                        ),
                        sizeHeight10,
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: Text(
                            titleDesc.tr,
                            style: const TextStyle(
                                color: Color(0xFF8F959E), fontSize: 14),
                          ),
                        ),
                      ],
                    );
                  }),
              const SizedBox(
                height: 16,
              ),
              if (isShowNotification) ...[
                LinkTile(
                  context,
                  Text(
                    "通知勿扰".tr,
                    style:
                        const TextStyle(color: Color(0xFF1F2125), fontSize: 16),
                  ),
                  height: 56,
                  showTrailingIcon: false,
                  trailing: Row(
                    children: <Widget>[
                      _buildRadio(
                          value: isOpenMessageNotification,
                          onChange: radioSwitch),
                      // FutureBuilder(
                      //     future: messageNotificationStatusFuture,
                      //     builder: (context, snapshot) {
                      //       if (snapshot.hasData &&
                      //           snapshot.data['notification_mute'] == true) {
                      //         isOpenMessageNotification = true;
                      //       } else {
                      //         isOpenMessageNotification = false;
                      //       }
                      //       return _buildRadio(
                      //           value: isOpenMessageNotification,
                      //           onChange: radioSwitch);
                      //     }),
                    ],
                  ),
                ),
                sizeHeight10,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Text(
                    '应用置后台后，当日最多接收一定数量的消息通知，直到再次回到应用'.tr,
                    style:
                        const TextStyle(color: Color(0xFF8F959E), fontSize: 14),
                  ),
                )
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 开关控件
  Widget _buildRadio({bool value, ValueChanged<bool> onChange}) {
    return Transform.scale(
      scale: 0.8,
      alignment: Alignment.centerRight,
      child: CupertinoSwitch(
          activeColor: Theme.of(context).primaryColor,
          value: value,
          onChanged: onChange),
    );
  }

  /// 开关事件
  Future<void> radioSwitch(bool value) async {
    try {
      await UserApi.updateSetting(notificationMute: value);
      await UserConfig.update(notificationMute: value);

      setState(() {
        isOpenMessageNotification = value;
      });
    } catch (e) {
      logger.info(e);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      setState(() {
        permissionStatusFuture = getCheckNotificationPermStatus();
      });
    }
  }

  /// 获取通知开关状态
  Future<String> getCheckNotificationPermStatus() {
    return NotificationPermissions.getNotificationPermissionStatus()
        .then((status) {
      switch (status) {
        case PermissionStatus.denied:
          return permDenied;
        case PermissionStatus.granted:
          return permGranted;
        case PermissionStatus.unknown:
          return permUnknown;
        case PermissionStatus.provisional:
          return permProvisional;
        default:
          return null;
      }
    });
  }
}
