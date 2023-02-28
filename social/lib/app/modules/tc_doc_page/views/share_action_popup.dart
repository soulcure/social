import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:fluwx/fluwx.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/document_online/document_api.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/doc_info_item.dart';
import 'package:im/app/modules/friend_list_page/controllers/friend_list_page_controller.dart';
import 'package:im/app/modules/tc_doc_add_group_page/entities/tc_doc_group.dart';
import 'package:im/app/modules/tc_doc_page/controllers/tc_doc_page_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/global_methods/goto_direct_message.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/circle/circle_share/circle_share_widget.dart';
import 'package:im/pages/guild_setting/role/role_icon.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/tc_doc_utils.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/link_tile.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/share_link_popup/share_friends_popup.dart';
import 'package:im/widgets/share_link_popup/share_type.dart';
import 'package:im/widgets/toast.dart';
import 'package:im/widgets/user_info/popup/stack_pictures.dart';
import 'package:oktoast/oktoast.dart';

import '../../../../global.dart';

Future<void> showShareActionPopup({
  @required BuildContext context,
  @required DocInfoItem docInfo,
}) async {
  await showBottomModal(
    context,
    builder: (c, s) => ShareActionPopup(
      docInfo: docInfo,
    ),
    backgroundColor: appThemeData.scaffoldBackgroundColor,
    resizeToAvoidBottomInset: false,
  );
}

class ShareActionPopup extends StatefulWidget {
  final DocInfoItem docInfo;
  const ShareActionPopup({
    @required this.docInfo,
  });

  @override
  _ShareActionPopupState createState() => _ShareActionPopupState();
}

const divider = Divider(
  thickness: 0.5,
  indent: 16,
);

class _ShareActionPopupState extends State<ShareActionPopup> {
  final Color specColor = const Color(0xff737780).withOpacity(0.2);
  GuildTarget guild;
  ValueNotifier<UserInfo> user;
  List<TcDocGroup> docGroups = [];

  bool get isOwner => widget.docInfo.userId == Global.user.id;

  bool get isInGuild => ChatTargetsModel.instance.chatTargets
      .any((element) => element.id == widget.docInfo.guildId);

  String get docUrl => widget.docInfo.url;

