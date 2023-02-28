import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/user_api.dart';
import 'package:im/app/modules/friend_list_page/controllers/friend_list_page_controller.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/web/widgets/app_bar/web_appbar.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/default_tip_widget.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:oktoast/oktoast.dart';

import '../../icon_font.dart';

class ShieldSetPage extends StatefulWidget {
  @override
  _ShieldSetPageState createState() => _ShieldSetPageState();
}

class _ShieldSetPageState extends State<ShieldSetPage> {
  final List<Map<String, dynamic>> _allBlackList = [];
  List<UserInfo> _blackUserList;
  final List<UserInfo> _removedBlackList = [];

  @override
  void initState() {
    super.initState();
    _allBlackList.clear();
    _allBlackList.addAll(FriendListPageController.to.blackList);
    final List<String> ids = [];
    _allBlackList.forEach((element) {
      ids.add(element['black_id']);
    });
    UserApi.getUserInfo(ids).then((value) {
      _blackUserList = [...value];
      sortBlackList();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: OrientationUtil.portrait
            ? CustomAppbar(
                title: '已屏蔽的用户'.tr,
              )
            : WebAppBar(
                title: '已屏蔽的用户'.tr,
                height: 68,
              ),
        backgroundColor: Theme.of(context).backgroundColor,
        body: _blackUserList == null
            ? const Center(child: CircularProgressIndicator())
            : (_blackUserList.isNotEmpty
                ? Column(
                    children: <Widget>[
                      sizeHeight10,
                      Expanded(
                          child: ListView.builder(
                              itemCount: _blackUserList.length + 1,
                              itemBuilder: (context, i) {
                                if (i < _blackUserList.length) {
                                  return _buildTile(_blackUserList[i]);
                                } else {
                                  return Center(
                                    heightFactor: 2,
                                    child: Text('暂时没有更多了.'.tr),
                                  );
                                }
                              }))
                    ],
                  )
                : Center(
                    child: GestureDetector(
                      onTap: () async {
                        await FriendListPageController.to.fetchBlackList();
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          sizeHeight16,
                          DefaultTipWidget(
                            icon: IconFont.buffNaviFriends,
                            text: '空空如也'.tr,
                          )
                        ],
                      ),
                    ),
                  )));
  }

  Widget _buildTile(UserInfo userInfo) {
    final theme = Theme.of(context);
    return Container(
        padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
        color: theme.backgroundColor,
        child: ListTile(
          dense: true,
          leading: RealtimeAvatar(
            userId: userInfo.userId,
            size: 48,
          ),
          title: Text(
            userInfo.nickname ?? '',
            style: theme.textTheme.bodyText2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: MaterialButton(
              color: theme.primaryColor,
              textColor: Colors.white,
              onPressed: () {
                if (blackListContain(_removedBlackList, userInfo.userId)) {
                  if (FriendListPageController.to
                      .blackListIsContain(userInfo.userId)) {
                    showToast("已被屏蔽".tr);
                    if (blackListContain(_removedBlackList, userInfo.userId)) {
                      _removedBlackList.remove(userInfo);
                      setState(() {});
                    }
                  } else {
                    FriendListPageController.to
                        .addBlackId(userInfo.userId)
                        .then((value) {
                      showToast("已被你屏蔽".tr);
                      if (blackListContain(
                          _removedBlackList, userInfo.userId)) {
                        _removedBlackList.remove(userInfo);
                        setState(() {});
                      }
                    });
                  }
                } else {
                  if (FriendListPageController.to
                      .blackListIsContain(userInfo.userId)) {
                    FriendListPageController.to
                        .removeFromBlackList(userInfo.userId)
                        .then((value) {
                      showToast("已解除屏蔽".tr);
                      if (!blackListContain(
                          _removedBlackList, userInfo.userId)) {
                        _removedBlackList.add(userInfo);
                        setState(() {});
                      }
                    });
                  } else {
                    showToast("已被解除屏蔽".tr);
                    if (!blackListContain(_removedBlackList, userInfo.userId)) {
                      _removedBlackList.add(userInfo);
                      setState(() {});
                    }
                  }
                }
              },
              child: blackListContain(_removedBlackList, userInfo.userId)
                  ? Text('已解除'.tr)
                  : Text('解除屏蔽'.tr)),
        ));
  }

  void sortBlackList() {
    _allBlackList.sort((obj1, obj2) {
      final c1 = obj1['created_at'].toString();
      final c2 = obj2['created_at'].toString();
      return c2.compareTo(c1);
    });
    final List<UserInfo> sortBlackUserInfo = [];
    _allBlackList.forEach((blackMapInfo) {
      sortBlackUserInfo.add(_blackUserList.firstWhere(
          (blackUserInfo) => blackUserInfo.userId == blackMapInfo['black_id']));
    });
    _blackUserList.clear();
    _blackUserList.addAll(sortBlackUserInfo);
  }

  bool blackListContain(List<UserInfo> findList, String userId) {
    return findList.firstWhere((element) => element.userId == userId,
            orElse: () => null) !=
        null;
  }
}
