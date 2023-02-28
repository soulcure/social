import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/controllers/circle_topic_controller.dart';
import 'package:im/app/modules/circle/models/guild_topic_sort_model.dart';
import 'package:im/app/modules/circle/views/widgets/create_moment_button.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/guild_setting/circle/circle_loading_view.dart';
import 'package:im/themes/const.dart';
import 'package:im/web/pages/main/main_model.dart';
import 'package:im/web/widgets/popup/web_popup.dart';
import 'package:im/web/widgets/tab_bar/web_tab_bar.dart';

import '../circle_topic_page.dart';
import 'widgets/circle_header_widget.dart';

class LandscapeCircleMainPage extends StatefulWidget {
  const LandscapeCircleMainPage();

  @override
  _LandscapeCircleMainPageState createState() =>
      _LandscapeCircleMainPageState();
}

class _LandscapeCircleMainPageState extends State<LandscapeCircleMainPage> {
  CircleController controller;

  @override
  void initState() {
    final CircleControllerParam args = MainRouteModel.instance.routes.last.args;
    controller = CircleController(args.guildId, args.channelId,
        topicId: args.topicId,
        autoPushCircleMessage: args.autoPushCircleMessage);

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CircleController>(
        init: controller,
        builder: (c) {
          return c.initFinish ? _buildCircleMainPage() : CircleLoadingView();
        });
  }

  Widget _buildCircleMainPage() {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        floatingActionButton: const CreateMomentButton(),
        body: Column(
          children: [
            const CircleHeaderWidget(),
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 68),
                    child: TabBarView(
                        controller: controller.tabController,
                        children: controller.circleTopicList
                            .map((e) => CircleTopicPage(
                                  topicId: e.topicId,
                                  key: ValueKey(e.topicId),
                                ))
                            .toList()),
                  ),
                  _buildWebTab(),
                ],
              ),
            )
          ],
        ));
  }

  Widget _buildWebTab() {
    return GetBuilder<WebTabBarModel>(
      init: controller.tabBarModel,
      builder: (model) {
        String topicId = controller.circleTopicList[model.selectIndex].topicId;
        topicId = topicId.isEmpty ? '_all' : topicId;
        return Container(
          padding: EdgeInsets.only(
              left: 24, right: 24, top: 12, bottom: model.expand ? 12 : 2),
          decoration: BoxDecoration(
              color: Theme.of(context).backgroundColor,
              boxShadow: model.expand
                  ? [
                      BoxShadow(
                          offset: const Offset(16, 16),
                          blurRadius: 16,
                          color: const Color(0xFF717D8D).withOpacity(0.2))
                    ]
                  : []),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: WebTabBar(),
              ),
              const SizedBox(
                width: 40,
              ),
              GetBuilder(
                  key: ValueKey(topicId),
                  init: CircleTopicController.to(topicId: topicId),
                  tag: topicId,
                  builder: (c) {
                    return ValueListenableBuilder<Box<Map>>(
                        valueListenable: Db.guildTopicSortCategoryBox
                            .listenable(keys: [controller.guildId]),
                        builder: (context, _, __) {
                          final value =
                              controller.sortModel.getSortIdx(topicId);
                          return TextButton(
                            onPressed: () async {
                              final index = await showWebSelectionPopup(context,
                                  items: CircleSortType.values
                                      .map((e) => e.typeName)
                                      .toList());
                              if (index != null && index != c.sortIdx) {
                                c.sortIdx = index;
                                //切换了排序方式，重新刷新
                                c.loadData(reload: true);
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4)),
                              height: 32,
                              width: 118,
                              child: Row(
                                children: [
                                  sizeWidth12,
                                  Text(
                                    value == 0 ? '最新回复'.tr : '最新发布'.tr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyText2
                                        .copyWith(fontSize: 14),
                                  ),
                                  sizeWidth24,
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                  }),
            ],
          ),
        );
      },
    );
  }
}
