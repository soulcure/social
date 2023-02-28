import 'package:flutter/material.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/member_list/member_list_window.dart';

import '../inner_drawer.dart';
import 'group_chat_view.dart';

///暂未使用
class GroupChatPage extends StatelessWidget {
  final ChatChannel channel;

  GroupChatPage(this.channel, {Key key}) : super(key: key) {
    GlobalState.selectedChannel.value = channel;
  }

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey();
    return Scaffold(
      body: SafeArea(
        child: InnerDrawer(
          key: key,
          scaffold: GroupChatView(channel),
          rightChild: const MemberListWindow(),
        ),
      ),
    );
  }
}
