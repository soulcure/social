import 'package:flutter/material.dart';
import 'package:im/app/modules/circle/models/circle_topic_data_model.dart';
import 'package:im/app/modules/circle/views/landscape/landscape_circle_topic_page.dart';
import 'package:im/app/modules/circle/views/portrait/portrait_circle_topic_page.dart';
import 'package:im/utils/orientation_util.dart';

class CircleTopicPage extends StatelessWidget {
  final String topicId;
  final int showType;
  final CircleTopicType type;

  const CircleTopicPage({Key key, this.topicId, this.showType = 0, this.type})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrientationUtil.portrait
        ? PortraitCircleTopicPage(topicId: topicId, type: type)
        : LandscapeCircleTopicPage(topicId: topicId, showType: showType);
  }
}
