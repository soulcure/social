import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/api/user_api.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/web/extension/state_extension.dart';
import 'package:im/web/widgets/button/web_hover_button.dart';
import 'package:im/widgets/link_tile.dart';

class PrivacySetPage extends StatefulWidget {
  @override
  _PrivacySetPageState createState() => _PrivacySetPageState();
}

class _PrivacySetPageState extends State<PrivacySetPage> {
  Box userConfigBox;

  final Map<String, bool> _friendSourceType = {};

  ///谁允许我为好友，分别是：全体成员、好友的好友、共同服务器
  final _keyToAll = UserConfig.friendSourceFlagsAll;
  final _keyToFriend = UserConfig.friendSourceFlagsMutualFriends;
  final _keyToService = UserConfig.friendSourceFlagsMutualGuilds;

  bool _restricted;
  bool _restrictedConfirm = false;

  Future _future;

  Future<bool> init() async {
    final res = await UserApi.getSetting();
    final mutedChannels = UserConfig.getMutedChannel(res);
    await UserConfig.update(
      defaultGuildsRestricted: res[UserConfig.defaultGuildsRestricted] ?? true,
      restrictedGuilds:
          ((res[UserConfig.restrictedGuilds] ?? []) as List).cast<String>(),
      friendSourceFlags: res[UserConfig.friendSourceFlags],
      mutedChannels: mutedChannels,
    );

    _initData();
    return true;
  }

