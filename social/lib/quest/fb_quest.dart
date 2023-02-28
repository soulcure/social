import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/guide/components/business_guide.dart';
import 'package:im/app/modules/guide/components/client_guide.dart';
import 'package:im/app/modules/guide/components/task_status_panel.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:quest_system/quest_system.dart';
import 'fb_quest_config.dart';

// 任务 id 段：关闭服务器引导弹窗后，出现查看更多指引
enum QIDSegGuildQuickStart {
  moreGuildSettings,
  onCreatedShowTask,
}

class FbQuest {
  ///加载所有的任务进度数据
  static void loadQuestsData(Map data) {
    final importer = JsonImportVisitor(Map<String, dynamic>.from(data));
    QuestSystem.acceptVisitor(importer);
  }

  ///重新添加所有服务器的任务组
  static void restoreGuildQuests(Map<String, dynamic> data) {
    final loadData = Map<String, dynamic>.from(data);
    final guildQuestPrefix =
        const QuestId([QIDSegSequence.guildGuidance]).toString();
    loadData?.keys?.forEach((k) {
      if (k.startsWith(guildQuestPrefix)) {
        final splits = k.split("-");
        if (splits.length > 1) {
          final guildId = splits[1];
          final quest = QuestSystem.getQuest(
              QuestId([QIDSegSequence.guildGuidance, "-", guildId]));

          ///如果已经加载了相同的任务则return
          if (quest != null) return;
          FbQuest.addCreatedGuildGuide(guildId);
        }
      }
    });
  }

  /// 由于可能同时存在多个服务器引导任务，因此不能使用枚举作为 id 和 任务条件，与服务器相关的任务都要使用特殊 id 和条件
  /// 触发器也只能用 [CustomTrigger]
  /// 创建新服务器后的新手引导，这个任务可以被添加多个
  static void addCreatedGuildGuide(String guildId) {
    ///快速上手服务器任务组
    final seq = QuestSequence(
        id: QuestId([QIDSegSequence.guildGuidance, "-", guildId]),
        children: [
          QuestGroup(
            id: QuestId([QIDSegGroup.quickStart, "-", guildId]),
            triggerChecker: QuestChecker.automate(),
            completeChecker: QuestChecker.condition(
                QuestCondition([QIDSegGroup.quickStart, guildId])),
            onComplete: () => DLogManager.getInstance().customEvent(
              actionEventId: "guild_guide",
              actionEventSubId: "click_task_progress",
              actionEventSubParam: "confirm",
              extJson: {"guild_id": guildId},
            ),
            children: [
              Quest(
                id: QuestId(
                    [QIDSegQuest.understandChannelManage, "-", guildId]),
                triggerChecker: QuestChecker.automate(),
                completeChecker: QuestChecker.condition(
                  QuestCondition(
                      [QIDSegQuest.understandChannelManage, guildId]),
                ),
                onComplete: () => DLogManager.getInstance().customEvent(
                  actionEventId: "guild_guide",
                  actionEventSubId: "click_task_progress",
                  actionEventSubParam: "channel",
                  extJson: {"guild_id": guildId},
                ),
              ),
              Quest(
                id: QuestId([QIDSegQuest.sendFirstMessage, "-", guildId]),
                triggerChecker: QuestChecker.automate(),
                completeChecker: QuestChecker.custom((data) {
                  /// 只需要是这个服务器发的消息就行，不管是哪个频道
                  return data.condition.toString().startsWith(QuestCondition([
                        QIDSegQuest.sendFirstMessage,
                        "-",
                        guildId,
                      ]).toString());
                }),
                onComplete: () => DLogManager.getInstance().customEvent(
                  actionEventId: "guild_guide",
                  actionEventSubId: "click_task_progress",
                  actionEventSubParam: "send",
                  extJson: {"guild_id": guildId},
                ),
              ),
              Quest(
                id: QuestId([QIDSegQuest.inviteFriend, "-", guildId]),
                triggerChecker: QuestChecker.automate(),
                completeChecker: QuestChecker.condition(
                  QuestCondition([QIDSegQuest.inviteFriend, guildId]),
                ),
                onComplete: () => DLogManager.getInstance().customEvent(
                  actionEventId: "guild_guide",
                  actionEventSubId: "click_task_progress",
                  actionEventSubParam: "share",
                  extJson: {"guild_id": guildId},
                ),
              ),
            ],
          )
        ]);

    ///关闭任务弹窗时显示更多服务器设置浮标
    final tipSeq = QuestSequence(
        id: QuestId([QIDSegSequence.moreGuildSettings, "-", guildId]),
        children: [
          Quest(
              id: QuestId(
                  [QIDSegGuildQuickStart.moreGuildSettings, "-", guildId]),
              triggerChecker: QuestChecker.custom((data) {
                final condition = data.condition;
                return condition is RouteCondition &&
                    condition.routeName == Routes.BS_GUILD_INTRO &&
                    condition.isRemove &&
                    ChatTargetsModel.instance.selectedChatTarget?.id == guildId;
              }),
              completeChecker: QuestChecker.custom((data) {
                final condition = data.condition;
                return condition is RouteCondition &&
                    condition.routeName == Routes.BS_GUILD_SETTINGS &&
                    ChatTargetsModel.instance.selectedChatTarget?.id == guildId;
              }))
        ]);

    ///当创建完服务器后展示任务弹窗
    final onCreatedShowTask = QuestSequence(
        id: QuestId([QIDSegSequence.onCreatedShowTask, "-", guildId]),
        children: [
          Quest(
            id: QuestId(
                [QIDSegGuildQuickStart.onCreatedShowTask, "-", guildId]),
            onTrigger: () {
              final questGroup = QuestSystem.getQuest<QuestGroup>(QuestId([
                QIDSegGroup.quickStart,
                "-",
                ChatTargetsModel.instance.selectedChatTarget?.id
              ]));
              Future.delayed(const Duration(milliseconds: 400), () {
                Get.bottomSheet(
                  BusinessGuide(questGroup, TaskStatusPanel.taskTitles),
                  isScrollControlled: true,
                  settings: const RouteSettings(name: Routes.BS_GUILD_INTRO),
                );
                DLogManager.getInstance().customEvent(
                  actionEventId: "guild_guide",
                  actionEventSubId: "show_guide",
                  actionEventSubParam: "create_auto_push",
                  extJson: {"guild_id": guildId},
                );
              });
            },
            triggerChecker: QuestChecker.condition(QuestCondition(
              [QIDSegGuildQuickStart.onCreatedShowTask, guildId],
            )),
            completeChecker: QuestChecker.condition(const RouteCondition(
                routeName: Routes.BS_GUILD_INTRO, isRemove: true)),
          )
        ]);

    QuestSystem.addQuestContainers([seq, tipSeq, onCreatedShowTask]);
  }

