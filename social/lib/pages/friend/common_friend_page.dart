import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/relation_api.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/global.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/refresh/net_checker.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';

class CommonFriendPage extends StatefulWidget {
  final String relationId;
  final bool hideGuildName;
  final String guildId;

  const CommonFriendPage(this.relationId,
      {this.hideGuildName = false, this.guildId});

  @override
  _CommonFriendPageState createState() => _CommonFriendPageState();
}

class _CommonFriendPageState extends State<CommonFriendPage> {
//  Future _future;
  final ValueNotifier<int> _amount = ValueNotifier(0);

  @override
  void initState() {
    _resetFuture();
    super.initState();
  }

  Future _resetFuture() async {
    final res =
        await RelationApi.getRelation(Global.user.id, widget.relationId);
    final List<String> _userList =
        (res['relations'] as List).map((v) => v['user_id'].toString()).toList();
    _amount.value = _userList.length;
    return _userList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrientationUtil.landscape
          ? Theme.of(context).backgroundColor
          : Theme.of(context).scaffoldBackgroundColor,
      appBar: OrientationUtil.portrait
          ? CustomAppbar(
              titleBuilder: (style) {
                return ValueListenableBuilder<int>(
                    valueListenable: _amount,
                    builder: (context, amount, _) {
                      return Text(
                        '%s个共同好友'.trArgs([amount.toString()]),
                        style: style,
                      );
                    });
              },
            )
          : null,
      body: NetChecker(
        futureGenerator: _resetFuture,
        retry: () {
          setState(() => {});
        },
        builder: (list) {
          return Builder(
            builder: (context) {
              if (list.isEmpty) return Center(child: Text('暂时没有共同好友哦 '.tr));
              return ListView.builder(
                padding:
                    EdgeInsets.only(top: OrientationUtil.landscape ? 12 : 0),
                itemBuilder: (context, index) {
                  return _item(list[index]);
                },
                itemCount: list.length,
              );
            },
          );
        },
      ),
    );
  }

  FadeBackgroundButton _item(String userId) {
    return FadeBackgroundButton(
      backgroundColor: Theme.of(context).backgroundColor,
      tapDownBackgroundColor:
          Theme.of(context).backgroundColor.withOpacity(0.5),
      onTap: () {
        showUserInfoPopUp(context,
            userId: userId,
            guildId: widget.guildId,
            hideGuildName: widget.hideGuildName);
      },
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
                vertical: 10, horizontal: OrientationUtil.portrait ? 16 : 24),
            child: UserInfo.consume(userId, builder: (context, user, _) {
              return Row(
                children: <Widget>[
                  RealtimeAvatar(
                    userId: user.userId,
                    size: OrientationUtil.landscape ? 40 : 24,
                  ),
                  sizeWidth16,
                  Expanded(
                      child: RealtimeNickname(
                    userId: userId,
                    guildId: widget.guildId,
                  ))
                ],
              );
            }),
          ),
          if (OrientationUtil.landscape)
            const Positioned(
              bottom: 0,
              right: 0,
              left: 24,
              child: divider,
            )
        ],
      ),
    );
  }
}
