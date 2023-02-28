import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';

import 'model.dart';

class PortraitNotificationManagerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
          title: '频道消息提醒'.tr,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor),
      body: GetBuilder<NotificationManagerController>(
          init: NotificationManagerController(),
          builder: (c) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    child: Text(
                      '关闭频道消息提醒后，设备将不再接收该频道的新消息通知'.tr,
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return buildItem(context, index, c);
                  }, childCount: c.channels.length),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 34)),
              ],
            );
          }),
    );
  }

  Widget buildItem(BuildContext context, int index,
      NotificationManagerController controller) {
    final channel = controller.channels[index];
    if (channel.isCategory) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 0, 6),
        child: Text(
          channel?.name ?? '',
          style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 14),
        ),
      );
    } else {
      return Stack(
        children: [
          Container(
            color: Theme.of(context).backgroundColor,
            child: ListTile(
                title: Row(
                  children: [
                    sizeWidth4,
                    Icon(
                        channel.isPrivate
                            ? IconFont.buffWenzipindaotubiao
                            : IconFont.buffSimiwenzipindao,
                        size: 16,
                        color: Theme.of(context).textTheme.bodyText1.color),
                    sizeWidth12,
                    Expanded(
                      child: Text(
                        channel.name,
                        style: Theme.of(context).textTheme.bodyText2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                trailing: SizedBox(
                  width: 84,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!channel.selected)
                        Icon(
                          IconFont.buffChannelForbidNotice,
                          color: const Color(0xff8F959E).withOpacity(0.5),
                          size: 16,
                        ),
                      Transform.scale(
                        scale: 0.9,
                        alignment: Alignment.centerRight,
                        child: CupertinoSwitch(
                            activeColor: Theme.of(context).primaryColor,
                            value: channel.selected,
                            onChanged: (v) =>
                                controller.updateChannel(index, v)),
                      ),
                    ],
                  ),
                )),
          ),
          const Positioned(bottom: 0, left: 48, right: 0, child: divider),
        ],
      );
    }
  }
}
