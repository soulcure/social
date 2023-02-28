import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/topic_tag_text.dart';

class CircleDetailArticleTopic extends StatelessWidget {
  final String topicName;
  final Color bgColor;
  final Color textColor;
  final double top;
  final double bottom;

  const CircleDetailArticleTopic(
    this.topicName, {
    Key key,
    this.bgColor,
    this.textColor,
    this.top = 14,
    this.bottom = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => topicName?.isEmpty ?? true
      ? sizedBox
      : Container(
          margin: EdgeInsets.fromLTRB(16, top ?? 14, 16, bottom ?? 0),
          child: TopicTagText(
            [topicName],
            bgColor: bgColor,
            textColor: textColor,
          ),
        );
}

/// * 发布和更新时间
class CircleDetailTime extends StatelessWidget {
  final int createdAt;
  final int updatedAt;
  final EdgeInsetsGeometry padding;
  final TextStyle textStyle;

  const CircleDetailTime({
    Key key,
    this.createdAt,
    this.updatedAt,
    this.padding,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final text = StringBuffer();
    if (createdAt != 0) {
      text.write(createdAt != updatedAt ? '编辑于 '.tr : '发布于 '.tr);
      text.write(formatDate2Str(
          DateTime.fromMillisecondsSinceEpoch(updatedAt ?? createdAt)
              .toLocal()));
    }
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(
        text.toString(),
        style: textStyle ??
            TextStyle(fontSize: 11, color: appThemeData.disabledColor),
      ),
    );
  }
}
