import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/show_dialog.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/button/back_button.dart';
import 'package:im/widgets/relay_message_popup.dart';

import '../../icon_font.dart';
import '../default_tip_widget.dart';

Future showShareDmListDialog(BuildContext context, {MessageEntity message}) {
  return showCustomDialog(
      context: context,
      builder: (context) {
        return DmlistDialog(
          message: message,
        );
      });
}

class DmlistDialog extends StatefulWidget {
  final MessageEntity message;

  const DmlistDialog({
    @required this.message,
  });
  @override
  _DmlistDialogState createState() => _DmlistDialogState();
}

class _DmlistDialogState extends State<DmlistDialog> {
  final List<UserInfo> _friends = [];

  @override
  void initState() {
    super.initState();

    /// copy from ShareDmListPopup
    () async {
      final channels = DirectMessageController.to.channels;
      for (final c in channels) {
        try {
          _friends.add(await UserInfo.get(c.guildId));
        } catch (e) {
          continue;
        }
      }
      if (mounted) setState(() {});
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          '发送给'.tr,
          style: Theme.of(context).textTheme.headline5,
        ),
        elevation: 0.5,
      ),
      body: Container(
          child: _friends.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  child: DefaultTipWidget(
                    icon: IconFont.buffChatMessage,
                    iconSize: 34,
                    text: '暂无私信成员'.tr,
                  ),
                )
              : _listView()),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final UserInfo user = _friends[index];
    return Stack(
      children: [
        Container(
          height: 60,
          alignment: Alignment.center,
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Avatar(
                  radius: 18,
                  url: user.avatar,
                ),
              ],
            ),
            title: Text(
              user.nickname,
              style: Theme.of(context).textTheme.bodyText2,
            ),
            onTap: () {
              showRelayMessagePopup(context,
                  user: user, message: widget.message);
            },
          ),
        ),
        const Positioned(
          bottom: 0,
          left: 64,
          right: 0,
          child: divider,
        ),
      ],
    );
  }

  Widget _listView() {
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Container(
            height: 43,
            padding: const EdgeInsets.fromLTRB(16, 20, 0, 0),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Text(
              '最近私信成员'.tr,
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  .copyWith(height: 1, fontSize: 13),
            ),
          ),
        ),
        // 当列表项高度固定时，使用 SliverFixedExtendList 比 SliverList 具有更高的性能
        SliverFixedExtentList(
            delegate: SliverChildBuilderDelegate(_buildItem,
                childCount: _friends.length),
            itemExtent: 60),
        SliverToBoxAdapter(
          child: SizedBox(
            height: getBottomViewInset(),
          ),
        ),
      ],
    );
  }
}
