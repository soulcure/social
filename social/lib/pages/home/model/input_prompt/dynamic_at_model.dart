import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/input_prompt/base_input_prompt_model.dart';
import 'package:im/routes.dart';
import 'package:im/themes/default_theme.dart';

class DynamicAtModel extends InputPromptModel {
  DynamicAtModel(InputModel inputModel, this.channel) : super(inputModel, '');

  ChatChannel channel;
  int textLength = 0;

  final List<String> atList = [];

  final List<String> channelList = [];

  final Map<String, String> atMap = {};

  @override
  Future<List> getCompleteList() async {
    final cursorPosition = inputModel.inputController.selection.baseOffset;
    final res = await selectUser();
    inputModel.inputController
        .replaceRange('', start: cursorPosition - 1, end: cursorPosition);
    insertUser(res);
    return Future.value();
  }

  Future<List> selectUser() async {
    return Routes.pushRichEditorAtListPage(Get.context,
        channel: channel, guildId: channel.guildId);
  }

  void insertUser(List res) {
    res?.forEach((e) {
      String atId = '';
      String userId = '';
      String atName = '';
      if (e is Role) {
        userId = e.id;
        atId = TextEntity.getAtString(e.id, true);
        atName = e.name;
      } else if (e is UserInfo) {
        userId = e.userId;
        atId = TextEntity.getAtString(e.userId, false);
        atName = e.showName(guildId: channel.guildId);
      }

      if (!atList.contains(atId)) {
        atList.add(userId);

        atMap[atId] = "@${atName ?? ''}";
      }

      inputModel.inputController.insertAt(atName,
          data: atId, textStyle: TextStyle(color: primaryColor, fontSize: 17));
    });
  }

  @override
  Future<void> submitFilter(String text) {
    if (textLength < text.length) {
      final cursorPosition = inputModel.inputController.selection.baseOffset;
      if (text[max(0, cursorPosition - 1)] == '@') getCompleteList();
      if (text[max(0, cursorPosition - 1)] == '#') getCompleteList();
    }
    textLength = text.length;
    return Future.value();
  }

  @override
  Future<void> onMatch(String match) => Future.value();
}
