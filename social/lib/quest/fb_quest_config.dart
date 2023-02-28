import 'dart:async';

import 'package:get/get_rx/src/rx_workers/utils/debouncer.dart';
import 'package:im/api/util_api.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/bot_market/bot_utils.dart';
import 'package:im/quest/fb_quest.dart';
import 'package:pedantic/pedantic.dart';
import 'package:quest_system/internal/quest_system.dart';
import 'package:quest_system/quest_system.dart';

/// 自定义 id 定义 (quest id segments)

enum QIDSegSequence {
  moreGuildSettings, // 更多服务器设置引导
  guildGuidance, // 服务器引导
  channelSettingGuide, //频道设置引导
  roleSettingGuide, //角色设置引导
  onCreatedShowTask, //创建服务器后弹出任务弹框
}
enum QIDSegGroup {
  quickStart, // 服务器引导 - 服务器快速上手
  newBotRedDot, // 机器人市场新增机器人的红点
}
enum QIDSegQuest {
  understandChannelManage, // 服务器引导 - 服务器快速上手 - 了解频道管理
  inviteFriend, // 服务器引导 - 服务器快速上手 - 邀请好友
  sendFirstMessage, // 服务器引导 - 服务器快速上手 - 发送第一条消息
}

enum FbQuestSequenceId {
  firstEntryServer,
  firstEntryTextChat,
}

enum FbQuestId {
  firstEntryServer,
  firstEntryTextChat,
  firstTimeToManageChannels,
  firstTimeToRoleSetting,
  newBotRedDot, // 机器人市场新增机器人的红点
}

StreamSubscription _saveStream;

void initFbQuestConfig() {
  QuestSystem.addTrigger(CustomTrigger.instance);
  QuestSystem.addTrigger(RouteTrigger.instance);

  QuestSystem.clear();
  _saveStream?.cancel();

  ///频道设置弹窗
  FbQuest.addGuideChannelSetting();

  ///角色设置弹窗
  FbQuest.addGuideRoleSetting();

  ///添加C端用户引导任务
  FbQuest.addClientGuidance();

  ///添加新增机器人红点任务
  FbQuest.addNewBotTag();

  ///从服务器获取任务进度数据并加载
  Future<void> loadDataFromServer() async {
    final data = await UtilApi.getConfig('guidance');
    final params = (data as List)[0]['params'];
    if (params is Map) {
      FbQuest.restoreGuildQuests(params);
      FbQuest.loadQuestsData(params);
    }
    final debounce = Debouncer(delay: const Duration(milliseconds: 100));
    _saveStream = QuestSystem.listenerAll(() {
      debounce(() {
        final data = QuestSystem.acceptVisitor(JsonExportVisitor());
        (data as Map<String, dynamic>).removeWhere((key, value) {
          final botRedDotPrefix =
              const QuestId([FbQuestId.newBotRedDot, '_']).toString();
          return key.startsWith(botRedDotPrefix) ||
              key.startsWith(QIDSegGroup.newBotRedDot.toString());
        });
        Db.guideBox.putAll(data);
        unawaited(UtilApi.setConfig('guidance', data, 'B端任务引导数据'));
      });
    });
  }

  final localData = Db.guideBox.toMap();

  /// 只需要本地保存的任务，在任务进度加载前先恢复任务
  BotUtils.restoreQuests(Map<String, dynamic>.from(localData));

  ///加载本地已有数据
  FbQuest.loadQuestsData(localData);

  ///从服务器获取数据
  loadDataFromServer();
}
