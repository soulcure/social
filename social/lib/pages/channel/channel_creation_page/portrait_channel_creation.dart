import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/channel/channel_creation_page/create_channel_controller.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/normal_text_input.dart';
import 'package:im/widgets/radio.dart';
import 'package:im/widgets/text_field/link_input.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:tuple/tuple.dart';

import '../../../routes.dart';
import 'view_model.dart';

class PortraitChannelCreation extends StatefulWidget {
  final String guildId;
  final String cateId;

  const PortraitChannelCreation(this.guildId, {this.cateId});

  @override
  _PortraitChannelCreationState createState() =>
      _PortraitChannelCreationState();
}

class _PortraitChannelCreationState extends State<PortraitChannelCreation> {
  // ViewModel _viewModel;

  @override
  void initState() {
    // _viewModel = ViewModel(guildId: widget.guildId, cateId: widget.cateId);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);

    return GetBuilder<CreateChannelController>(
      init: CreateChannelController(
          guildId: widget.guildId, cateId: widget.cateId),
      builder: (c) => GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size(double.infinity, kFbAppBarHeight),
            child: GetBuilder<CreateChannelController>(
              id: CreateChannelController.createButtonTag,
              builder: (c) => FbAppBar.custom(
                '创建频道'.tr,
                actions: [
                  if (c.isPrivateChannel)
                    createPrivateChannel(c)
                  else
                    createChannel(c, context),
                ],
              ),
            ),
          ),
          body: GetBuilder<CreateChannelController>(
            id: CreateChannelController.createInfoChanged,
            builder: (c) => ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                      top: 16, left: 16, bottom: 6, right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '频道名称'.tr,
                        style:
                            _theme.textTheme.bodyText1.copyWith(fontSize: 13),
                      ),
                      const SizedBox(width: 40),
                      if (c.cateName.hasValue)
                        Flexible(
                          child: Text(
                            '所属分类：%s'.trArgs([c?.cateName]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _theme.textTheme.bodyText1
                                .copyWith(fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ),
                NormalTextInput(
                  initText: c.channelName,
                  placeHolder: "请输入频道名称".tr,
                  maxCnt: 30,
                  onChanged: (value) {
                    setState(() {
                      c.channelName = value;
                    });
                  },
                ),
                sizeHeight16,
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    '频道类别'.tr,
                    style: _theme.textTheme.bodyText1.copyWith(fontSize: 13),
                  ),
                ),
                sizeHeight6,
                _buildChannelItem(
                    c.channelType,
                    ChatChannelType.guildText,
                    channelTypeInfo[ChatChannelType.guildText].item1,
                    c.isPrivateChannel
                        ? channelTypeInfo[ChatChannelType.guildText].item3
                        : channelTypeInfo[ChatChannelType.guildText].item2,
                    onTap: () => c.channelType = ChatChannelType.guildText),
                _buildChannelItem(
                  c.channelType,
                  ChatChannelType.guildLink,
                  channelTypeInfo[ChatChannelType.guildLink].item1,
                  c.isPrivateChannel
                      ? channelTypeInfo[ChatChannelType.guildLink].item3
                      : channelTypeInfo[ChatChannelType.guildLink].item2,
                  onTap: () => c.channelType = ChatChannelType.guildLink,
                ),
                _buildChannelItem(
                    c.channelType,
                    ChatChannelType.guildLive,
                    channelTypeInfo[ChatChannelType.guildLive].item1 +
                        c.endOfLiveString(),
                    c.isPrivateChannel
                        ? channelTypeInfo[ChatChannelType.guildLive].item3
                        : channelTypeInfo[ChatChannelType.guildLive].item2,
                    disabled: c.disableLive,
                    onTap: () => c.channelType = ChatChannelType.guildLive),
                Visibility(
                  visible: !c.videoCameraEnabled,
                  child: _buildChannelItem(
                    c.channelType,
                    ChatChannelType.guildVideo,
                    '音视频频道（敬请期待）'.tr,
                    c.isPrivateChannel
                        ? channelTypeInfo[ChatChannelType.guildVideo].item3
                        : channelTypeInfo[ChatChannelType.guildVideo].item2,
                    disabled: true,
                    showBorder: false,
                  ),
                ),
                Visibility(
                  visible: c.videoCameraEnabled,
                  child: _buildChannelItem(
                      c.channelType,
                      ChatChannelType.guildVoice,
                      channelTypeInfo[ChatChannelType.guildVoice].item1,
                      c.isPrivateChannel
                          ? channelTypeInfo[ChatChannelType.guildVoice].item3
                          : channelTypeInfo[ChatChannelType.guildVoice].item2,
                      onTap: () => c.channelType = ChatChannelType.guildVoice),
                ),

                /// 视频频道
                Visibility(
                  visible: c.videoCameraEnabled,
                  child: _buildChannelItem(
                      c.channelType,
                      ChatChannelType.guildVideo,
                      channelTypeInfo[ChatChannelType.guildVideo].item1,
                      c.isPrivateChannel
                          ? channelTypeInfo[ChatChannelType.guildVideo].item3
                          : channelTypeInfo[ChatChannelType.guildVideo].item2,
                      onTap: () => c.channelType = ChatChannelType.guildVideo),
                ),

                buildLinkInput(context),

                sizeHeight12,

                // 私密频道选择
                Container(
                  height: 52,
                  color: Colors.white,
                  child: Row(
                    children: [
                      sizeWidth16,
                      Text(
                        "私密频道".tr,
                        style: const TextStyle(
                            fontSize: 17,
                            height: 1.23,
                            color: Color(0xFF1F2126)),
                      ),
                      const Expanded(child: SizedBox()),
                      Transform.scale(
                        scale: 0.8,
                        alignment: Alignment.centerRight,
                        child: CupertinoSwitch(
                            activeColor: Theme.of(context).primaryColor,
                            value: c.isPrivateChannel,
                            onChanged: (value) {
                              if (value == true) {
                                FocusScope.of(context).unfocus();
                              }
                              c.isPrivateChannel = value;
                            }),
                      ),
                      sizeWidth16,
                    ],
                  ),
                ),

                Container(
                  margin: const EdgeInsets.only(left: 16, right: 30, top: 10),
                  child: Text("将频道设为私密，则只有所选成员及角色才能够查看此频道。".tr,
                      maxLines: 2,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF5C6273))),
                ),
                // if (viewModel.isPrivateChannel) _buildRoles(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 创建非私密频道
  AppBarActionModelInterface createChannel(
      CreateChannelController c, BuildContext context) {
    return AppBarTextPrimaryActionModel('创建'.tr,
        isLoading: c.createLoading,
        isEnable: !(c.createLoading ||
            c.channelName.isEmpty ||
            c.channelName.characters.length > 30), actionBlock: () async {
      FocusScope.of(context).unfocus();
      final resp = await c.create();
      if (resp.code == CreateChannelResponse.CodeSuccess) {
        Get.back(result: Tuple2(resp.channel, resp.overwrite));
      }
      showToast(resp.desc);
    });
  }