  ///频道设置弹窗
  static void addGuideChannelSetting() {
    final seq = QuestSequence(
      id: QIDSegSequence.channelSettingGuide,
      children: [
        Quest(
          id: FbQuestId.firstTimeToManageChannels,
          onTrigger: () {
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              GuideBottomSheet.showChannelPopup();
            });
          },
          triggerChecker: QuestChecker.condition(
            const RouteCondition(
                routeName: Routes.GUILD_CHANNEL_SETTINGS, isRemove: false),
          ),
          completeChecker: QuestChecker.condition(
            const RouteCondition(
                routeName: Routes.GUILD_CHANNEL_SETTINGS, isRemove: true),
          ),
        ),
      ],
    );

    QuestSystem.addQuestContainer(seq);
  }

  ///角色设置弹窗
  static void addGuideRoleSetting() {
    final seq = QuestSequence(
      id: QIDSegSequence.roleSettingGuide,
      children: [
        Quest(
          id: FbQuestId.firstTimeToRoleSetting,
          onTrigger: () {
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              GuideBottomSheet.showRolePopup();
            });
          },
          triggerChecker: QuestChecker.condition(
            const RouteCondition(
                routeName: Routes.GUILD_ROLE_MANAGER, isRemove: false),
          ),
          completeChecker: QuestChecker.condition(
            const RouteCondition(
                routeName: Routes.GUILD_ROLE_MANAGER, isRemove: true),
          ),
        ),
      ],
    );

    QuestSystem.addQuestContainer(seq);
  }

  ///添加C端指引
  static void addClientGuidance() {
    ///首次进入服务器
    final firstEntryServer = QuestSequence(
      id: FbQuestSequenceId.firstEntryServer,
      children: [
        Quest(
          id: FbQuestId.firstEntryServer,
          onTrigger: () {
            Future.delayed(
              const Duration(milliseconds: 300),
              GuideBottomSheet.showPageViewPopup,
            );
            DLogManager.getInstance().customEvent(
              actionEventId: "guild_join",
              actionEventSubId: "show_community",
              extJson: {
                "guild_id": ChatTargetsModel.instance.selectedChatTarget?.id
              },
            );
          },
          triggerChecker: QuestChecker.condition(
            const QuestCondition(
              [FbQuestId.firstEntryServer],
            ),
          ),
          completeChecker: QuestChecker.condition(
            const RouteCondition(
                routeName: Routes.BS_GUILD_FIRST_ENTRY, isRemove: true),
          ),
        )
      ],
    );

    ///首次进入文字频道
    final firstEntryTextChat = QuestSequence(
      id: FbQuestSequenceId.firstEntryTextChat,
      children: [
        Quest(
          id: FbQuestId.firstEntryTextChat,
          onComplete: () {
            Future.delayed(
              const Duration(milliseconds: 300),
              GuideBottomSheet.showTextChatPopup,
            );
            DLogManager.getInstance().customEvent(
              actionEventId: "guild_join",
              actionEventSubId: "show_channel_page",
              actionEventSubParam: GlobalState.selectedChannel.value?.id,
              extJson: {
                "guild_id": ChatTargetsModel.instance.selectedChatTarget?.id
              },
            );
          },
          triggerChecker: QuestChecker.condition(
            const QuestCondition(
              [FbQuestId.firstEntryServer],
            ),
          ),
          completeChecker: QuestChecker.custom((data) {
            final condition = data.condition;
            return condition is RouteCondition &&
                condition.routeName == Routes.SECOND_SCREEN &&
                GlobalState.selectedChannel.value?.type ==
                    ChatChannelType.guildText;
          }),
        )
      ],
    );

    QuestSystem.addQuestContainers([firstEntryServer, firstEntryTextChat]);
  }

  ///机器人市场新增机器人红点
  static void addNewBotTag() {
    QuestSystem.addQuestContainer(
      QuestGroup(
        children: [],
        triggerChecker: QuestChecker.automate(),
        id: QIDSegGroup.newBotRedDot,
        completeChecker: QuestChecker.custom((_) => false),
      ),
    );
  }
}
