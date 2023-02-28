import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/api/user_api.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/web/utils/confirm_dialog/setting_dialog.dart';
import 'package:pedantic/pedantic.dart';

class DmSetting extends SettingDialog {
  @override
  _DmSettingState createState() => _DmSettingState();
}

class _DmSettingState extends SettingDialogState<DmSetting> {
  bool isRestricted = false;

  @override
  void initState() {
    isRestricted =
        ((Db.userConfigBox.get(UserConfig.restrictedGuilds) ?? []) as List)
            .contains(ChatTargetsModel.instance.selectedChatTarget.id);
    super.initState();
  }

  @override
  String get title => '私信设置'.tr;

  @override
  Widget body() {
    final _theme = Theme.of(context);
    return Container(
      height: 80,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '私信'.tr,
            style: _theme.textTheme.bodyText1,
          ),
          sizeHeight5,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '该服务器的所有成员都可以发消息给你'.tr,
                style: _theme.textTheme.bodyText2,
              ),
              Transform.scale(
                scale: 0.8,
                alignment: Alignment.centerRight,
                child: CupertinoSwitch(
                    activeColor: Theme.of(context).primaryColor,
                    value: !isRestricted,
                    onChanged: _onRestrictedChange),
              )
            ],
          )
        ],
      ),
    );
  }

  @override
  Future<void> finish() async {
    final v = !isRestricted;
    try {
      loading.value = true;
      final List<String> restrictedGuilds =
          ((await Db.userConfigBox.get(UserConfig.restrictedGuilds) ?? [])
                  as List)
              .cast<String>();
      final String guildId = ChatTargetsModel.instance.selectedChatTarget.id;
      if (v) {
        restrictedGuilds.remove(guildId);
      } else if (!v && !restrictedGuilds.contains(guildId)) {
        restrictedGuilds.add(guildId);
      }
      await UserApi.updateSetting(restrictedGuilds: restrictedGuilds);
      unawaited(
          Db.userConfigBox.put(UserConfig.restrictedGuilds, restrictedGuilds));
      loading.value = false;
      Get.back();
    } catch (e) {
      loading.value = false;
    }
  }

  Future<void> _onRestrictedChange(bool v) async {
    setState(() {
      isRestricted = !v;
    });
  }
}
