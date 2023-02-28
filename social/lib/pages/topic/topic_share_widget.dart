import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/guild_setting/circle/circle_share/circle_share_widget.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/widgets/check_circle_box.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:oktoast/oktoast.dart';

import '../../icon_font.dart';

void shareTopic(BuildContext context, MessageEntity message) {
  if (OrientationUtil.portrait)
    showBottomModal(
      context,
      bottomInset: false,
      backgroundColor: appThemeData.scaffoldBackgroundColor,
      builder: (c, s) => ShareWidget(
        guildId: message.guildId,
        buttonText: '转发'.tr,
        onSend: (selectedChannels, guildTargetModel) {
          final mes = message;
          final Set<ChatChannel> wrongSet = {};
          selectedChannels.forEach((key, value) {
            final GuildPermission gp =
                PermissionModel.getPermission(value.guildId);
            final canSendMes = PermissionUtils.oneOf(
                gp, [Permission.SEND_MESSAGES],
                channelId: key);
            final isChannelDeleted =
                guildTargetModel.getChannel(value.id) == null;
            if (!canSendMes || isChannelDeleted) {
              wrongSet.add(value);
            } else {
              final tcController = TextChannelController.to(channelId: key);
              tcController.sendContent(
                  TopicShareEntity(mes.messageId, mes.channelId, mes.userId));
            }
          });
          if (wrongSet.isEmpty)
            showToast('转发成功'.tr);
          else {
            String errorChannels = '';
            wrongSet.forEach((element) {
              final isLast = element == wrongSet.last;
              errorChannels += '#${element.name}${isLast ? '' : '、'.tr}';
            });
            showToast('%s 出现变动发送失败，请刷新频道列表重试'.trArgs([errorChannels]));
          }
        },
      ),
    );
  else {
    SuperTooltip tip;
    tip = SuperTooltip(
      popupDirection: TooltipDirection.bottom,
      content: Material(
        child: Container(
            width: 400,
            decoration: BoxDecoration(
                color: CustomColor(context).backgroundColor6,
                boxShadow: const [BoxShadow(blurRadius: 2)]),
            child: ShareTopicWidget(
              message: message,
              closeCallback: () => tip.close(),
            )),
      ),
    );
    tip.show(context);
  }
}

class ShareTopicWidget extends StatefulWidget {
  final MessageEntity message;
  final VoidCallback closeCallback;

  const ShareTopicWidget({Key key, this.message, this.closeCallback})
      : super(key: key);

  @override
  _ShareTopicWidgetState createState() => _ShareTopicWidgetState();
}

class _ShareTopicWidgetState extends State<ShareTopicWidget> {
  final List<ChatChannel> _channels = [];
  final List<bool> _channelValue = [];
  Rx<int> selectedIndex = Rx<int>(-1);

  ///key为channelId
  final Map<String, ChatChannel> _selectedChannels = {};

  bool isNetWorkNormal = true;
  GuildTarget _guildTargetModel;

  bool get hasSelected => _selectedChannels.isNotEmpty;

  int get select => selectedIndex.value;

  set select(int index) => selectedIndex.value = index;

  @override
  void initState() {
    final list = ChatTargetsModel.instance.chatTargets;
    list.forEach((e) {
      if (e is GuildTarget && e.id == widget.message.guildId)
        _guildTargetModel = e;
    });
    if (_guildTargetModel != null) {
      initialData();
    }
    super.initState();
  }

