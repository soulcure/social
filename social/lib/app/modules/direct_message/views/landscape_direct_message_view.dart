import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/direct_message/views/portrait_direct_message_view.dart';
import 'package:im/app/modules/friend_apply_page/controllers/friend_apply_page_controller.dart';
import 'package:im/app/routes/app_pages.dart' as get_pages show Routes;
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/components/red_dot.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/pages/search/widgets/search_input_box.dart';
import 'package:im/themes/const.dart';
import 'package:im/web/pages/main/main_model.dart';
import 'package:provider/provider.dart';

import '../controllers/direct_message_controller.dart';
import 'item.dart';

class LandscapeDirectMessageView extends StatefulWidget {
  const LandscapeDirectMessageView({Key key}) : super(key: key);

  @override
  _LandscapeDirectMessageViewState createState() =>
      _LandscapeDirectMessageViewState();
}

class _LandscapeDirectMessageViewState
    extends State<LandscapeDirectMessageView> {
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
    return GetBuilder<DirectMessageController>(builder: (controller) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.only(left: 16),
              alignment: Alignment.centerLeft,
              child: Text(
                '我的主页'.tr,
                style: Theme.of(context)
                    .textTheme
                    .bodyText2
                    .copyWith(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Divider(
                  color: Theme.of(context).dividerColor.withOpacity(0.1)),
            ),
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                    color: const Color(0xFFF0F1F2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFDEE0E3))),
                child: SearchInputBox(
                  searchInputModel: controller.searchInputModel,
                  inputController: controller.textEditingController,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 8, top: 2),
                    child: Icon(
                      IconFont.buffCommonSearch,
                      size: 14,
                      color: Color(0x4D1F2329),
                    ),
                  ),
                  height: 32,
                  fontSize: 14,
                  autoFocus: false,
                  focusNode: controller.focusNode,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChangeNotifierProvider.value(
                value: MainRouteModel.instance,
                child: Selector<MainRouteModel, bool>(
                    selector: (_, model) =>
                        model.routes.last.route ==
                        get_pages.Routes.FRIEND_LIST_PAGE,
                    builder: (context, v, child) {
                      return FadeBackgroundButton(
                        backgroundColor: v
                            ? Colors.white
                            : Theme.of(context).scaffoldBackgroundColor,
                        tapDownBackgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: 4,
                        onTap: () {
                          ChatTargetsModel.instance.selectChatTarget(null);
                          MainRouteModel.instance.pushFriendListPage();
                        },
                        child: SizedBox(
                          height: 40,
                          child: Row(
                            children: [
                              sizeWidth8,
                              const Icon(
                                IconFont.buffNaviFriendList,
                                size: 16,
                              ),
                              sizeWidth8,
                              Expanded(
                                child: Text(
                                  '我的好友'.tr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyText2
                                      .copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                ),
                              ),
                              ValueListenableBuilder<int>(
                                valueListenable:
                                    FriendApplyPageController.friendApplyNum,
                                builder: (context, val, _) {
                                  return RedDot(
                                    val,
                                    child: child,
                                  );
                                },
                              ),
                              sizeWidth16
                            ],
                          ),
                        ),
                      );
                    }),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 28, 0, 8),
              alignment: Alignment.topLeft,
              child: Text(
                '消息'.tr,
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    .copyWith(fontSize: 12),
              ),
            ),
            Expanded(
                child: ListView.builder(
              controller: ScrollController(),
              itemCount: controller.filterChannels.length,
              itemBuilder: (context, index) => Item(
                key: ValueKey(controller.filterChannels[index].id),
                channel: controller.filterChannels[index],
              ),
              itemExtent: 60,
            ))
          ],
        ),
      );
    });
  }
}
