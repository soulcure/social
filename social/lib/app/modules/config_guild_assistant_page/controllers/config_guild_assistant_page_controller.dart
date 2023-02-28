import 'dart:core';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/bot_api.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/api/entity/create_template.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/utils.dart';
import 'package:im/utils/welcome_content.dart';
import 'package:im/widgets/land_pop_app_bar.dart';

import '../../../../icon_font.dart';

class RobotConfigInfo {
  final List<String> robotList;
  final String batchGuidType;
  final String avatarUrl;
  final String serverName;

  RobotConfigInfo(
      this.robotList, this.batchGuidType, this.avatarUrl, this.serverName);
}

class ConfigGuildAssistantPageController extends GetxController {
  static const String listUpdated = "listUpdated";

  ConfigGuildAssistantPageController(this.robotConfigInfo);

  //{"robotList": robotIds, "batchGuidType": widget.batchGuidType, "avatarUrl": avatarUrl}
  final RobotConfigInfo robotConfigInfo;

  final List<BotInfo> bots = [
    BotInfo(
        botName: "某机器人".tr,
        botDescription: "使用Fan-Bot机器人能帮助你设置新成员验证、表态分配角色等功能，助力服务器管理事半功倍。".tr),
    BotInfo(
        botName: "小熊猫".tr,
        botDescription: "小熊猫是服务器的数据小助手，它可以帮助记录服务器的数据情况，帮你快速了解服务器的数据和运营情况。".tr)
  ];

  final List<WelcomeContentItem> toNextPageList = [];

  @override
  void onInit() {
    super.onInit();
    loadBotsInfo();
  }

  Future loadBotsInfo() async {
    bots.clear();
    final List<CreateTemplate> typeList =
        await GuildApi.getGuildChannelTemplate(
            guildType: robotConfigInfo.batchGuidType);
    typeList.forEach((element) {
      if (element.channelType != ChatChannelType.guildCategory.index) {
        toNextPageList.add(WelcomeContentItem(IconFont.buffWenzipindaotubiao,
            element.channelName, element.channelDesc));
      }
    });

    await Future.forEach(robotConfigInfo.robotList, (botId) async {
      final b = await BotApi.getBot(botId);
      if (b is BotInfo) {
        bots.add(b);
      }
    });
    update([ConfigGuildAssistantPageController.listUpdated]);
    // return;
  }

  void onNext() {
    Get.back();
    Get.bottomSheet(
      WelcomeContent(
        imageUrl: robotConfigInfo.avatarUrl,
        title: "%s创建成功".trArgs([robotConfigInfo.serverName ?? '']),
        tips: "这是根据模板生成的频道：".tr,
        buttonText: "进入服务器".tr,
        items: toNextPageList,
        buttonPress: Get.back,
        // bottomTips: "",
      ),
      isScrollControlled: true,
    );
  }

  void onNextDialog() {
    Get.back();
    Get.dialog(popWrap(
      horizontal: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LandPopAppBar(horizontal: 24),
          WelcomeContent(
            imageUrl: robotConfigInfo.avatarUrl,
            title: "${robotConfigInfo.serverName}创建成功",
            tips: "这是根据模板生成的频道：",
            buttonText: "进入服务器",
            items: toNextPageList,
            buttonPress: Get.back,
            // bottomTips: "",
          ),
        ],
      ),
    ));
  }
}
