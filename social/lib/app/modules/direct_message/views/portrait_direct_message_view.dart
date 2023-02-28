import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/api/user_api.dart';
import 'package:im/app/modules/direct_message/views/item.dart';
import 'package:im/app/modules/friend_apply_page/controllers/friend_apply_page_controller.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/db/db.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/pages/search/widgets/search_input_box.dart';
import 'package:im/svg_icons.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/svg_tip_widget.dart';
import 'package:im/widgets/top_status_bar.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

import '../controllers/direct_message_controller.dart';

class NotifySwitcherStream {}

class NotifyWebSwitcherStream {}

class PortraitDirectMessageView extends StatefulWidget {
  const PortraitDirectMessageView({Key key}) : super(key: key);

  @override
  _PortraitDirectMessageViewState createState() =>
      _PortraitDirectMessageViewState();
}

class _PortraitDirectMessageViewState extends State<PortraitDirectMessageView> {
  StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = TextChannelUtil.instance.stream.listen((value) {
      switch (value.runtimeType) {
        case NotifySwitcherStream:
          setState(() {});
          break;
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DirectMessageController>(builder: (c) {
      return Stack(
        children: [
          Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: FbAppBar.noLeading(
              '消息'.tr,
              actions: [
                AppBarIconActionModel(
                  IconFont.buffFriendListNew,
                  isShowRedDotWithNum: true,
                  unreadMsgNumListenable:
                      FriendApplyPageController.friendApplyNum,
                  actionBlock: () {
                    Get.toNamed(Routes.FRIEND_LIST_PAGE).then((_) {
                      setState(() {});
                    });
                  },
                )
              ],
            ),
            backgroundColor: Colors.white,
            body: c.channels.isEmpty ? _emptyWidget() : _contentWidget(c),
          ),
          ValueListenableBuilder(
            valueListenable: TopStatusController.to().showStatusUI,
            builder: (context, visible, child) => AnimatedPositioned(
              left: 0,
              right: 0,
              height: visible
                  ? (TopStatusBar.height + MediaQuery.of(context).padding.top)
                  : 0,
              duration: kThemeAnimationDuration,
              child: child,
            ),
            child: TopStatusBar(),
          ),
        ],
      );
    });
  }

  // AppBar _appBar() {
  //   return AppBar(
  //     // backgroundColor: const Color(0xFFF5F5F8),
  //     title: Padding(
  //       padding: const EdgeInsets.only(top: 2),
  //       child: Text(
  //         '消息'.tr,
  //         style: Theme.of(context).textTheme.headline5.copyWith(fontSize: 20),
  //       ),
  //     ),
  //     automaticallyImplyLeading: false,
  //     actions: [
  //       Stack(
  //         children: [
  //           Center(
  //             child: GestureDetector(
  //               onTap: () {
  //                 Get.toNamed(Routes.FRIEND_LIST_PAGE);
  //               },
  //               behavior: HitTestBehavior.translucent,
  //               child: Container(
  //                 padding: const EdgeInsets.only(right: 16),
  //                 child: Icon(
  //                   IconFont.buffFriendList,
  //                   color: Theme.of(context).iconTheme.color,
  //                   size: 24,
  //                 ),
  //               ),
  //             ),
  //           ),
  //           Positioned(
  //             top: 4,
  //             right: 6,
  //             child: RedDotListenable(
  //               valueListenable: FriendApplyPageController.friendApplyNum,
  //             ),
  //           ),
  //         ],
  //       )
  //     ],
  //     centerTitle: false,
  //     toolbarHeight: 44,
  //     elevation: 0,
  //   );
  // }

  Widget _emptyWidget() {
    return Center(
      child: ValueListenableBuilder(
        valueListenable: TopStatusController.to().showStatusUI,
        builder: (context, v, child) {
          return SvgTipWidget(
            svgName: v ? SvgIcons.noNetState : SvgIcons.nullState,
            text: v ? '你的网络不佳哦'.tr : '你还没有收到私信哦'.tr,
            textSize: 17,
            desc: v ? '当前网络不佳，请勿拍打设备\n检查你的网络设置' : '在服务器中遇到有趣的朋友\n要主动Say Hi 呀~',
          );
        },
      ),
    );
  }

  Widget _contentWidget(DirectMessageController c) {
    return GestureDetector(
      onTapDown: (details) => c.focusNode.unfocus(),
      onVerticalDragStart: (details) => c.focusNode.unfocus(),
      child: CustomScrollView(
        key: const PageStorageKey('direct_message'),
        controller: c.scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: Colors.white,
              child: SizedBox(
                height: 36,
                child: SearchInputBox(
                  searchInputModel: c.searchInputModel,
                  inputController: c.textEditingController,
                  height: 36,
                  autoFocus: false,
                  focusNode: c.focusNode,
                ),
              ),
            ),
          ),
          GetBuilder<DirectMessageController>(
            builder: (_) {
              return SliverFixedExtentList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => getItem(c.filterChannels, index),
                  childCount: c.filterChannels.length,
                ),
                itemExtent: 72,
              );
            },
          ),
        ],
      ),
    );
  }

  void refreshThis() {
    setState(() {});
  }

  Widget getItem(List<ChatChannel> list, int index) {
    if (UniversalPlatform.isIOS) {
      return swipeItem(list, index);
    } else {
      return androidItem(list, index);
    }
  }

  Widget androidItem(List<ChatChannel> list, int index) {
    final ChatChannel item = list[index];
    return Item(
      key: ValueKey(item.id),
      channel: item,
      refreshParent: refreshThis,
    );
  }

  Widget swipeItem(List<ChatChannel> list, int index) {
    final ChatChannel item = list[index];

    final List<SwipeAction> trailingActions = [
      SwipeAction(
          //widthSpace: 80,
          // title: '不显示'.tr,
          // style: const TextStyle(fontSize: 14, color: Colors.white),
          content: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                '不显示'.tr,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                maxLines: 1,
              ),
            ),
          ),
          onTap: (handler) async {
            await handler(true);
            list.removeAt(index);
            unawaited(DirectMessageController.to.closeChannel(item));
            setState(() {});
          },
          color: const Color(0xFFFA9D3B)),
    ];

    if (item.type == ChatChannelType.group_dm ||
        item.type == ChatChannelType.circlePostNews) {
      final bool isMuted = (Db.userConfigBox.get(UserConfig.mutedChannel) ?? [])
          .contains(item.id);
      final Widget content = isMuted
          ? Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  '开启提醒'.tr,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  maxLines: 1,
                ),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  '关闭提醒'.tr,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  maxLines: 1,
                ),
              ),
            );
      trailingActions.add(SwipeAction(
          widthSpace: 90,
          //title: isMuted ? '开启提醒'.tr : '关闭提醒'.tr,
          //style: const TextStyle(fontSize: 14, color: Colors.white),
          content: content,
          onTap: (handler) async {
            await handler(false);
            final mutedChannels =
                (Db.userConfigBox.get(UserConfig.mutedChannel) ?? []).toList();
            if (isMuted) {
              mutedChannels.remove(item.id);
            } else {
              mutedChannels.add(item.id);
            }
            await UserApi.updateSetting(mutedChannels: mutedChannels);
            await UserConfig.update(mutedChannels: mutedChannels);
            showToast(isMuted ? '已开启消息提醒'.tr : '已关闭消息提醒'.tr);
            DirectMessageController.to.updateUnread();

            setState(() {});
          },
          color: const Color(0xFF646A73)));
    }

    final Widget swipeActionCell = SwipeActionCell(
      key: ValueKey(item.id),
      trailingActions: trailingActions,
      normalAnimationDuration: 150,
      deleteAnimationDuration: 50,
      closeWhenScrolling: false,
      fullSwipeFactor: 50,
      child: Item(
        channel: item,
        refreshParent: refreshThis,
      ),
    );

    return swipeActionCell;
  }
}
