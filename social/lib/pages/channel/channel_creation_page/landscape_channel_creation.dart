import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/channel/channel_creation_page/view_model.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/web/widgets/radio.dart';
import 'package:im/widgets/normal_text_input.dart';
import 'package:provider/provider.dart';

import '../../../web/utils/confirm_dialog/setting_dialog.dart';

class LanscapeChannelCreation extends SettingDialog {
  final String guildId;
  final String cateId;

  LanscapeChannelCreation(this.guildId, {this.cateId});

  @override
  _CreateChannelPageWebState createState() => _CreateChannelPageWebState();
}

class _CreateChannelPageWebState
    extends SettingDialogState<LanscapeChannelCreation> {
  ViewModel _viewModel;

  @override
  void initState() {
    _viewModel = ViewModel(
        guildId: widget.guildId, cateId: widget.cateId, loading: loading);
    super.initState();
  }

  @override
  Widget body() {
    final _theme = Theme.of(context);
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Consumer<ViewModel>(builder: (context, viewModel, child) {
          return Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
            height: viewModel.isPrivateChannel ? 438 : 308,
            child: ListView(
              children: <Widget>[
                Text(
                  '频道名称'.tr,
                  style: _theme.textTheme.bodyText1,
                ),
                sizeHeight10,
                borderWraper(
                  child: NormalTextInput(
                    initText: viewModel.channelName,
                    placeHolder: "请输入频道名称".tr,
                    maxCnt: 30,
                    height: 40,
                    fontSize: 14,
                    backgroundColor: Colors.transparent,
                    contentPadding: const EdgeInsets.only(bottom: 10),
                    onChanged: (value) {
                      viewModel.channelName = value.trim();
                      enable.value = value.trim().length <= 30;
                    },
                  ),
                ),
                sizeHeight16,
                Text(
                  '频道类别'.tr,
                  style: _theme.textTheme.bodyText1.copyWith(fontSize: 13),
                ),
                sizeHeight10,
                borderWraper(
                  child: _buildChannelItem(
                      viewModel.channelType,
                      ChatChannelType.guildText,
                      channelTypeInfo[ChatChannelType.guildText].item1,
                      viewModel.isPrivateChannel
                          ? channelTypeInfo[ChatChannelType.guildText].item3
                          : channelTypeInfo[ChatChannelType.guildText].item2,
                      onTap: () =>
                          viewModel.setChannelType(ChatChannelType.guildText)),
                ),
                Visibility(
                  visible: !viewModel.videoCameraEnabled,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: borderWraper(
                      child: _buildChannelItem(
                        viewModel.channelType,
                        ChatChannelType.guildVideo,
                        '音视频频道（敬请期待）'.tr,
                        viewModel.isPrivateChannel
                            ? channelTypeInfo[ChatChannelType.guildVideo].item3
                            : channelTypeInfo[ChatChannelType.guildVideo].item2,
                        disabled: true,
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: _viewModel.videoCameraEnabled,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: borderWraper(
                      child: _buildChannelItem(
                          viewModel.channelType,
                          ChatChannelType.guildVoice,
                          channelTypeInfo[ChatChannelType.guildVoice].item1,
                          viewModel.isPrivateChannel
                              ? channelTypeInfo[ChatChannelType.guildVoice]
                                  .item3
                              : channelTypeInfo[ChatChannelType.guildVoice]
                                  .item2,
                          onTap: () => viewModel
                              .setChannelType(ChatChannelType.guildVoice)),
                    ),
                  ),
                ),
                Visibility(
                  visible: _viewModel.videoCameraEnabled,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: borderWraper(
                      child: _buildChannelItem(
                          viewModel.channelType,
                          ChatChannelType.guildVideo,
                          channelTypeInfo[ChatChannelType.guildVideo].item1,
                          viewModel.isPrivateChannel
                              ? channelTypeInfo[ChatChannelType.guildVideo]
                                  .item3
                              : channelTypeInfo[ChatChannelType.guildVideo]
                                  .item2,
                          onTap: () => viewModel
                              .setChannelType(ChatChannelType.guildVideo)),
                    ),
                  ),
                ),
                sizeHeight24,
                divider,
                sizeHeight12,
                // 私密频道选择
                Container(
                  height: 52,
                  color: Colors.white,
                  child: Row(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            IconFont.buffSimiwenzipindao,
                            size: 16,
                          ),
                          sizeWidth4,
                          Text("私密频道(指定角色可见)".tr,
                              style: Theme.of(context).textTheme.bodyText1),
                        ],
                      ),
                      const Expanded(child: SizedBox()),
                      Transform.scale(
                        scale: 0.8,
                        alignment: Alignment.centerRight,
                        child: CupertinoSwitch(
                            activeColor: Theme.of(context).primaryColor,
                            value: viewModel.isPrivateChannel,
                            onChanged: (value) {
                              if (value == true) {
                                FocusScope.of(context).unfocus();
                              }
                              viewModel.setIsPrivateChannel(value);
                            }),
                      ),
                    ],
                  ),
                ),
                if (viewModel.isPrivateChannel) _buildRoles()
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  String get title => '创建频道'.tr;

  @override
  Future<void> finish() => _viewModel.create(context);

  Widget _buildRoles() {
    // 获取最新角色列表信息
    final List<Role> rolesList = _viewModel.guildRoles();

    // 用来更新历史选中的角色信息 (因为角色管理排序 / 删除 / 新增会导致Role对象更新)
    final List<Role> tempRoleList = [...rolesList];

    // 将最新的角色列表信息筛选出选中的数据重新给 roleSelected 数据源赋值,否则会导致某个角色信息变化后,roleSelected无法移除对象的问题
    tempRoleList.removeWhere((element) {
      return !_viewModel.roleSelected
          .map((e) {
            return e.id;
          })
          .toList()
          .contains(element.id);
    });
    _viewModel.roleSelected = tempRoleList;

    return Container(
      color: Colors.white,
      child: Column(
          children: rolesList.map((r) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (_viewModel.roleSelected
                .map((e) {
                  return e.id;
                })
                .toList()
                .contains(r.id)) {
              _viewModel.roleSelected.remove(r);
            } else {
              _viewModel.roleSelected.add(r);
            }
            _viewModel.setRoleSelected(_viewModel.roleSelected);
          },
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 16, 11),
                child: WebRadio(
                    value: _viewModel.roleSelected.map((se) {
                      return se.id;
                    }).contains(r.id),
                    groupValue: true,
                    type: WebRadioType.iconRight,
                    onChanged: (value) {}),
              ),
              Text(
                r.name,
                style: TextStyle(
                    fontSize: 16,
                    color: (r.color == null || r.color == 0)
                        ? Colors.black
                        : Color(r.color)),
              ),
            ],
          ),
        );
      }).toList()),
    );
  }

  Widget _buildChannelItem(ChatChannelType groupType, ChatChannelType type,
      String title, IconData icon,
      {bool disabled = false, GestureTapCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: disabled
          ? null
          : () {
              onTap();
            },
      child: Row(
        children: <Widget>[
          sizeWidth12,
          WebRadio(
            activeColor: Theme.of(context).primaryColor,
            value: type,
            onChanged: disabled ? null : (value) {},
            groupValue: groupType,
          ),
          sizeWidth16,
          Icon(icon,
              size: 16,
              color: disabled
                  ? Theme.of(context).iconTheme.color.withOpacity(0.25)
                  : Theme.of(context).iconTheme.color),
          sizeWidth4,
          Text(title.tr,
              style: TextStyle(
                fontSize: 14,
                color: disabled
                    ? Theme.of(context)
                        .textTheme
                        .bodyText2
                        .color
                        .withOpacity(0.25)
                    : Theme.of(context).textTheme.bodyText2.color,
              ))
        ],
      ),
    );
  }
}
