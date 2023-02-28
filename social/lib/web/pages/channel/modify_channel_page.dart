import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/channel_api.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/common/permission/permission.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/extension/state_extension.dart';
import 'package:im/widgets/custom_inputbox_web.dart';
import 'package:im/widgets/link_tile.dart';
import 'package:pedantic/pedantic.dart';

import '../../../global.dart';

class ModifyChannelPage extends StatefulWidget {
  final ChatChannel channelId;

  const ModifyChannelPage(this.channelId);

  @override
  _ModifyChannelPageState createState() => _ModifyChannelPageState();
}

class _ModifyChannelPageState extends State<ModifyChannelPage> {
  String _originChannelName;
  String _originChannelTopic;
  TextEditingController _nameController;
  TextEditingController _topicController;
  GuildTarget _gt;
  ChatChannel _channel;
  String _cateId;
  int _userLimitInner = 10;

  /// 游客是否可见
  bool _isGuestVisible = false;
  bool _isOriginGuestVisible = false;

  @override
  void initState() {
    _channel = widget.channelId;
    _gt = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    _nameController = TextEditingController(text: _channel.name);
    _topicController = TextEditingController(text: _channel.topic);
    _originChannelName = _channel.name;
    _originChannelTopic = _channel.topic;
    _userLimitInner = _channel.userLimit == -1 ? 0 : _channel.userLimit;
    _cateId = _channel.parentId;
    _isGuestVisible = _channel.pendingUserAccess ?? false;
    _isOriginGuestVisible = _channel.pendingUserAccess ?? false;
    _gt.addListener(_onChannelChange);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      formDetectorModel.setCallback(onConfirm: _onConfirm, onReset: _onReset);
    });
    super.initState();
  }

  void _onChannelChange() {
    _channel = _gt.channels.firstWhere(
        (element) => element.id == widget.channelId.id,
        orElse: () => null);
    if (_channel == null) {
      Global.navigatorKey.currentState
          .popUntil((route) => route.settings.name == app_pages.Routes.HOME);
      return;
    }
    setState(() {
      _nameController.value = TextEditingValue(text: _channel.name);
      _topicController.value = TextEditingValue(text: _channel.topic);
      _cateId = _channel.parentId;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _topicController.dispose();
    _gt.removeListener(_onChannelChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ValidPermission(
          channelId: widget.channelId.id,
          permissions: [Permission.MANAGE_CHANNELS],
          builder: (value, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 10),
                  child: Text(
                    '频道名称'.tr,
                    style: _theme.textTheme.bodyText1.copyWith(fontSize: 13),
                  ),
                ),
                WebCustomInputBox(
                  readOnly: !value,
                  controller: _nameController,
                  fillColor: _theme.backgroundColor,
                  hintText: '请输入频道名称'.tr,
                  maxLength: 30,
                  onChange: (val) {
                    checkFormChanged();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 10),
                  child: Text(
                    '频道主题'.tr,
                    style: _theme.textTheme.bodyText1.copyWith(fontSize: 13),
                  ),
                ),
                WebCustomInputBox(
                  readOnly: !value,
                  controller: _topicController,
                  fillColor: _theme.backgroundColor,
                  hintText: '请输入频道主题'.tr,
                  maxLength: 300,
                  keyboardType: TextInputType.multiline,
                  onChange: (val) {
                    checkFormChanged();
                  },
                ),
                sizeHeight32,
                const Divider(
                  height: 1,
                ),
                sizeHeight32,
                LinkTile(
                  context,
                  Text(
                    '游客可见'.tr,
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xFF1F2125)),
                  ),
                  padding: EdgeInsets.zero,
                  showTrailingIcon: false,
                  trailing: Transform.scale(
                    scale: 0.9,
                    alignment: Alignment.centerRight,
                    child: CupertinoSwitch(
                        activeColor: Theme.of(context).primaryColor,
                        value: _isGuestVisible,
                        onChanged: (v) {
                          setState(() {
                            _isGuestVisible = v;
                          });
                          checkFormChanged();
                        }),
                  ),
                ),
                if (_channel.type == ChatChannelType.guildVoice) ...[
                  const SizedBox(height: 15),
                  const Divider(
                    height: 1,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '用户限制'.tr,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF1F2125)),
                        ),
                      ),
                      Text(
                        _userLimitInner <= 0 ? "" : "$_userLimitInner",
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.25,
                          color: Color(0xFF8F959E),
                        ),
                      ),
                      Text(
                        _userLimitInner <= 0 ? "无限制".tr : "用户".tr,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.25,
                          color: Color(0xFF8F959E),
                        ),
                      ),
                    ],
                  ),
                  _buildUserCountDescriptionWidget(context),
                  _buildUserCountWidget(),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildUserCountWidget() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          sizeHeight10,
          SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                thumbColor: Colors.white,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                // rangeThumbShape: const RoundRangeSliderThumbShape(),
                activeTrackColor: Theme.of(context).primaryColor,
                inactiveTrackColor: const Color(0xFF8F959E).withOpacity(0.2),
              ),
              child: Slider(
                value: _userLimitInner.toDouble(),
                max: (_userLimitInner.toDouble() <= 99 &&
                        _userLimitInner.toDouble() >= 0)
                    ? 99
                    : _userLimitInner.toDouble(),
                onChanged: (v) {
                  setState(() {
                    _userLimitInner = v.toInt();
                  });
                  checkFormChanged();
                },
              )),
          sizeHeight8,
        ],
      ),
    );
  }

  Widget _buildUserCountDescriptionWidget(BuildContext context) {
    final color = Theme.of(context).textTheme.bodyText1.color;
    return Container(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        "限制可以连接到此语音频道的用户数。拥有添加成员 权限的用户忽略此限制，并且可以将其他用户添加到 该频道。".tr,
        style: TextStyle(
            fontSize: 14,
            height: 1.21,
            color: color,
            backgroundColor: Colors.transparent),
      ),
    );
  }

  bool get formChanged {
    return _originChannelName != _nameController.text ||
        _originChannelTopic != _topicController.text ||
        _isOriginGuestVisible != _isGuestVisible ||
        _userLimitInner != (_channel.userLimit == -1 ? 0 : _channel.userLimit);
  }

  void checkFormChanged() {
    formDetectorModel.toggleChanged(formChanged);

    final nameLen = _nameController.text.trim().characters.length;
    final descLen = _topicController.text.trim().characters.length;
    final enable = nameLen > 0 && nameLen <= 30 && descLen <= 300;
    formDetectorModel.confirmEnabled(enable);
  }

  void _onReset() {
    setState(() {
      _nameController.value = TextEditingValue(
          text: _originChannelName,
          selection:
              TextSelection.collapsed(offset: _originChannelName.length));
      _topicController.value = TextEditingValue(
          text: _originChannelTopic,
          selection:
              TextSelection.collapsed(offset: _originChannelTopic.length));
      _isGuestVisible = _isOriginGuestVisible;

      _userLimitInner = _channel.userLimit == -1 ? 0 : _channel.userLimit;
    });
    checkFormChanged();
  }

  Future<void> _onConfirm() async {
    FocusScope.of(context).unfocus();
    String name = _nameController.text.trim();
    final String topic = _topicController.text.trim();
    name = name.isEmpty ? _originChannelName : name;
    final gt = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    final channelOrder = _getChannelOrder(gt.channels, _channel, _cateId);
    final pendingUserAccess = _isGuestVisible;
    await ChannelApi.updateChannel(
      Global.user.id,
      widget.channelId.guildId,
      widget.channelId.id,
      name: name,
      topic: topic,
      parentId: _cateId,
      channelOrder: channelOrder,
      pendingUserAccess: pendingUserAccess,
      userLimit: _userLimitInner <= 0 ? -1 : _userLimitInner,
    );
    gt
      ..channelOrder = channelOrder
      ..updateChannel(widget.channelId.id,
          name: name,
          topic: topic,
          parentId: _cateId,
          userLimit: _userLimitInner <= 0 ? -1 : _userLimitInner,
          pendingUserAccess: pendingUserAccess)
      ..sortChannels();
    unawaited(Db.channelBox.put(_channel.id, _channel));
    _originChannelTopic = topic;
    _originChannelName = name;
    _isOriginGuestVisible = _isGuestVisible;
    checkFormChanged();
  }

  List<String> _getChannelOrder(
      List<ChatChannel> oldChannels, ChatChannel channel, String parentId) {
    final newChannels = [...oldChannels];
    if (channel.parentId == parentId)
      return newChannels.map((e) => e.id).toList();
    newChannels.removeWhere((element) => element.id == channel.id);
    if (parentId == '') {
      final index = newChannels.lastIndexWhere((element) =>
          !isNotNullAndEmpty(element.parentId) &&
          element.type != ChatChannelType.guildCategory);
      newChannels.insert(index == -1 ? 0 : index + 1, channel);
      return newChannels.map((e) => e.id).toList();
    } else {
      newChannels.removeWhere((element) => element.id == channel.id);
      final childNum =
          newChannels.where((element) => element.parentId == parentId).length;
      final cateIdx =
          newChannels.indexWhere((element) => element.id == parentId);

      newChannels.insert(cateIdx + childNum + 1, channel);
      return newChannels.map((e) => e.id).toList();
    }
  }
}
