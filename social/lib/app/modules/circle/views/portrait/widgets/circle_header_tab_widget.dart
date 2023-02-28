import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/const.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/views/portrait/widgets/custom_tabbar_indicator.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/default_theme.dart';

class CircleHeaderTabWidget extends GetView<CircleController> {
  const CircleHeaderTabWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CircleController>(
      builder: (c) {
        return Container(
          decoration: const BoxDecoration(color: Colors.white),
          height: tabBarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    TabBar(
                      tabs: _tabs(),
                      padding:
                          const EdgeInsets.only(bottom: 8, top: 5, left: 8),
                      labelColor: appThemeData.textTheme.bodyText2.color,
                      unselectedLabelColor:
                          appThemeData.textTheme.headline2.color,
                      controller: controller.tabController ??
                          TabController(length: 0, vsync: controller),
                      isScrollable: true,
                      labelPadding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
                      unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          height: 1.25),
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          height: 1.25),
                      indicator: MyUnderlineTabIndicator(
                        borderSide: BorderSide(width: 2, color: primaryColor),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 24,
                        height: 35,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            // stops: [0.0, 1.0],
                            colors: [
                              Color.fromRGBO(255, 255, 255, 0),
                              Colors.white
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _tabs() {
    ///因为‘全部’显示tabBar的时候改成了‘最新’,如果服务端改动这个字段值影响面较大
    ///故只能在显示tabBar的Item的时候做处理了
    return controller.circleTopicList
        .map((e) => Tab(text: e.topicName))
        .toList();
  }
}

//TODO 废弃组件
/// tab 更多内容的弹出的页面
class CircleHeaderTabMoreWidget extends GetView<CircleController> {
  Widget _item(BuildContext context, String topicName, String topicId) {
    final isSelected = controller.topicId == topicId;
    return ChoiceChip(
      pressElevation: 1,
      selectedColor: primaryColor,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(16),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            IconFont.buffPoundSign,
            size: 14,
            color: isSelected
                ? Colors.white
                : Theme.of(context).textTheme.bodyText2.color,
          ),
          const SizedBox(
            width: 3,
          ),
          Text(
            topicName,
            style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyText2.color,
                fontSize: 14,
                height: 1.2),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        final findIndex = controller.topicAtIndex(topicId);
        if (findIndex >= 0) {
          controller.tabController.index = findIndex;
        }
        Get.back();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topicList = controller.circleTopicList ?? [];
    return Container(
      constraints: const BoxConstraints(minHeight: 230),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: topicList
            .map((e) => _item(context, e.topicName, e.topicId))
            .toList(),
      ),
    );
  }
}