  @override
  void initState() {
    userConfigBox = Db.userConfigBox;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      formDetectorModel.setCallback(onConfirm: _onConfirm, onReset: _onReset);
    });
    _future = init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
              child: SizedBox(
                  width: 30, height: 30, child: CircularProgressIndicator()),
            );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 32),
              SizedBox(
                height: 72,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '已屏蔽的用户'.tr,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText2
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    WebHoverButton(
                      width: 88,
                      height: 32,
                      padding: EdgeInsets.zero,
                      borderRadius: 4,
                      color: Theme.of(context).primaryColor,
                      hoverColor: Theme.of(context).textTheme.bodyText2.color,
                      onTap: () => Routes.pushShieldSetPage(context),
                      child: Text(
                        '编辑'.tr,
                        style: Theme.of(context)
                            .textTheme
                            .bodyText2
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '谁可以添加你为好友'.tr,
                style: Theme.of(context)
                    .textTheme
                    .bodyText2
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              LinkTile(
                  context,
                  Text(
                    "全体成员".tr,
                    style: Theme.of(context).textTheme.bodyText2,
                  ),
                  showTrailingIcon: false,
                  height: 58,
                  padding: EdgeInsets.zero,
                  trailing: Row(
                    children: <Widget>[
                      _buildRadio(
                        value: _friendSourceType[_keyToAll] ?? true,
                        onChange: (v) => _onChange(v, _keyToAll),
                      )
                    ],
                  )),
              divider,
              LinkTile(
                context,
                Text(
                  "好友的好友".tr,
                  style: Theme.of(context).textTheme.bodyText2,
                ),
                height: 58,
                showTrailingIcon: false,
                padding: EdgeInsets.zero,
                trailing: Row(
                  children: <Widget>[
                    _buildRadio(
                      value: _friendSourceType[_keyToFriend] ?? true,
                      onChange: (v) => _onChange(v, _keyToFriend),
                    )
                  ],
                ),
              ),
              divider,
              LinkTile(
                context,
                Text(
                  "共同服务器成员".tr,
                  style: Theme.of(context).textTheme.bodyText2,
                ),
                height: 58,
                showTrailingIcon: false,
                padding: EdgeInsets.zero,
                trailing: Row(
                  children: <Widget>[
                    _buildRadio(
                        value: _friendSourceType[_keyToService] ?? true,
                        onChange: (v) => _onChange(v, _keyToService)),
                  ],
                ),
              ),
              divider,
              sizeHeight24,
              Text(
                '谁可以私信你'.tr,
                style: Theme.of(context)
                    .textTheme
                    .bodyText2
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              LinkTile(
                context,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '共同服务器成员'.tr,
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                    sizeHeight10,
                    Text(
                      '只对设置后新加入的服务器生效，不影响现已加入的服务器。'.tr,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: 12),
                    )
                  ],
                ),
                showTrailingIcon: false,
                height: 76,
                padding: EdgeInsets.zero,
                trailing: Row(children: <Widget>[
                  _buildRadio(
                      value: !_restricted, onChange: _onRestrictedChange)
                ]),
              ),
              divider,
            ],
          );
        });
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

  Future<void> _onRestrictedChange(bool v) async {
    final res = await showConfirmDialog(
        title: '服务器默认隐私设置'.tr,
        content: '你想要将此更改应用到所有现有的服务器吗？'.tr,
        confirmText: '是'.tr,
        cancelText: '否'.tr,
        barrierDismissible: true);
    if (res == null) return;
    _restrictedConfirm = res;
    setState(() => _restricted = !v);
    checkFormChanged();
  }

  Future _onChange(bool v, String type) async {
    ///判断优先级：全体成员 > 好友的好友 > 共同服务器成员
    _changeType(type, v);
    setState(() {});
    checkFormChanged();
  }

  void _changeType(String type, bool v) {
    if (type == _keyToAll) {
      _friendSourceType.forEach((key, value) {
        _friendSourceType[key] = v;
      });
    } else if (type == _keyToFriend) {
      _friendSourceType[_keyToFriend] = v;
      if (v && _friendSourceType[_keyToService]) {
        _friendSourceType[_keyToAll] = true;
      } else {
        _friendSourceType[_keyToAll] = false;
      }
    } else {
      _friendSourceType[_keyToService] = v;
      if (v && _friendSourceType[_keyToFriend]) {
        _friendSourceType[_keyToAll] = true;
      } else {
        _friendSourceType[_keyToAll] = false;
      }
    }
  }

  void _initData() {
    final Map<dynamic, dynamic> friendMap =
        userConfigBox.get(UserConfig.friendSourceFlags) ?? {};
    friendMap.forEach((key, value) {
      _friendSourceType[key] = value == true;
    });
    _restricted =
        userConfigBox.get(UserConfig.defaultGuildsRestricted) ?? false;
  }

  void _onReset() {
    _initData();
    setState(() {});
    checkFormChanged();
  }

  Future<void> _onConfirm() async {
    List<String> restrictedGuilds =
        await Db.userConfigBox.get(UserConfig.restrictedGuilds);
    if (!_restricted && _restrictedConfirm) {
      restrictedGuilds.clear();
    } else if (_restricted && _restrictedConfirm) {
      restrictedGuilds = ChatTargetsModel.instance.chatTargets
          .whereType<GuildTarget>()
          .map((e) => e.id)
          .toList();
    }

    /// 避免直接引用_friendSourceType, 不然会造成_friendSourceType与box的值直接同步
    final Map<String, bool> friendSourceType = {
      _keyToAll: _friendSourceType[_keyToAll],
      _keyToFriend: _friendSourceType[_keyToFriend],
      _keyToService: _friendSourceType[_keyToService],
    };
    try {
      await UserApi.updateSetting(
          defaultGuildsRestricted: _restricted,
          restrictedGuilds: restrictedGuilds,
          friendSourceFlags: friendSourceType);
      await UserConfig.update(
          defaultGuildsRestricted: _restricted,
          restrictedGuilds: restrictedGuilds,
          friendSourceFlags: friendSourceType);
      setState(() {});
      checkFormChanged();
    } catch (e) {
      return;
    }
  }

  bool get formChanged {
    final Map<dynamic, dynamic> friendMap =
        userConfigBox.get(UserConfig.friendSourceFlags) ?? {};
    final restricted =
        userConfigBox.get(UserConfig.defaultGuildsRestricted) ?? false;
    return friendMap[_keyToAll] != _friendSourceType[_keyToAll] ||
        friendMap[_keyToFriend] != _friendSourceType[_keyToFriend] ||
        friendMap[_keyToService] != _friendSourceType[_keyToService] ||
        restricted != _restricted;
  }

  void checkFormChanged() {
    formDetectorModel.toggleChanged(formChanged);
  }
}
