import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/db/db.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/components/bottom_right_button/top_right_button_controller.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/bottom_bar/im_bottom_bar.dart';
import 'package:im/pages/home/view/dock.dart';
import 'package:im/pages/home/view/model/home_page_model.dart';
import 'package:im/pages/home/view/record_view/record_sound_state.dart';
import 'package:im/pages/home/view/text_chat/show_message_tooltip.dart';
import 'package:im/pages/home/view/text_chat_view.dart';
import 'package:im/routes.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/user_info/realtime_nick_name.dart';
import 'package:provider/provider.dart';

class DirectChatPage extends StatefulWidget {
  final ChatChannel channel;

  const DirectChatPage({Key key, this.channel}) : super(key: key);

  @override
  _DirectChatPageState createState() => _DirectChatPageState();
}

class _DirectChatPageState extends State<DirectChatPage> {
  @override
  void initState() {
    TextChannelController.to(channelId: widget.channel.id).joinChannel();
    TextChannelController.dmChannel?.id = widget.channel.id;
    TopRightButtonController.to(widget.channel.id).updateNumUnread();
    super.initState();
    Future.delayed(const Duration(milliseconds: 500)).then((value) {
      Dock.updateDock();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: WillPopScope(
        onWillPop: () {
          closeToolTip();
          return Future.value(true);
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Theme.of(context).backgroundColor,
          appBar: FbAppBar.diyTitleView(
            //  - 横屏不展示返回按钮
            hideLeading: !OrientationUtil.portrait,
            leadingShowMsgNum: GlobalState.totalRedDotNum,
            titleBuilder: (context, style) {
              return RealtimeNickname(
                userId: widget.channel.recipientId ?? widget.channel.guildId,
                showNameRule: ShowNameRule.remark,
                style: style,
              );
            },
            actions: [
              AppBarIconActionModel(
                IconFont.buffChatPin,
                unreadMsgNumListenable: Db.pinMessageUnreadBox
                    .listenable(keys: [widget.channel.id]),
                selector: (box) {
                  final unread = box.get(widget.channel.id) ?? [];
                  return unread.length;
                },
                actionBlock: () =>
                    Routes.pushPinListPage(context, channel: widget.channel),
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
      ),
    );
  }
}
