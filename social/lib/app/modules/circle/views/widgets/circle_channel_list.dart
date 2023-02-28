import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/channel_icon.dart';

import '../../../../../../icon_font.dart';

Future showCircleChannelListDialog(
    BuildContext context, List<CircleTopicDataModel> topicList) {
  return Get.to(
      CircleChannelListPage(
        topicList: topicList,
      ),
      transition: Transition.downToUp);
}

class CircleChannelListPage extends StatefulWidget {
  final List<CircleTopicDataModel> topicList;

  const CircleChannelListPage({
    this.topicList = const [],
  });

  @override
  _CircleChannelListPageState createState() => _CircleChannelListPageState();
}

class _CircleChannelListPageState extends State<CircleChannelListPage> {
  List<ChatChannel> channels;

  void updateWithCircleTopic() {
    // 过滤 全部、关注、外露的圈子频道
    final circleTopics = widget.topicList
        .where((e) =>
            e.type == CircleTopicType.common &&
            channels.indexWhere((channel) => channel.id == e.topicId) < 0)
        .map((e) => ChatChannel(
              id: e.topicId,
              name: e.topicName,
              type: ChatChannelType.guildCircleTopic,
            ))
        .toList();
    if (circleTopics.isNotEmpty) {
      // channels.insertAll(0, Circle)
      channels.insertAll(0, circleTopics);
      channels.insert(
          0, ChatChannel(type: ChatChannelType.guildCategory, name: '圈子'));
    }
  }

  @override
  void initState() {
    final GuildPermission gp = PermissionModel.getPermission(
        ChatTargetsModel.instance.selectedChatTarget.id);
    channels = (ChatTargetsModel.instance.selectedChatTarget as GuildTarget)
        .channels
        .where((element) => PermissionUtils.isChannelVisible(gp, element.id))
        .toList(); //[dj private channel] 屏蔽掉私密频道
    updateWithCircleTopic();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget appBar;
    if (OrientationUtil.portrait) {
      appBar = CustomAppbar(
        title: '选择频道'.tr,
        leadingIcon: IconFont.buffNavBarCloseItem,
      );
    } else {
      appBar = CustomAppbar(
        title: '选择频道'.tr,
        leadingBuilder: (icon) => const SizedBox(),
        actions: [
          AppbarIconButton(
              onTap: Get.back,
              icon: IconFont.buffChatTextShrink,
              size: 18,
              color: CustomColor(context).disableColor)
        ],
      );
    }

    return Scaffold(
      appBar: appBar,
      backgroundColor: appThemeData.backgroundColor,
      body: ListView.builder(
        itemCount: channels.length,
        itemBuilder: (context, i) => _buildChannelItem(channels[i]),
      ),
    );
  }

  Widget _buildChannelItem(ChatChannel item) {
    final channel = item;
    if (channel.type == ChatChannelType.guildCategory) {
      return Padding(
        padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
        child: Text(
          channel.name,
          style: appThemeData.textTheme.caption.copyWith(height: 1.25),
        ),
      );
    }

    return Column(
      children: [
        FadeButton(
            height: 52,
            backgroundColor: Theme.of(context).backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () {
              Get.back(result: item);
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  ChannelIcon(
                    channel.type,
                    size: 16,
                  ),
                  sizeWidth8,
                  Expanded(
                    child: Text(
                      channel.name,
                      style: appThemeData.textTheme.bodyText1
                          .copyWith(height: 1.25),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
        const Padding(
          padding: EdgeInsets.only(left: 40),
          child: divider,
        )
      ],
    );
  }
}
