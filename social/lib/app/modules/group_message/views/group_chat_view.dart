import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/group_message/views/group_member_list.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/components/bottom_right_button/top_right_button_controller.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/bottom_bar/im_bottom_bar.dart';
import 'package:im/pages/home/view/model/home_page_model.dart';
import 'package:im/pages/home/view/record_view/record_sound_state.dart';
import 'package:im/pages/home/view/text_chat_view.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:provider/provider.dart';

class GroupChatView extends StatefulWidget {
  final ChatChannel channel;

  const GroupChatView(this.channel);

  @override
  _GroupChatViewState createState() => _GroupChatViewState();
}

class _GroupChatViewState extends State<GroupChatView> {
  @override
  void initState() {
    TextChannelController.to(channelId: widget.channel.id).joinChannel();
    TextChannelController.dmChannel?.id = widget.channel.id;
    TopRightButtonController.to(widget.channel.id).updateNumUnread();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return ClipRRect(
      borderRadius: orientation == Orientation.portrait
          ? const BorderRadius.vertical(top: Radius.circular(8))
          : const BorderRadius.vertical(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: FbAppBar.diyTitleView(
          //  - 横屏不展示返回按钮
          hideLeading: !OrientationUtil.portrait,
          leadingShowMsgNum: GlobalState.totalRedDotNum,
          titleBuilder: (context, style) {
            return RealtimeChannelName(
              widget.channel.id,
              style: style,
            );
          },
          actions: [
            AppBarIconActionModel(
              IconFont.buffFriendList,
              actionBlock: () {
                final channel = widget.channel;
                Get.to(() => GroupMemberList(channel: channel),
                    transition: Transition.rightToLeft);
              },
            ),
          ],
        ),
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => RecordSoundState()),
            ChangeNotifierProvider(create: (_) => HomePageModel()),
          ],
          child: TextChatView(
            model: TextChannelController.to(channelId: widget.channel.id),
            bottomBar: ImBottomBar(widget.channel),
          ),
        ),
      ),
    );
  }
}
