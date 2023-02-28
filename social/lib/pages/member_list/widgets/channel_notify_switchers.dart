import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/api/user_api.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/db/db.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_confirm_popup.dart';

class ChannelNotifySwitchers extends StatefulWidget {
  /// 当前频道id
  final String channelId;

  const ChannelNotifySwitchers(this.channelId, {Key key}) : super(key: key);

  @override
  _ChannelNotifySwitchersState createState() => _ChannelNotifySwitchersState();
}

class _ChannelNotifySwitchersState extends State<ChannelNotifySwitchers> {
  /// 是否正在网络请求中
  bool _isLoading;

  ValueListenable listenable;

  @override
  void initState() {
    super.initState();
    _isLoading = false;
    listenable = Db.userConfigBox.listenable(keys: [UserConfig.mutedChannel])
      ..addListener(refresh);
  }

  @override
  void dispose() {
    listenable.removeListener(refresh);
    super.dispose();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  /// 当前channel是否被消息屏蔽
  bool get isMute {
    final List<String> mutedChannels =
        Db.userConfigBox.get(UserConfig.mutedChannel);
    if (mutedChannels != null && mutedChannels.contains(widget.channelId)) {
      return true;
    }
    return false;
  }

  /// 如果当前频道允许通知，发起网络请求更改设置，屏蔽通知
  /// 如果当前频道不允许通知，发起网络请求更改设置，允许通知
  Future _toggleNotifyState() async {
    if (_isLoading == true) {
      return;
    }

    final _isMute = isMute;

    /// 展示确认弹窗
    final isConfirm = await showConfirmPopup(
      title: _isMute ? '确认要接收此频道的消息通知？'.tr : '确定不再接收此频道的消息通知？'.tr,
      confirmStyle: Theme.of(context)
          .textTheme
          .bodyText2
          .copyWith(fontSize: 17, color: DefaultTheme.dangerColor),
    );

    if (isConfirm != true) {
      /// 取消屏蔽
      return;
    }

    /// 确认屏蔽
    try {
      setState(() => _isLoading = true);

      final List<String> mutedChannels =
          Db.userConfigBox.get(UserConfig.mutedChannel) ?? [];
      if (_isMute) {
        if (mutedChannels.remove(widget.channelId)) {
          /// 当前channel已被屏蔽，发起取消屏蔽请求
          await updateSetting(mutedChannels);
        }
      } else {
        if (!mutedChannels.contains(widget.channelId)) {
          /// 当前channel未被屏蔽，发起屏蔽请求
          mutedChannels.add(widget.channelId);
          await updateSetting(mutedChannels);
        }
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }

  /// 发起更改配置请求并更新本地配置，mutedChannels包含所有被屏蔽的频道id
  Future<void> updateSetting(List<String> mutedChannels) async {
    await UserApi.updateSetting(mutedChannels: mutedChannels);
    await UserConfig.update(mutedChannels: mutedChannels);
  }

  @override
  Widget build(BuildContext context) {
    return FadeButton(
      onTap: _toggleNotifyState,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(),
            )
          else if (isMute)
            Image.asset("assets/images/channel_mute.png", width: 24, height: 24)
          else
            Icon(IconFont.buffChannelNotice,
                size: 24, color: Get.textTheme.bodyText2.color),
          sizeHeight6,
          Text(
            "通知".tr,
            style: const TextStyle(color: Color(0xFF1F2125), fontSize: 12),
          )
        ],
      ),
    );
  }
}
