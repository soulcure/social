import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/invite_api.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/guild_setting/member/model/invite_manage_model.dart';
import 'package:im/pages/guild_setting/member/widgets/invite_code_friend_popup.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/web/pages/setting/widgets/dialog/edit_link_remark_dialog.dart';
import 'package:im/web/pages/setting/widgets/intvite_code_item.dart';
import 'package:im/web/utils/confirm_dialog/message_box.dart';
import 'package:im/web/widgets/popup/web_popup.dart';
import 'package:im/web/widgets/slider_sheet/show_slider_sheet.dart';
import 'package:im/widgets/refresh/refresh.dart';
import 'package:oktoast/oktoast.dart';

import '../../../global.dart';

class InviteLinkPage extends StatefulWidget {
  final String guildId;

  const InviteLinkPage({
    @required this.guildId,
  });

  @override
  _InviteLinkPageState createState() => _InviteLinkPageState();
}

class _InviteLinkPageState extends State<InviteLinkPage> {
  InviteManageModel _model;
  GuildTarget _guild;
  String _copyPrefix;
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _model = InviteManageModel(guildId: widget.guildId);
  }

  Widget _buildHeaderItem(
    String title,
    double width, {
    bool alignmentRight = false,
  }) {
    return Container(
      width: width,
      alignment: alignmentRight ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.of(context).size.height - 220).ceil().toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          width: 654,
          decoration: BoxDecoration(
              border: Border(
                  bottom:
                      BorderSide(color: Theme.of(context).dividerTheme.color))),
          child: Row(
            children: [
              _buildHeaderItem('?????????'.tr, 206),
              _buildHeaderItem('?????????'.tr, 94),
              _buildHeaderItem('??????????????????'.tr, 76, alignmentRight: true),
              _buildHeaderItem('????????????'.tr, 80, alignmentRight: true),
              _buildHeaderItem('????????????'.tr, 80, alignmentRight: true),
              _buildHeaderItem('??????'.tr, 116, alignmentRight: true),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(-16, 0),
          child: SizedBox(
            height: height,
            child: Refresher(
              model: _model,
              enableRefresh: false,
              scrollController: _controller,
              builder: (context) {
                return ListView.builder(
                    controller: _controller,
                    shrinkWrap: true,
                    itemCount: _model.list.length,
                    itemBuilder: (context, index) {
                      return Builder(builder: (context) {
                        return InviteCodeItemWeb(
                            model: _model.list[index],
                            moreCallback: (context) async {
                              final int result = await showWebSelectionPopup(
                                context,
                                items: ['??????'.tr, '????????????'.tr, '????????????'.tr],
                                offsetY: 10,
                              );
                              switch (result) {
                                case 0:
                                  await _onUndoLink(index);
                                  break;
                                case 1:
                                  _onCopyLink(index);
                                  break;
                                case 2:
                                  _onRemarkLink(index);
                              }
                            },
                            inviterInfoCallback: (_) {},
                            detailCallback: () {
                              String inviterName =
                                  _model.list[index].inviterName ?? '';
                              inviterName = inviterName.takeCharacter(8);
                              showSliderModal(
                                context,
                                body: InviteCodeFriendPopup(
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
                    });
              },
            ),
          ),
        ),
      ],
    );
  }

  /// ????????????
  Future<void> _onUndoLink(int index) async {
    final res = await showWebMessageBox(
        title: '???????????????????????????????????????'.tr, confirmText: '??????'.tr);
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

  /// ??????????????????
  void _onRemarkLink(int index) {
    final record = _model.list[index];
    showEditLinkRemarkDialog(
      context,
      initContent: record.remark,
      saveCallback: (content) async {
        if (content == record.remark) return;
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
            showToast('?????????????????????????????????'.tr);
          }
        }
      },
    );
  }

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
    return _copyPrefix ??= "????????????${guild.name}???????????????????????????????????????????????? ~ ???????????????";
  }

  /// ????????????
  void _onCopyLink(int index) {
    final record = _model.list[index];
    if (record.url == null || record.url.isEmpty) {
      debugPrint('invite url is empty!!!');
      return;
    }
    final content = "$copyPrefix${record.url}";
    final ClipboardData data = ClipboardData(text: content);
    Clipboard.setData(data);
    showToast('????????????'.tr);
  }
}
