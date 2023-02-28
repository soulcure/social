import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/invite_api.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/global.dart';
import 'package:im/pages/guild_setting/member/widgets/invite_code_friend_popup.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/routes.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/show_confirm_popup.dart';
import 'package:im/utils/show_manager_invite_link_popup.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/refresh/refresh.dart';
import 'package:im/widgets/share_link_popup/setting/share_link_setting_remark.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';
import 'package:oktoast/oktoast.dart';

import 'model/invite_manage_model.dart';
import 'widgets/intvite_code_item.dart';

class MemberManagerInvitePage extends StatefulWidget {
  final String guildId;

  const MemberManagerInvitePage({
    @required this.guildId,
  });

  @override
  _MemberManagerInvitePageState createState() =>
      _MemberManagerInvitePageState();
}

class _MemberManagerInvitePageState extends State<MemberManagerInvitePage> {
  InviteManageModel _model;

  GuildTarget _guild;
  String _copyPrefix;

  GuildTarget get guild {
    if (_guild != null) return _guild;
    if (widget.guildId != null) {
      _guild = ChatTargetsModel.instance.getGuild(widget.guildId);
    } else {
      _guild = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    }
    return _guild;
  }

  String get copyPrefix {
    return _copyPrefix ??= "我正在「${guild.name}」服务器中聊天，来和我一起畅聊吧 ~ 点击加入：";
  }

  /// 复制链接选项
  void _onCopyLink(int index) {
    final record = _model.list[index];
    if (record.url == null || record.url.isEmpty) {
      debugPrint('invite url is empty!!!');
      return;
    }
    final content = "$copyPrefix${record.url}";
    final ClipboardData data = ClipboardData(text: content);
    Clipboard.setData(data);
    showToast('复制成功'.tr);
  }

  /// 设置备注选项
  void _onRemarkLink(int index) {
    final record = _model.list[index];
    showSettingRemarkPopup(
      context,
      initContent: record.remark,
      saveAction: (content) async {
        if (content == record.remark) {
          Navigator.of(context)
              .popUntil(ModalRoute.withName(memberManageInviteRoute));
          return;
        }
        try {
          final Map params = {
            'channel_id': record.channelId,
            'guild_id': ChatTargetsModel.instance.selectedChatTarget.id,
            'user_id': Global.user.id,
            'v': DateTime.now().millisecondsSinceEpoch.toString(),
            'number': int.parse(record.number),
            'time': int.parse(record.time),
            'remark': content,
            'type': 1,
            'member_id': record.inviterId,
          };
          final inviteUrl = await InviteApi.getInviteInfo(params);
          if (inviteUrl != null && inviteUrl.remark == content) {
            setState(() => record.remark = content);
          }
        } catch (e) {
          if (e is FormatException) {
            debugPrint(e?.toString());
          } else {
            showToast('网络异常，请检查后重试'.tr);
          }
        } finally {
          Navigator.of(context)
              .popUntil(ModalRoute.withName(memberManageInviteRoute));
        }
      },
    );
  }

  /// 撤销链接选项
  Future<void> _onUndoLink(int index) async {
    final res = await showConfirmPopup(
      title: '撤销后该邀请链接将永久失效'.tr,
      confirmText: '撤销'.tr,
      confirmStyle: Theme.of(context)
          .textTheme
          .bodyText2
          .copyWith(fontSize: 17, color: DefaultTheme.dangerColor),
    );
    if (res == true) {
      final code = _model.list[index].code;
      if (code != null && code.isNotEmpty) {
        await InviteApi.giveUpCode(code);
        _model.updateItem(
            _model.list[index].copyWith(expireTime: '0', numberLess: '0'),
            index);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _model = InviteManageModel(guildId: widget.guildId);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppbar(
          title: '管理邀请链接'.tr,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: Refresher(
          model: _model,
          enableRefresh: false,
          builder: (context) {
            return ListView.builder(
                itemCount: _model.list.length,
                itemBuilder: (context, index) {
                  return InviteCodeItem(
                      model: _model.list[index],
                      moreCallback: () async {
                        await showManagerInviteLinkPopup(
                          context,
                          onCopyLink: () => _onCopyLink(index),
                          onRemarkLink: () => _onRemarkLink(index),
                          onUndoLink: () => _onUndoLink(index),
                        );
                      },
                      inviterInfoCallback: () {
                        final inviterId = _model.list[index].inviterId ?? '';
                        if (inviterId.isNotEmpty)
                          showUserInfoPopUp(
                            context,
                            userId: inviterId,
                            guildId:
                                ChatTargetsModel.instance.selectedChatTarget.id,
                            showRemoveFromGuild: true,
                            enterType: EnterType.fromServer,
                          );
                      },
                      detailCallback: () {
                        String inviterName =
                            _model.list[index].inviterName ?? '';
                        inviterName = inviterName.takeCharacter(8);
                        showBottomModal(
                          context,
                          builder: (c, s) => InviteCodeFriendPopup(
                            inviterName: inviterName,
                            hasInvited: _model.list[index].hasInvited,
                            code: _model.list[index].code,
                            totalUpdate: (hasInvited) {
                              _model.updateItem(
                                  _model.list[index]
                                      .copyWith(hasInvited: hasInvited),
                                  index);
                            },
                          ),
                        );
                      });
                });
          },
        ));
  }
}