  @override
  void initState() {
    // 文档所有者并且在服务器内才能邀请协作者
    if (isOwner && isInGuild) {
      DocumentApi.docGroups(widget.docInfo.fileId, pageSize: 200).then((res) {
        docGroups = List<TcDocGroup>.from(
          (res['lists'] as List)
              .map((e) => TcDocGroup.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
        );
        docGroups.insert(
          0,
          TcDocGroup(
            type: TcDocGroupType.user,
            role: TcDocGroupRole.edit,
            targetId: Global.user.id,
            fileId: widget.docInfo.fileId,
          ),
        );
        if (docGroups.isNotEmpty) setState(() {});
      });
    }
    super.initState();
  }

  List<ShareItem> get shareConfigs => [
        ShareItem(
          radius: 8,
          size: 52,
          iconBgColor: appThemeData.backgroundColor,
          config: WechatShareToFriendConfig(),
          action: WechatShareLinkAction(
            title: widget.docInfo.title,
            subtitle: widget.docInfo.url,
            link: docUrl,
            icon:
                "https://fb-cdn.fanbook.mobi/fanbook/tc-doc/${DocTypeExtension.name(widget.docInfo.type)}.png",
          ),
          textStyle: shareItemTextStyle,
          // padding: padding,
        ),
        ShareItem(
          radius: 8,
          size: 52,
          iconBgColor: appThemeData.backgroundColor,
          config: WechatShareToMomentConfig(),
          action: WechatShareLinkAction(
            title: widget.docInfo.title,
            subtitle: widget.docInfo.url,
            link: docUrl,
            icon:
                "https://fb-cdn.fanbook.mobi/fanbook/tc-doc/${DocTypeExtension.name(widget.docInfo.type)}.png",
            scene: WeChatScene.TIMELINE,
          ),
          textStyle: shareItemTextStyle,
          // padding: padding,
        ),
        ShareItem(
          radius: 8,
          size: 52,
          iconBgColor: appThemeData.backgroundColor,
          config: CopyLinkShareConfig(),
          action: CopyLinkShareAction(docUrl),
          textStyle: shareItemTextStyle,
          // padding: padding,
        )
      ];

  TextStyle get shareItemTextStyle =>
      Get.textTheme.bodyText2.copyWith(fontSize: 10);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        sizeHeight12,
        Text(
          '分享文档'.tr,
          style: const TextStyle(
              height: 21 / 17, fontSize: 17, fontWeight: FontWeight.w500),
        ),
        sizeHeight12,
        Container(
          // color: CustomColor(context).backgroundColor7,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            children: <Widget>[
              if (isOwner && isInGuild) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    children: <Widget>[
                      LinkTile(
                        context,
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              IconFont.buffJoinGuild,
                              size: 17,
                            ),
                            sizeWidth8,
                            Text(
                              '邀请协作者'.tr,
                              style: const TextStyle(
                                  height: 20 / 16,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16),
                            ),
                          ],
                        ),
                        height: 52,
                        onTap: _toAddGroupPage,
                      ),
                      const Divider(
                        indent: 16,
                        thickness: 0.5,
                      ),
                      LinkTile(
                        context,
                        Row(
                          children: <Widget>[
                            const Icon(IconFont.buffFriendList, size: 17),
                            sizeWidth8,
                            Text(
                              '协作者'.tr,
                              style: const TextStyle(
                                  height: 20 / 16,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16),
                            ),
                          ],
                        ),
                        height: 52,
                        trailing: _buildGroupsAvatar(),
                        onTap: _toGroupsPage,
                      ),
                    ],
                  ),
                ),
                sizeHeight16,
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  children: <Widget>[
                    if (isInGuild) ...[
                      LinkTile(
                        context,
                        Text(
                          '分享至频道'.tr,
                          style: const TextStyle(
                              fontWeight: FontWeight.w400, fontSize: 16),
                        ),
                        height: 52,
                        onTap: _shareToChannel,
                      ),
                      const Divider(
                        indent: 16,
                        thickness: 0.5,
                      ),
                    ],
                    LinkTile(
                      context,
                      Text(
                        '分享给好友'.tr,
                        style: const TextStyle(
                            fontWeight: FontWeight.w400, fontSize: 16),
                      ),
                      height: 52,
                      onTap: _shareToFriend,
                    ),
                  ],
                ),
              ),
              sizeHeight10,
              SizedBox(
                width: double.infinity,
                height: 85,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (c, i) => shareConfigs[i],
                    itemCount: shareConfigs.length,
                    separatorBuilder: (context, index) => sizeWidth16,
                  ),
                ),
              ),
              SizedBox(
                height: getBottomViewInset(),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildGroupsAvatar() {
    final tempList =
        docGroups.length >= 3 ? docGroups.getRange(0, 3) : docGroups;
    final List<Widget> widgets = [];
    tempList.forEach((group) {
      if (group.type == TcDocGroupType.user) {
        widgets.add(RealtimeAvatar(
          userId: group.targetId,
          size: 24,
        ));
      } else if (group.type == TcDocGroupType.role) {
        final role = PermissionModel.getPermission(widget.docInfo.guildId)
            ?.roles
            ?.firstWhere((r) => r.id == group.targetId, orElse: () => null);
        if (role != null)
          widgets.add(Container(
              constraints: BoxConstraints.tight(const Size(24, 24)),
              padding: const EdgeInsets.only(bottom: 1),
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: RoleIcon(
                role,
                size: 21,
              )));
      } else if (group.type == TcDocGroupType.channel) {
        widgets.add(_channelIcon());
      }
    });
    return StackPictures(
      totalNum: docGroups.length,
      maxDisplayNum: 3,
      children: widgets,
    );
  }

  Widget _channelIcon() {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        color: Color(0xFFe7f3fe),
        shape: BoxShape.circle,
      ),
      child: Icon(
        IconFont.buffWenzipindaotubiao,
        size: 20,
        color: Get.theme.primaryColor,
      ),
    );
  }

  Future<void> _shareToChannel() async {
    Get.back();
    Future<void> _popUp() {
      return showBottomModal(
        context,
        bottomInset: false,
        backgroundColor: appThemeData.scaffoldBackgroundColor,
        builder: (c, s) => ShareWidget(
          guildId: widget.docInfo.guildId,
          buttonText: '转发'.tr,
          onSend: (selectedChannels, guildTargetModel) async {
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
                tcController.sendContent(TextEntity.fromString(docUrl));
              }
            });
            if (wrongSet.isEmpty) {
              Toast.iconToast(icon: ToastIcon.success, label: "分享成功".tr);
            } else {
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
    }

    if (Get.isRegistered<TcDocPageController>()) {
      await Get.find<TcDocPageController>().unFocus(_popUp());
    } else {
      await _popUp();
    }
  }

  Future<void> _shareToFriend() async {
    if (FriendListPageController.to.list.isEmpty) {
      showToast('😑暂无好友，请选择其他方式分享'.tr);
    } else {
      Get.back();
      Future<void> _popUp() {
        return showShareFriendsPopUp(context, onConfirm: (users) async {
          for (final user in users) {
            unawaited(
              sendDirectMessage(
                user.user.userId,
                TextEntity.fromString(docUrl),
              ),
            );
          }
          Toast.iconToast(icon: ToastIcon.success, label: "分享成功".tr);
          Get.back();
        });
      }

      if (Get.isRegistered<TcDocPageController>()) {
        await Get.find<TcDocPageController>().unFocus(_popUp());
      } else {
        await _popUp();
      }
    }
  }

  Future<void> _toAddGroupPage() async {
    final res = await TcDocUtils.toAddGroupPage(
        widget.docInfo.guildId, widget.docInfo.fileId);
    if (res == true) Get.back();
  }

  Future<void> _toGroupsPage() async {
    final res = await TcDocUtils.toGroupsPage(
        widget.docInfo.guildId, widget.docInfo.fileId);
    if (res is List<TcDocGroup>) {
      setState(() {
        docGroups
          ..clear()
          ..addAll(res);
      });
    }
  }
}
