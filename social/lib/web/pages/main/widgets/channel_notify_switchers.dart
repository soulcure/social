import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/api/user_api.dart';
import 'package:im/app/modules/direct_message/views/portrait_direct_message_view.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/db/db.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/web/utils/confirm_dialog/message_box.dart';
import 'package:im/web/widgets/button/web_icon_button.dart';

class ChannelNotifySwitchers extends StatefulWidget {
  /// 当前频道id
  final String channelId;

  const ChannelNotifySwitchers(this.channelId, {Key key}) : super(key: key);

  @override
  _ChannelNotifySwitchersState createState() => _ChannelNotifySwitchersState();
}

class _ChannelNotifySwitchersState extends State<ChannelNotifySwitchers> {
  /// 当前channel是否被消息屏蔽
  bool _isMute;

  /// 是否正在网络请求中
  bool _isLoading;

  StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _isMute = _getIsMute();
    _isLoading = false;
    _subscription = TextChannelUtil.instance.stream.listen((value) {
      switch (value.runtimeType) {
        case NotifyWebSwitcherStream:
          _isMute = _getIsMute();
          setState(() {});
          break;
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  /// 从本地配置查看当前channel是否有屏蔽消息
  bool _getIsMute() {
    List<String> mutedChannels = [];
    try {
      mutedChannels = Db.userConfigBox.get(UserConfig.mutedChannel);
      // ignore: empty_catches
    } catch (e) {}
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

    /// 展示确认弹窗
    final isConfirm = await showWebMessageBox(
      title: _isMute ? '确认要接收此频道的消息通知？'.tr : '确定不再接收此频道的消息通知？'.tr,
    );

    if (isConfirm != true) {
      /// 取消屏蔽
      return;
    }

    /// 确认屏蔽
    try {
      setState(() => _isLoading = true);

      List<String> mutedChannels = [];
      try {
        mutedChannels = Db.userConfigBox.get(UserConfig.mutedChannel);
        // ignore: empty_catches
      } catch (e) {}

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
        _isMute = !_isMute;
      });
      TextChannelUtil.instance.stream.add(NotifySwitcherStream());
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
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(),
            )
          : (_isMute
              ? Image.asset("assets/images/channel_mute.png",
                  width: 20, height: 20)
              : WebIconButton(
                  IconFont.webCircleNotice,
                  hoverColor: Colors.black,
                  highlightColor: Theme.of(context).primaryColor,
                  size: 20,
                  onPressed: _toggleNotifyState,
                  padding: EdgeInsets.zero,
                )),
    );
  }
}
