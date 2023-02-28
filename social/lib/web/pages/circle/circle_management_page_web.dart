import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/icon_font.dart';
import 'package:im/web/pages/circle/circle_base_info_web.dart';
import 'package:im/web/pages/circle/topic_management_web.dart';
import 'package:im/web/widgets/web_form_detector/web_form_page_view.dart';
import 'package:im/web/widgets/web_form_detector/web_form_tab_item.dart';
import 'package:im/web/widgets/web_form_detector/web_form_tab_view.dart';

class CircleManagementPage extends StatefulWidget {
  final CircleInfoDataModel circleInfoDataModel;

  const CircleManagementPage(this.circleInfoDataModel, {Key key})
      : super(key: key);

  @override
  _CircleManagementPageState createState() => _CircleManagementPageState();
}

class _CircleManagementPageState extends State<CircleManagementPage> {
  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF0F1F2);
    return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: SizedBox(
            width: 1040,
            child: WebFormPage(
              tabItems: [
                WebFormTabItem.title(title: '圈子管理'.tr),
                WebFormTabItem(
                    title: '基本信息'.tr, icon: IconFont.webCircleInfo, index: 0),
                WebFormTabItem(
                    title: '话题管理'.tr,
                    icon: IconFont.webCircleTopicSet,
                    index: 1),
              ],
              tabViews: [
                WebFormTabView(
                  title: '基本信息'.tr,
                  index: 0,
                  child: WebCircleBaseInfo(widget.circleInfoDataModel),
                ),
                WebFormTabView(
                  title: '话题管理'.tr,
                  index: 1,
                  child: WebTopicManagement(widget.circleInfoDataModel.guildId,
                      widget.circleInfoDataModel.channelId),
                )
              ],
            ),
          ),
        ));
  }
}
