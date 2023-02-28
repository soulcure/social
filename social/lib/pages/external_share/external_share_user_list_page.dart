import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/pages/search/model/search_model.dart';
import 'package:im/pages/search/widgets/search_input_box.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/realtime_user_info.dart';

import '../../global.dart';
import 'external_share_model.dart';
import 'external_share_send_dialog.dart';

class ExternalShareUserListPage extends StatefulWidget {
  final ExternalShareModel model;
  final String fromType;

  const ExternalShareUserListPage(this.model, this.fromType, {Key key})
      : super(key: key);

  @override
  _ExternalShareUserListPageState createState() =>
      _ExternalShareUserListPageState();
}

class _ExternalShareUserListPageState extends State<ExternalShareUserListPage> {
  SearchInputModel _searchInputModel;
  TextEditingController _searchInputController;
  String searchKey;

  Widget _buildUser(String userId, {VoidCallback onTap}) {
    return UserInfo.consume(userId, builder: (context, u, widget) {
      return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 64,
            child: Row(
              children: [
                RealtimeAvatar(
                  userId: u.userId,
                  size: 40,
                ),
                sizeWidth12,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      u.nickname,
                      style: const TextStyle(
                          fontSize: 16,
                          height: 20.0 / 16.0,
                          color: Color(0xFF363940)),
                    ),
                    Text("#${u.username}",
                        style: const TextStyle(
                            fontSize: 13,
                            height: 16.0 / 13.0,
                            color: Color(0xFF8F959E)))
                  ],
                )
              ],
            ),
          ));
    });
  }

  Widget _buildSearchBox() {
    return Container(
      color: Colors.white,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SearchInputBox(
        searchInputModel: _searchInputModel,
        inputController: _searchInputController,
        borderRadius: 18,
        autoFocus: false,
        height: 36,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    _searchInputModel = SearchInputModel();
    _searchInputController = TextEditingController();
  }

  Widget _buildSearchList() {
    return StreamBuilder(
      stream: _searchInputModel.searchStream,
      builder: (context, snapshot) {
        searchKey = snapshot.data;
        return _contentList(searchKey);
      },
    );
  }

  // List<UserInfo> _userItems() {
  //   if (widget.fromType == "recents") {
  //     if (searchKey == null || searchKey.isEmpty) {
  //       return widget.model.recentList();
  //     } else {
  //       return widget.model.searchMembers(searchKey, source: "recents");
  //     }
  //   } else if (widget.fromType == "friends") {
  //     if (searchKey == null || searchKey.isEmpty) {
  //       return widget.model.friendList();
  //     } else {
  //       return widget.model.searchMembers(searchKey, source: "friends");
  //     }
  //   } else {
  //     return <UserInfo>[];
  //   }
  // }

  Future<List<String>> _userItemsIds() async {
    if (widget.fromType == "recents") {
      if (searchKey == null || searchKey.isEmpty) {
        return widget.model.recentUserListIds();
      } else {
        return widget.model.searchMembers(searchKey, source: "recents");
      }
    } else if (widget.fromType == "friends") {
      if (searchKey == null || searchKey.isEmpty) {
        return widget.model.friendListIds();
      } else {
        return widget.model.searchMembers(searchKey, source: "friends");
      }
    } else {
      return <String>[];
    }
  }

  Widget _contentList(String searchKey) {
    return FutureBuilder(
        future: _userItemsIds(),
        builder: (cxt, snap) {
          final List<String> items = snap.data;
          if (items == null) return const SizedBox();
          return ListView.separated(
              separatorBuilder: (context, index) => Divider(
                  indent: 48,
                  height: 0.5,
                  color: const Color(0xFF8F959E).withOpacity(0.2)),
              itemCount: items.length,
              itemBuilder: (ctx, index) {
                final userId = items.elementAt(index);
                return _buildUser(userId, onTap: () async {
                  await widget.model.selectUser(userId);
                  final currContext = Global.navigatorKey.currentContext;
                  await showDialog(
                      context: currContext,
                      builder: (cxt) {
                        return ExternalShareSendDialog(
                          widget.model,
                          onConfirm: () {
                            Navigator.pop(cxt, true);
                            widget.model.share();
                          },
                          onCancel: () {
                            Navigator.pop(cxt, true);
                          },
                        );
                      },
                      barrierDismissible: false);
                });
              });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppbar(
        title: '选择用户'.tr,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBox(),
            Expanded(child: _buildSearchList()),
          ],
        ),
      ),
    );
  }
}
