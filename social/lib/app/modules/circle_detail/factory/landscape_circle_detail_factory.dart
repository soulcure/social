import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/circle_detail/views/widget/circle_detail_article_topic.dart';
import 'package:im/web/widgets/app_bar/web_appbar.dart';

import 'abstract_circle_detail_factory.dart';

class LandscapeCircleDetailFactory extends AbstractCircleDetailFactory {
  @override
  Widget showAppBar(CircleDetailController controller,
          {BuildContext context}) =>
      WebAppBar(
        title: '动态详情'.tr,
        height: 68,
      );

  @override
  CircleDetailArticleTopic createArticleTopic(String topicName,
          {double top, double bottom, Color textColor, Color bgColor}) =>
      CircleDetailArticleTopic(
        topicName,
        top: top,
        bottom: bottom,
        textColor: textColor,
        bgColor: bgColor,
      );
}