  void initialData() {
    _guildTargetModel.channels?.forEach((channel) {
      final isTextChannel = channel.type == ChatChannelType.guildText;
      final GuildPermission gp = PermissionModel.getPermission(channel.guildId);
      final canSendMes = PermissionUtils.oneOf(gp, [Permission.SEND_MESSAGES],
          channelId: channel.id);
      final isVisible = PermissionUtils.isChannelVisible(
          gp, channel.id); //[dj private channel]
      if (isTextChannel && canSendMes && isVisible) {
        _channels.add(channel);
        _channelValue.add(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.of(context).size.height / 2;

    return Container(
      constraints: BoxConstraints(maxHeight: height > 400 ? 400 : height),
      child: buildMenu(theme),
    );
  }

  Widget buildMenu(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 18),
          child: Text(
            '分享至频道'.tr,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        Expanded(
          child: Scrollbar(
            child: ListView(
              padding: const EdgeInsets.all(0),
              children: List.generate(_channelValue.length, (index) {
                final channel = _channels[index];
                final color = isChannelColorBlack(channel)
                    ? const Color(0xff1F2125)
                    : Colors.grey;
                final isPrivate = PermissionUtils.isPrivateChannel(
                    PermissionModel.getPermission(channel.guildId), channel.id);
                return GestureDetector(
                  onTap: () {
                    onValueChange(index);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        AbsorbPointer(
                          absorbing: _selectedChannels.length >= 9 &&
                              _channelValue[index] == false,
                          child: Obx(() => AnimatedContainer(
                                duration: const Duration(milliseconds: 20),
                                child: CheckCircleBox(
                                  value: select == index,
                                  onChanged: (v) {
                                    onValueChange(v ? index : -1);
                                  },
                                ),
                              )),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          isPrivate
                              ? IconFont.buffSimiwenzipindao
                              : IconFont.buffWenzipindaotubiao,
                          size: 16,
                          color: const Color(0xff8F959E),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _channels[index].name,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: color),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        buildButton(theme, '发送'.tr, true, onPressed: () {
          if (_selectedChannels.isEmpty) return;

          _shareTopic(context);
//          _controller.nextPage(
//              duration: const Duration(milliseconds: 200),
//              curve: Curves.linear);
        })
      ],
    );
  }

  Widget buildButton(ThemeData theme, String text, bool hasSelected,
      {VoidCallback onPressed}) {
    return Column(
      children: [
        Container(
          height: 0.5,
          color: const Color(0xff8F959E).withOpacity(0.3),
          margin: const EdgeInsets.only(bottom: 7.5),
        ),
        Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          // ignore: deprecated_member_use
          child: FlatButton(
            onPressed: onPressed,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            color: hasSelected
                ? theme.primaryColor
                : theme.scaffoldBackgroundColor,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(
                    fontSize: 17,
                    color:
                        hasSelected ? null : theme.textTheme.bodyText1.color),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _shareTopic(BuildContext context) {
    final mes = widget.message;
    final Set<ChatChannel> wrongSet = {};
    _selectedChannels.forEach((key, value) {
      final GuildPermission gp = PermissionModel.getPermission(value.guildId);
      final canSendMes =
          PermissionUtils.oneOf(gp, [Permission.SEND_MESSAGES], channelId: key);
      final isChannelDeleted = _guildTargetModel.getChannel(value.id) == null;
      if (!canSendMes || isChannelDeleted) {
        wrongSet.add(value);
      } else {
        final tcController = TextChannelController.to(channelId: key);
        tcController.sendContent(
            TopicShareEntity(mes.messageId, mes.channelId, mes.userId));
      }
    });
    if (wrongSet.isEmpty)
      showToast('转发成功'.tr);
    else {
      String errorChannels = '';
      wrongSet.forEach((element) {
        final isLast = element == wrongSet.last;
        errorChannels += '#${element.name}${isLast ? '' : '、'.tr}';
      });
      showToast('%s 出现变动发送失败，请刷新频道列表重试'.trArgs([errorChannels]));
    }
    if (widget.closeCallback == null)
      Get.back();
    else
      widget.closeCallback();
  }

  @override
  void dispose() {
    clearData();
    super.dispose();
  }

  void onValueChange(int index) {
    select = index;
    _selectedChannels.clear();
    if (index >= 0) {
      final channel = _channels[index];
      _selectedChannels[channel.id] = channel;
    }

    // final v = !_channelValue[index];
    // if (_selectedChannels.length >= 9 && v) {
    //   showToast('同时最多只能选择9个频道'.tr);
    //   return;
    // }
    // final channel = _channels[index];
    // if (v) {
    //   _selectedChannels[channel.id] = channel;
    // } else
    //   _selectedChannels.remove(channel.id);
    // _channelValue[index] = v;
    // _refresh();
  }

  void onConnectivityChanged(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      isNetWorkNormal = false;
    } else
      isNetWorkNormal = true;
    _refresh();
  }

  bool isChannelColorBlack(ChatChannel channel) {
    if (_selectedChannels.length != 9) return true;
    if (_selectedChannels[channel.id] != null) return true;
    return false;
  }

  void clearData() {
    _channels.clear();
    _channelValue.clear();
    _selectedChannels.clear();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }
}