  /// 创建私密频道
  AppBarActionModelInterface createPrivateChannel(CreateChannelController c) {
    return AppBarTextLightActionModel('下一步'.tr, actionBlock: () async {
      if (c.createLoading ||
          c.channelName.isEmpty ||
          c.channelName.characters.length > 30) {
        if (c.channelName.isEmpty) {
          showToast("请输入频道名".tr);
        } else if (c.channelName.trim().characters.length > 30) {
          showToast("频道名需1-30个字符".tr);
        }
      } else {
        final errMsg = c.checkParam([
          CreateChannelController.checkItemName,
          CreateChannelController.checkItemLink
        ]);
        if (errMsg.isNotEmpty) {
          showToast(errMsg);
          return;
        }

        final resp =
            await Routes.pushChannelRoleOrUserSelectPage(c.guildId, c.cateId);
        if (resp != null && resp.code == CreateChannelResponse.CodeSuccess) {
          if (resp.channel != null) {
            final _currentSelectedGuild =
                ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
            final index = _currentSelectedGuild.channels.lastIndexWhere((e) =>
                    isNotNullAndEmpty(e.parentId) &&
                    e.type != ChatChannelType.guildCategory) +
                1;
            _currentSelectedGuild.channelOrder.insert(index, resp.channel.id);
            _currentSelectedGuild.addChannel(resp.channel,
                notify: true,
                initPermissions: resp.overwrite as List<PermissionOverwrite>);
            unawaited(Db.channelBox.put(resp.channel.id, resp.channel));

            /// 创建私密频道后，需要设置本地的频道范围权限为可访问，否则下次收到权限变更比对服务端
            /// 和客户端的值时，会视为权限变更，导致清理了 IM 的本地数据
            TextChannelUtil.setChannelViwePermission(resp.channel.id, true);
          }

          /// 返回主页 并进入频道
          Routes.backHome();
          await HomeScaffoldController.to.gotoWindow(1);
          await ChatTargetsModel.instance
              .selectChatTargetById(widget.guildId, channelId: resp.channel.id);
        }
      }
    });
  }

  Widget _buildChannelItem(ChatChannelType groupType, ChatChannelType type,
      String title, IconData icon,
      {bool disabled = false,
      GestureTapCallback onTap,
      bool showBorder = true}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: disabled
          ? null
          : () {
              onTap();
            },
      child: Container(
          height: 56,
          color: Theme.of(context).backgroundColor,
          child: Row(
            children: <Widget>[
              MyRadio(
                activeColor: Theme.of(context).primaryColor,
                value: type,
                onChanged: disabled ? null : (value) {},
                groupValue: groupType,
              ),
              Expanded(
                child: Container(
                  decoration: showBorder
                      ? BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: CustomColor(context)
                                    .disableColor
                                    .withOpacity(0.2),
                                width: 0.5),
                          ),
                        )
                      : null,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(icon,
                          size: 17,
                          color: disabled
                              ? const Color(0xFF8F959E).withOpacity(0.5)
                              : const Color(0xFF1F2125)),
                      sizeWidth12,
                      Text(title.tr,
                          style: TextStyle(
                            fontSize: 17,
                            color: disabled
                                ? const Color(0xFF8F959E).withOpacity(0.5)
                                : const Color(0xFF1F2125),
                          ))
                    ],
                  ),
                ),
              )
            ],
          )),
    );
  }

  Widget buildLinkInput(BuildContext context) {
    return GetBuilder<CreateChannelController>(
      id: CreateChannelController.channelTypeChanged,
      builder: (c) {
        if (c.channelType != ChatChannelType.guildLink) return sizedBox;
        return Container(
          margin: const EdgeInsets.only(top: 16),
          child: LinkInput(
            onChanged: (bean) => c.channelLinkBean = bean,
          ),
        );
      },
    );
  }
}
