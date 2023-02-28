/*
 * @FilePath       : /social/lib/pages/bot_market/widget/bot_description.dart
 * 
 * @Info           : 
 * 
 * @Author         : Whiskee Chan
 * @Date           : 2021-12-25 16:52:41
 * @Version        : 1.0.0
 * 
 * Copyright 2021 iDreamSky FanBook, All Rights Reserved.
 * 
 * @LastEditors    : Whiskee Chan
 * @LastEditTime   : 2021-12-25 20:12:41
 * 
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/bot_market/model/robot_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:readmore/readmore.dart';

/// 机器人描述组件
///
/// 优先取[description]参数作为展示的描述
/// 否则会使用[botId]从机器人缓存[RobotModel.instance]里面机器人信息
class BotDescription extends StatefulWidget {
  final String botId;
  final String description;

  BotDescription({
    Key key,
    this.botId,
    this.description,
  })  : assert(botId.hasValue || description != null),
        super(key: key);

  @override
  _BotDescriptionState createState() => _BotDescriptionState();
}

class _BotDescriptionState extends State<BotDescription> {
  Future<BotInfo> _future;

  bool get hasDescription => widget.description.hasValue;

  @override
  void initState() {
    if (!hasDescription) {
      _future = RobotModel.instance.getRobot(widget.botId);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (hasDescription) {
      return _getDescriptionWidget(widget.description);
    }
    return FutureBuilder<BotInfo>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError || !snapshot.hasData) {
            return sizedBox;
          }
          return _getDescriptionWidget(snapshot.data.botDescription);
        });
  }

  Widget _getDescriptionWidget(String description) {
    return RepaintBoundary(
      child: ReadMoreText(
        '${"简介: ".tr}${description.hasValue ? description : "没有描述信息~".tr}',
        colorClickableText: primaryColor,
        delimiter: "",
        trimLength: 1000,
        trimMode: TrimMode.Line,
        trimCollapsedText: "...${'展开'.tr}",
        trimExpandedText: ' 收起'.tr,
        moreStyle: Get.textTheme.bodyText2.copyWith(
          color: primaryColor,
          fontSize: 14,
          height: 1.25,
        ),
        style: Get.textTheme.bodyText2.copyWith(
          color: Get.theme.disabledColor,
          fontSize: 14,
          height: 1.25,
        ),
      ),
    );
  }
}
