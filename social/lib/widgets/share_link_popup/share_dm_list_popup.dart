import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/global.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/button/primary_button.dart';
import 'package:oktoast/oktoast.dart';

import '../realtime_user_info.dart';

Future showShareDmListPopUp(
  BuildContext context,
) {
  return showBottomModal(
    context,
    builder: (c, s) => const ShareDmListPopup(),
    backgroundColor: CustomColor(context).backgroundColor6,
  );
}

class ShareDmListPopup extends StatefulWidget {
  const ShareDmListPopup();

  @override
  _ShareDmListPopupState createState() => _ShareDmListPopupState();
}

class _ShareDmListPopupState extends State<ShareDmListPopup> {
  final RxList<UserInfo> selectList = RxList<UserInfo>([]);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    selectList.close();
  }

  Future<List<UserInfo>> getUserList() async {
    final completer = Completer<List<UserInfo>>();

    final List<UserInfo> friends = [];
    final channels = DirectMessageController.to.channels;

    for (int i = 0; i < channels.length; i++) {
      final String userId = channels[i].recipientId ?? channels[i].guildId;
      final UserInfo user = await UserInfo.get(userId);
      if (user != null) friends.add(user);
      if (i == channels.length - 1) {
        completer.complete(friends);
      }
    }

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getUserList(),
        initialData: const <UserInfo>[],
        builder: (context, snapshot) {
          return buildSizedBox(snapshot.data ?? []);
        });
  }

  SizedBox buildSizedBox(List<UserInfo> friends) {
    return SizedBox(
      height: Global.mediaInfo.size.height * 0.8,
      child: Column(
        children: <Widget>[
          _buildSelectList(friends),
          PickListWidget(friends, selectList),
          _buildConfirm(),
        ],
      ),
    );
  }

  Widget _buildSelectList(List<UserInfo> friends) {
    final TextStyle ts12 = copyWithFs12(Theme.of(context).textTheme.bodyText1);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  '最近聊天'.tr,
                  style: ts12,
                ),
              ),
              buildBody(friends),
            ],
          ),
        ),
        divider,
      ],
    );
  }

  Widget buildBody(List<UserInfo> friends) {
    return Obx(() {
      return SizedBox(
        width: double.infinity,
        height: 72,
        child:
            selectList.isEmpty ? buildTitleWidget(friends) : buildListWidget(),
      );
    });
  }

  Widget buildTitleWidget(List<UserInfo> friends) {
    return Center(
        child: Text(
      friends.isNotEmpty ? "未选择联系人".tr : "暂无最近聊天联系人，赶紧去聊天吧。".tr,
      style: TextStyle(color: Theme.of(context).disabledColor),
    ));
  }

  Widget buildListWidget() {
    final TextStyle ts12 = copyWithFs12(Theme.of(context).textTheme.bodyText1);
    return Obx(() {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final user = selectList[index];
          return Column(
            children: <Widget>[
              Avatar(url: user.avatar, radius: 24),
              sizeHeight5,
              SizedBox(
                width: 48,
                child: Center(
                  child: RealtimeNickname(
                    userId: user.userId,
                    style: ts12,
                    showNameRule: ShowNameRule.remarkAndGuild,
                  ),
                ),
              )
            ],
          );
        },
        separatorBuilder: (context, index) => sizeWidth16,
        itemCount: selectList.length,
      );
    });
  }

  Widget _buildConfirm() {
    return Obx(() {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        height: 48,
        child: PrimaryButton(
          enabled: selectList.isNotEmpty,
          onPressed: _onConfirm,
          label: '确定'.tr,
        ),
      );
    });
  }

  Future _onConfirm() async {
    final res = await showConfirmDialog(
      title: '提示'.tr,
      content: '确认分享链接 ？'.tr,
    );
    if (res) {
      Navigator.of(context).pop(selectList.toList());
      showToast('邀请链接已发送'.tr);
    }
  }
}

class PickListWidget extends StatefulWidget {
  final List<UserInfo> friends;
  final RxList<UserInfo> selectList;

  const PickListWidget(this.friends, this.selectList, {Key key})
      : super(key: key);

  @override
  State<PickListWidget> createState() => _PickListWidgetState();
}

class _PickListWidgetState extends State<PickListWidget> {
  final int _itemHeight = 60;

  List<UserInfo> get selectList => widget.selectList;

  @override
  Widget build(BuildContext context) {
    return _buildPickList(widget.friends);
  }

  Widget _buildPickList(List<UserInfo> friends) {
    return Expanded(
        child: friends.isEmpty
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView.builder(
                itemBuilder: (context, index) {
                  final UserInfo user = friends[index];
                  return SizedBox(
                    height: _itemHeight.toDouble(),
                    child: ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (selectList.contains(user))
                            Icon(Icons.check_circle,
                                color: Theme.of(context).primaryColor)
                          else
                            const Icon(Icons.panorama_fish_eye),
                          sizeWidth15,
                          Avatar(
                            radius: 16,
                            url: user.avatar,
                          ),
                        ],
                      ),
                      title: RealtimeNickname(
                        userId: user.userId,
                        showNameRule: ShowNameRule.remarkAndGuild,
                      ),
                      onTap: () {
                        setState(() {
                          if (selectList.contains(user)) {
                            selectList.remove(user);
                          } else {
                            if (selectList.length >= 10) {
                              showToast("1次最多选择10个".tr);
                            } else {
                              selectList.add(user);
                            }
                          }
                        });
                      },
                    ),
                  );
                },
                itemCount: friends.length,
              ));
  }
}
