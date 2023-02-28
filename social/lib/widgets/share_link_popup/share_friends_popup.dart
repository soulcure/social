import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/friend_list_page/controllers/friend_list_page_controller.dart';
import 'package:im/global.dart';
import 'package:im/pages/friend/widgets/custom_index_bar.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/button/primary_button.dart';
import 'package:oktoast/oktoast.dart';

import '../realtime_user_info.dart';

typedef OnConfirm = void Function(List<UserInfoBean> userBeans);

Future showShareFriendsPopUp(BuildContext context, {OnConfirm onConfirm}) {
  return showBottomModal(
    context,
    builder: (c, s) => ShareFriendsPopup(onConfirm),
    backgroundColor: CustomColor(context).backgroundColor6,
  );
}

class ShareFriendsPopup extends StatefulWidget {
  final OnConfirm onConfirm;

  const ShareFriendsPopup(this.onConfirm);

  @override
  _ShareFriendsPopupState createState() => _ShareFriendsPopupState();
}

class _ShareFriendsPopupState extends State<ShareFriendsPopup> {
  final Color specColor = const Color(0xff737780).withOpacity(0.2);
  List<UserInfoBean> _friends = [];
  final List<UserInfoBean> _selectList = [];
  final int _suspensionHeight = 40;
  final int _itemHeight = 60;
  ThemeData _theme;

  @override
  void initState() {
    super.initState();
    _friends = FriendListPageController.to.friendList;
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    final TextStyle ts12 = copyWithFs12(_theme.textTheme.bodyText1);
    return SizedBox(
      height: Global.mediaInfo.size.height * 0.8,
      child: Column(
        children: <Widget>[
          _buildSelectList(ts12),
          _buildPickList(),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            height: 48,
            child: PrimaryButton(
              enabled: _selectList.isNotEmpty,
              onPressed: () {
                widget.onConfirm(_selectList);
              },
              label: '确定'.tr,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectList(TextStyle ts12) {
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
                  'Fanbook好友'.tr,
                  style: ts12,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 70,
                child: _selectList.isEmpty
                    ? Center(
                        child: Text(
                        _friends.isNotEmpty
                            ? "未选择好友".tr
                            : "暂无好友，赶紧去添加Fanbook好友吧。".tr,
                        style:
                            TextStyle(color: Theme.of(context).disabledColor),
                      ))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final user = _selectList[index].user;
                          return Column(
                            children: <Widget>[
                              RealtimeAvatar(
                                userId: user.userId,
                                size: 48,
                              ),
                              Expanded(
                                child: Container(
                                  alignment: Alignment.bottomCenter,
                                  width: 48,
                                  child: RealtimeNickname(
                                    userId: user.userId,
                                    showNameRule: ShowNameRule.remarkAndGuild,
                                    style: ts12,
                                  ),
                                ),
                              )
                            ],
                          );
                        },
                        separatorBuilder: (context, index) => sizeWidth16,
                        itemCount: _selectList.length,
                      ),
              ),
            ],
          ),
        ),
        divider,
      ],
    );
  }

  Widget _buildPickList() {
    return Expanded(
      child: AzListView(
        data: _friends,
        itemBuilder: (context, model) => _buildPickItem(model),
        itemHeight: _itemHeight,
        suspensionHeight: _suspensionHeight,
        indexBarBuilder: (context, tags, onTouch) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 0, 8),
            child: CustomIndexBar(
              touchDownColor: Colors.transparent,
              data: tags,
              width: 38,
              itemHeight: 22,
              textStyle:
                  Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 12),
              touchDownTextStyle:
                  Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 12),
              onTouch: (details) {
                onTouch(details);
              },
            ),
          );
        },
        indexHintBuilder: (context, hint) {
          return Card(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: Container(
              alignment: Alignment.center,
              width: 60,
              height: 60,
              child: Text(
                hint,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPickItem(UserInfoBean bean) {
    // String susTag = model.getSuspensionTag();
    return Column(
      children: <Widget>[
        // Offstage(
        //   offstage: model.isShowSuspension != true,
        //   child: _buildSusWidget(susTag),
        // ),
        SizedBox(
          height: _itemHeight.toDouble(),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (_selectList.contains(bean))
                  Icon(Icons.check_circle,
                      color: Theme.of(context).primaryColor)
                else
                  const Icon(Icons.panorama_fish_eye),
                sizeWidth15,
                RealtimeAvatar(
                  userId: bean.user.userId,
                  size: 32,
                ),
              ],
            ),
            title: Padding(
              padding: const EdgeInsets.only(right: 30),
              child: RealtimeNickname(
                userId: bean.user.userId,
                style: Theme.of(context).textTheme.bodyText2,
                showNameRule: ShowNameRule.remarkAndGuild,
              ),
            ),
            onTap: () {
              setState(() {
                if (_selectList.contains(bean)) {
                  _selectList.remove(bean);
                } else {
                  if (_selectList.length >= 10) {
                    showToast("1次最多选择10个".tr);
                  } else {
                    _selectList.add(bean);
                  }
                }
              });
            },
          ),
        ),
        // divider,
      ],
    );
  }
}
