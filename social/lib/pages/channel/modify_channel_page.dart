import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:im/api/channel_api.dart';
import 'package:im/app/theme/app_colors.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/const.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/db/db.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/link_tile.dart';
import 'package:im/widgets/text_field/link_input.dart';
import 'package:im/widgets/text_field/native_input.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

import '../../global.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;

class ModifyChannelPage extends StatefulWidget {
  final ChatChannel channel;

  const ModifyChannelPage(this.channel);

  @override
  _ModifyChannelPageState createState() => _ModifyChannelPageState();
}

class _ModifyChannelPageState extends State<ModifyChannelPage> {
  bool _loading = false;
  bool _deleteLoading = false;

  /// 游客是否可见
  bool _isGuestVisible = false;
  bool _enableConfirm = true;

  // bool _isPrivate = false;
  TextEditingController _nameController;
  TextEditingController _topicController;
  GuildTarget _gt;
  ChatChannel _channel;
  String _cateId;
  String _channelLink = '';

  int _userLimitInner = 10;
  final int _userLimitMax = 99;

  @override
  void initState() {
    _gt = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    _channel = _gt.channels.firstWhere(
        (element) => element.id == widget.channel.id,
        orElse: () => null);
    if (_channel == null) return;
    _nameController = TextEditingController(text: _channel.name);
    _topicController = TextEditingController(text: _channel.topic);
    _cateId = _channel.parentId;
    _channelLink = widget.channel.link ?? '';
    // 服务器端的值 -1和 大于 _userLimitMax 映射为最大值
    // 其他值，映射为 服务器值 -1 。
    _userLimitInner =
        (_channel.userLimit == -1 || _channel.userLimit > _userLimitMax)
            ? _userLimitMax
            : (_channel.userLimit - 1);
    _gt.addListener(_onChannelChange);

    // final gp = PermissionModel.getPermission(_gt.id);

    // _isPrivate = PermissionUtils.isPrivateChannel(gp, _channel.id);

    _isGuestVisible = _channel.pendingUserAccess ?? false;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _updateConfirmEnable();
    });
    super.initState();
  }

  void _onChannelChange() {
    _channel = _gt.channels.firstWhere(
        (element) => element.id == widget.channel.id,
        orElse: () => null);
    if (_channel == null) {
      if (!_deleteLoading) {
        Get.until(
            (route) => route.settings.name.startsWith(app_pages.Routes.HOME));
      }
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
    final _textStyle =
        Theme.of(context).textTheme.bodyText2.copyWith(fontSize: 16);
    const _hintStyle = TextStyle(fontSize: 16, color: Color(0xff8F959E));
    return WillPopScope(
      onWillPop: Loading.visible ? () => Future.value(!Loading.visible) : null,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kFbAppBarHeight),
            child: ValidPermission(
                channelId: widget.channel.id,
                permissions: [Permission.MANAGE_CHANNELS],
                builder: (value, _) {
                  return FbAppBar.custom(
                    '频道设置'.tr,
                    actions: [
                      if (value)
                        AppBarTextLightActionModel(
                          '确定'.tr,
                          isLoading: _loading,
                          isEnable: _enableConfirm,
                          actionBlock: _enableConfirm ? _onConfirm : null,
                        )
                    ],
                  );
                }),
          ),
          body: ListView(
            children: <Widget>[
              ValidPermission(
                channelId: widget.channel.id,
                permissions: [Permission.MANAGE_CHANNELS],
                builder: (value, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 20, left: 16, bottom: 10),
                        child: Text(
                          '频道名称'.tr,
                          style:
                              _theme.textTheme.bodyText1.copyWith(fontSize: 14),
                        ),
                      ),
                      Container(
                        height: 52,
                        color: _theme.backgroundColor,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: NativeInput(
                                readOnly: !value,
                                decoration: InputDecoration.collapsed(
                                  hintText: '请输入频道名称'.tr,
                                  hintStyle: _hintStyle,
                                ),
                                maxLengthEnforcement: MaxLengthEnforcement.none,
                                controller: _nameController,
                                onChanged: (value) {
                                  _updateConfirmEnable();
                                },
                              ),
                            ),
                            sizeWidth8,
                            RichText(
                              text: TextSpan(
                                  text:
                                      '${_nameController.text.trim().characters.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _nameController.text
                                                .trim()
                                                .characters
                                                .length >
                                            maxChannelNameLength
                                        ? Theme.of(context).errorColor
                                        : const Color(0xFF8F959E),
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: '/$maxChannelNameLength',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF8F959E)),
                                    )
                                  ]),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 20, left: 16, bottom: 10),
                        child: Text(
                          '频道介绍'.tr,
                          style:
                              _theme.textTheme.bodyText1.copyWith(fontSize: 14),
                        ),
                      ),
                      Container(
                        color: _theme.backgroundColor,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: NativeInput(
                          readOnly: !value,
                          controller: _topicController,
                          decoration: InputDecoration.collapsed(
                            hintText: '请输入频道介绍'.tr,
                            hintStyle: _hintStyle,
                          ),
                          maxLength: maxChannelDescLength,
                          maxLengthEnforcement: MaxLengthEnforcement.none,
                          height: 123,
                          maxLines: 4,
                          onChanged: (val) {
                            _updateConfirmEnable();
                          },
                          buildCounter: (_,
                              {currentLength, maxLength, isFocused}) {
                            return buildCount(currentLength, maxLength);
                          },
                        ),
                      ),
                      if (widget.channel.type == ChatChannelType.guildLink)
                        Padding(
                          padding: const EdgeInsets.only(top: 26),
                          child: LinkInput(
                            onChanged: (text) =>
                                _channelLink = text.toLinkString(),
                            linkBean:
                                LinkBean.fromStringLink(widget.channel.link),
                          ),
                        )
                    ],
                  );
                },
              ),
              // sizeHeight20,
              // ValidPermission(
              //     channelId: widget.channel.id,
              //     permissions: [Permission.MANAGE_CHANNELS],
              //     builder: (value, isOwner) {
              //       if (!value) return const SizedBox();
              //       return LinkTile(context, Text('可见范围'),
              //           trailing: ConstrainedBox(
              //             constraints: const BoxConstraints(maxWidth: 110),
              //             child: Text(
              //               "公开".tr,
              //               overflow: TextOverflow.ellipsis,
              //               style: _theme.textTheme.bodyText1,
              //             ),
              //           ),
              //           height: 48,
              //           onTap: (){
              //
              //           });
              //     }),
              const SizedBox(height: 26),
              ValidPermission(
                permissions: [Permission.MANAGE_CHANNELS],
                builder: (value, isOwner) {
                  if (!value) return const SizedBox();
                  return LinkTile(
                    context,
                    Text('分类'.tr, style: _textStyle),
                    trailing: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: Text(
                        _getChannelCateName(_cateId).tr,
                        overflow: TextOverflow.ellipsis,
                        style: _theme.textTheme.bodyText1,
                      ),
                    ),
                    height: 48,
                    onTap: _showSelectCategory,
                  );
                },
              ),
              Divider(
                indent: 16,
                thickness: 0.5,
                color: const Color(0xFF8F959E).withOpacity(0.2),
              ),
              ValidPermission(
                  channelId: widget.channel.id,
                  permissions: [Permission.MANAGE_ROLES],
                  builder: (value, isOwner) {
                    if (!value) return const SizedBox();
                    return Column(
                      children: [
                        LinkTile(
                          context,
                          Text('频道权限'.tr, style: _textStyle),
                          height: 48,
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            Routes.pushChannelPermissionPage(
                                context, widget.channel);
                          },
                        ),
                        _buildDescriptionWidget("更改隐私设置，并自定义角色与此频道互动的方式。".tr),
                      ],
                    );
                  }),
              // 只有文字频道可以设置快捷指令
              if (widget.channel.type == ChatChannelType.guildText)
                ValidPermission(
                    permissions: [Permission.MANAGE_CHANNELS],
                    builder: (value, isOwner) {
                      if (!value) return const SizedBox();
                      // 只有服务器所有者可以设置频道快捷指令
                      if (_isGuildOwner())
                        return Column(
                          children: [
                            LinkTile(
                                context, Text('频道快捷指令'.tr, style: _textStyle),
                                height: 48, onTap: () {
                              Routes.pushChannelCommandShortcutsSettings(
                                  widget.channel);
                            }),
                            _buildDescriptionWidget("设置频道中机器人的快捷指令。".tr),
                          ],
                        );
                      return const SizedBox();
                    }),
              // if (!_isPrivate)
              LinkTile(
                context,
                Text('游客可见'.tr, style: _textStyle),
                height: 48,
                showTrailingIcon: false,
                trailing: Transform.scale(
                  scale: 0.9,
                  alignment: Alignment.centerRight,
                  child: CupertinoSwitch(
                      activeColor: Theme.of(context).primaryColor,
                      value: _isGuestVisible,
                      onChanged: (value) {
                        setState(() {
                          _isGuestVisible = value;
                        });
                      }),
                ),
              ),
              _buildDescriptionWidget("游客状态的用户可进入此频道查看消息，但无法发送消息及表态。".tr),

              if (widget.channel.type == ChatChannelType.guildVoice ||
                  widget.channel.type == ChatChannelType.guildVideo) ...[
                _buildUserCountWidget(_textStyle),
                _buildDescriptionWidget(
                    "限制可以连接到此语音频道的用户数，拥有服务器管理频道权限的用户忽略此限制。".tr),
              ],

              ValidPermission(
                  channelId: widget.channel.id,
                  permissions: [Permission.MANAGE_CHANNELS],
                  builder: (value, isOwner) {
                    if (!value) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: FadeBackgroundButton(
                        backgroundColor: Theme.of(context).backgroundColor,
                        tapDownBackgroundColor:
                            Theme.of(context).backgroundColor.withOpacity(0.5),
                        onTap: _removeChannel,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _deleteLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: appThemeData.primaryColor,
                                    backgroundColor: Colors.white,
                                    strokeWidth: 1.5,
                                  ),
                                )
                              : Text(
                                  '删除频道'.tr,
                                  style: const TextStyle(
                                      color: DefaultTheme.dangerColor),
                                ),
                        ),
                      ),
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCount(int currentLength, int maxLength) {
    return RichText(
      text: TextSpan(
          text: '$currentLength',
          style: Theme.of(context).textTheme.bodyText1.copyWith(
                fontSize: 12,
                color: currentLength > maxLength
                    ? DefaultTheme.dangerColor
                    : const Color(0xFF8F959E),
              ),
          children: [
            TextSpan(
              text: '/$maxLength',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8F959E),
              ),
            )
          ]),
    );
  }

  Widget _buildDescriptionWidget(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 26),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildUserCountWidget(TextStyle style) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text("用户限制".tr, style: style),
                ),
                Text(
                  _userLimitInner >= _userLimitMax
                      ? ""
                      : "${_userLimitInner + 1}",
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.25,
                    color: Color(0xFF8F959E),
                  ),
                ),
                const SizedBox(
                  width: 2,
                ),
                Text(
                  _userLimitInner >= _userLimitMax ? "无限制".tr : "用户".tr,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.25,
                    color: Color(0xFF8F959E),
                  ),
                ),
              ],
            ),
          ),
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
                max: _userLimitMax.toDouble(),
                // max: (_userLimitInner.toDouble() <= _userLimitMax &&
                //         _userLimitInner.toDouble() > 0)
                //     ? _userLimitMax
                //     : _userLimitInner.toDouble(),
                divisions: _userLimitMax,
                onChanged: (v) {
                  setState(() {
                    _userLimitInner = v.toInt();
                  });
                  logger.info("onChange value:$v");
                },
              )),
          sizeHeight8,
        ],
      ),
    );
  }

  void _updateConfirmEnable() {
    final nameLen = _nameController.text.trim().characters.length;
    final topicLen = _topicController.text.trim().characters.length;
    setState(() {
      _enableConfirm = nameLen > 0 &&
          nameLen <= maxChannelNameLength &&
          topicLen <= maxChannelDescLength;
    });
  }

  Future<void> _onConfirm() async {
    FocusScope.of(context).unfocus();
    if (!_onLinkChannelConfirm()) return;
    final String name = _nameController.text.trim();
    final String topic = _topicController.text.trim();
    _toggleLoading(true);
    try {
      final pendingUserAccess = _isGuestVisible;
      final gt = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
      final channelOrder = _getChannelOrder(gt.channels, _channel, _cateId);
      await ChannelApi.updateChannel(
          Global.user.id, widget.channel.guildId, widget.channel.id,
          name: name,
          topic: topic,
          parentId: _cateId,
          channelOrder: channelOrder,
          userLimit:
              _userLimitInner >= _userLimitMax ? -1 : (_userLimitInner + 1),
          pendingUserAccess: pendingUserAccess,
          link: _channelLink);
      gt
        ..channelOrder = channelOrder
        ..updateChannel(widget.channel.id,
            name: name,
            topic: topic,
            parentId: _cateId,
            userLimit:
                _userLimitInner >= _userLimitMax ? -1 : (_userLimitInner + 1),
            link: _channelLink,
            pendingUserAccess: pendingUserAccess)
        ..sortChannels()
        ..reload();
      unawaited(Db.channelBox.put(_channel.id, _channel));
      _toggleLoading(false);
      Routes.pop(context);
    } catch (e) {
      _toggleLoading(false);
    }
  }

  bool _onLinkChannelConfirm() {
    bool canSubmit = true;
    final channel = widget.channel;
    final isLinked = channel.type == ChatChannelType.guildLink;
    if (!isLinked) return canSubmit;
    if (_channelLink.isEmpty) {
      showToast('请输入频道链接'.tr);
      canSubmit = false;
    }
    return canSubmit;
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

  void _toggleLoading(bool value) {
    if (value) {
      Loading.show(context, isEmpty: true);
    } else {
      Loading.hide();
    }
    setState(() {
      _loading = value;
    });
  }

  Future<void> _removeChannel() async {
    //  如果正在删除就不能点击
    if (_deleteLoading) {
      return;
    }
    final res = await showConfirmDialog(
      title: '删除频道'.tr,
      content: '确定将 %s 删除？一旦删除不可撤销。'.trArgs([_channel?.name]),
      confirmText: "确定删除".tr,
      confirmStyle: appThemeData.textTheme.bodyText2.copyWith(
        color: redTextColor,
        fontSize: 17,
      ),
    );
    if (res == true) {
      setState(() {
        _deleteLoading = true;
      });
      final guildTarget =
          ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
      final ChatChannel channel = guildTarget.channels.firstWhere(
          (element) => element.id == widget.channel.id,
          orElse: () => null);

      try {
        if (channel != null) {
          await guildTarget.removeChannel(channel);
        }
        Get.back();
      } catch (e) {
        debugPrint("删除频道异常: $e");
      }
      setState(() {
        _deleteLoading = false;
      });
    }
  }

  String _getChannelCateName(String channelCateId) {
    final GuildTarget guild =
        ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    final selectedChannel = guild.channels.firstWhere(
        (element) => element.id == channelCateId,
        orElse: () => null);
    return selectedChannel?.name ?? '无'.tr;
  }

  Future<void> _showSelectCategory() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));
    final GuildTarget guild =
        ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    final List<ChatChannel> categories = guild.channels
        .where((element) => element.type == ChatChannelType.guildCategory)
        .toList();
    categories.insert(0, ChatChannel(id: '', name: '无'.tr));
    if (categories.isEmpty) {
      showToast('无频道分类，无法设置'.tr);
      return;
    }
    final res = await showCustomActionSheet(
      categories
          .map((e) => Text(
                e.name.tr,
                style: appThemeData.textTheme.bodyText2,
              ))
          .toList(),
    );
    if (res != null) {
      setState(() {
        _cateId = categories[res].id;
      });
    }
  }

  bool _isGuildOwner() {
    return (ChatTargetsModel.instance.selectedChatTarget as GuildTarget)
            .ownerId ==
        Global.user.id;
  }
}
