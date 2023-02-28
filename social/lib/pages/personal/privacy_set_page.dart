import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/api/user_api.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/link_tile.dart';

class PrivacySetPage extends StatefulWidget {
  @override
  _PrivacySetPageState createState() => _PrivacySetPageState();
}

class _PrivacySetPageState extends State<PrivacySetPage> {
  Box userConfigBox;

  final Map<String, bool> friendSourceType = {};

  ///谁允许我为好友，分别是：全体成员、好友的好友、共同服务器
  final _keyToAll = UserConfig.friendSourceFlagsAll;
  final _keyToFriend = UserConfig.friendSourceFlagsMutualFriends;
  final _keyToService = UserConfig.friendSourceFlagsMutualGuilds;

  @override
  void initState() {
    userConfigBox = Db.userConfigBox;
    final Map<dynamic, dynamic> friendMap =
        userConfigBox.get(UserConfig.friendSourceFlags) ?? {};
    friendMap.forEach((key, value) {
      friendSourceType[key] = value == true;
    });
    // _changeType(_keyToAll, friendSourceType[_keyToAll]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        title: '隐私设置'.tr,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView(
        children: <Widget>[
          const SizedBox(height: 10),
          LinkTile(context, Text("已屏蔽的用户".tr), onTap: () {
            Routes.pushShieldSetPage(context);
            // showToast("开发中...");
          }),
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '谁可以添加你为好友'.tr,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    .copyWith(fontSize: 14),
              )),
          Column(
            children: <Widget>[
              LinkTile(
                  context,
                  Text(
                    "全体成员".tr,
                    style: const TextStyle(fontSize: 16),
                  ),
                  showTrailingIcon: false,
                  height: 56,
                  trailing: Row(
                    children: <Widget>[
                      _buildRadio(
                        value: friendSourceType[_keyToAll] ?? true,
                        onChange: (v) => _onChange(v, _keyToAll),
                      )
                    ],
                  )),
              transparentDivider,
              LinkTile(
                context,
                Text(
                  "好友的好友".tr,
                  style: const TextStyle(fontSize: 16),
                ),
                height: 56,
                showTrailingIcon: false,
                trailing: Row(
                  children: <Widget>[
                    _buildRadio(
                      value: friendSourceType[_keyToFriend] ?? true,
                      onChange: (v) => _onChange(v, _keyToFriend),
                    )
                  ],
                ),
              ),
              transparentDivider,
              LinkTile(
                context,
                Text(
                  "共同服务器成员".tr,
                  style: const TextStyle(fontSize: 16),
                ),
                height: 56,
                showTrailingIcon: false,
                trailing: Row(
                  children: <Widget>[
                    _buildRadio(
                        value: friendSourceType[_keyToService] ?? true,
                        onChange: (v) => _onChange(v, _keyToService)),
                  ],
                ),
              )
            ],
          ),
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '谁可以私信你'.tr,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    .copyWith(fontSize: 14),
              )),
          Column(
            children: <Widget>[
              LinkTile(
                context,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '共同服务器成员'.tr,
                    ),
                    sizeHeight5,
                    Text(
                      '只对设置后新加入的服务器生效，不影响现已加入的服务器。'.tr,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: 14),
                    )
                  ],
                ),
                showTrailingIcon: false,
                trailing: Row(children: <Widget>[
                  ValueListenableBuilder<Box>(
                      valueListenable: Db.userConfigBox.listenable(),
                      builder: (context, box, widget) {
                        return _buildRadio(
                          value:
                              !(box.get(UserConfig.defaultGuildsRestricted) ??
                                  false),
                          onChange: _onRestrictedChange,
                        );
                      })
                ]),
              )
            ],
          ),
        ],
      ),
    );
  }

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

  ///设置：谁可以私信你
  Future<void> _onRestrictedChange(bool v) async {
    ///先改变开关
    await UserApi.updateSetting(defaultGuildsRestricted: !v);
    await UserConfig.update(defaultGuildsRestricted: !v);
    setState(() {});

    ///再弹窗
    final res = await showConfirmDialog(
        title: '服务器默认隐私设置'.tr,
        content: '你想要将此更改应用到所有已加入的服务器吗？'.tr,
        confirmText: '应用'.tr,
        barrierDismissible: true);
    if (res == null) return;
    List<String> restrictedGuilds =
        await Db.userConfigBox.get(UserConfig.restrictedGuilds);
    if (v && res) {
      restrictedGuilds.clear();
    } else if (!v && res) {
      restrictedGuilds = ChatTargetsModel.instance.chatTargets
          .whereType<GuildTarget>()
          .map((e) => e.id)
          .toList();
    }
    if (res) {
      await UserApi.updateSetting(restrictedGuilds: restrictedGuilds);
      await UserConfig.update(restrictedGuilds: restrictedGuilds);
    }
  }

  Future _onChange(bool v, String type) async {
    ///判断优先级：全体成员 > 好友的好友 > 共同服务器成员
    _changeType(type, v);
    await UserApi.updateSetting(friendSourceFlags: friendSourceType);
    await UserConfig.update(friendSourceFlags: friendSourceType);
    setState(() {});
  }

  void _changeType(String type, bool v) {
    if (type == _keyToAll) {
      friendSourceType.forEach((key, value) {
        friendSourceType[key] = v;
      });
    } else if (type == _keyToFriend) {
      friendSourceType[_keyToFriend] = v;
      if (v && friendSourceType[_keyToService]) {
        friendSourceType[_keyToAll] = true;
      } else {
        friendSourceType[_keyToAll] = false;
      }
    } else {
      friendSourceType[_keyToService] = v;
      if (v && friendSourceType[_keyToFriend]) {
        friendSourceType[_keyToAll] = true;
      } else {
        friendSourceType[_keyToAll] = false;
      }
    }
  }
}
