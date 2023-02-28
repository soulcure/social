import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/bot_api.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/db/db.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/pages/bot_market/bot_utils.dart';
import 'package:im/pages/bot_market/model/bot_market_controller.dart';
import 'package:im/pages/bot_market/model/robot_model.dart';
import 'package:im/pages/bot_market/widget/bot_required_permissions.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:quest_system/internal/trigger/custom_trigger.dart';
import 'package:quest_system/quest_system.dart';

class BotDetailPageController extends GetxController {
  final String guildId;
  final String botId;

  /// 监听器：绑定列表滚动监听
  final ScrollController scrollCtl = ScrollController();

  /// 开始展示标题拦头像和按钮的临界值
  final double _showBotAvatarStartTipping = 25;

  /// 结束展示标题拦头像和按钮的临界值
  final double _showBotAvatarEndTipping = 90;

  /// 标题栏和按钮展示区间值
  final double _showBotAvatarSectionValue = 65;

  Future<BotInfo> future;
  bool addedValue = false;

  /// 监听器：标题栏头像与按钮的透明值
  double appBarElementAlpha = 0;

  /// 标题栏：右侧按钮
  List<AppBarActionModelInterface> actionModels = [];

  BotInfo bot;

  BotDetailPageController({@required this.guildId, @required this.botId});

  @override
  void onInit() {
    if (Get.isRegistered<BotMarketPageController>()) {
      addedValue =
          Get.find<BotMarketPageController>().receiveBots().contains(botId);
    }
    listenScroll();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      CustomTrigger.instance.dispatch(QuestTriggerData(
          condition:
              QuestCondition(BotUtils.getNewBotQuestSegments(guildId, botId))));
    });

    super.onInit();
  }

  void listenScroll() {
    /// 实现滚动监听：计算滚动区间的透明值：0 ～ 1
    /// - 通过计算最大距离和最小距离之间的 与 实时滚动值的 百分比
    scrollCtl.addListener(() {
      /// 非滚动区间特殊判断：
      //  - 如果小于区间值，在滚动特别快的情况下，计算会没法跟上，需要设置按钮的透明值为0
      if (scrollCtl.offset < _showBotAvatarStartTipping) {
        if (appBarElementAlpha != 0) {
          appBarElementAlpha = 0;
          actionModels.forEach((element) {
            element.alpha = appBarElementAlpha;
          });
          update();
        }
        return;
      }

      //  - 如果大于区间值，在滚动特别快的情况下，计算会没法跟上，需要设置按钮的透明值为1
      if (scrollCtl.offset > _showBotAvatarEndTipping) {
        if (appBarElementAlpha != 1) {
          appBarElementAlpha = 1;
          actionModels.forEach((element) {
            element.alpha = appBarElementAlpha;
          });
          update();
        }
        return;
      }

      /// 计算透明值：0～1
      appBarElementAlpha = (scrollCtl.offset - _showBotAvatarStartTipping) /
          _showBotAvatarSectionValue;

      /// 更新按钮透明度
      actionModels.forEach((element) {
        element.alpha = appBarElementAlpha;
      });
      update();
    });
  }

  /// - 获取机器人信息
  Future<void> fetchBotInfo() async {
    bot = await RobotModel.instance.getRobot(botId);
  }

  bool get isAdded {
    if (Get.isRegistered<BotMarketPageController>()) {
      return Get.find<BotMarketPageController>().isRobotAdded(botId);
    } else {
      return false;
    }
  }

  String get guildNickname {
    final botInfo = Db.userInfoBox.get(botId);
    return botInfo?.guildNickname(guildId);
  }

  Future<void> removeBot() async {
    if (Get.isRegistered<BotMarketPageController>()) {
      await Get.find<BotMarketPageController>()
          .removeRobot(botId, fromDetail: true);
      Get.back();
    }
  }

  Future<bool> onAdd(BotInfo bot) async {
    updateActionModels(true);
    final model = Get.find<BotMarketPageController>();
    final res = await model
        .addRobot(
          UserInfo(
            userId: bot.botId,
            avatar: bot.botAvatar,
            nickname: bot.botName,
          ),
          markAsNew: false,
          permissions: bot.permissions,
          fromDetail: true,
        )
        .whenComplete(
          () => updateActionModels(false),
        );
    update();
    return res;
  }

  Future<bool> onUnAdded(BotInfo bot) async {
    updateActionModels(true);
    final model = Get.find<BotMarketPageController>();
    final res = await model
        .removeRobot(
          bot.botId,
          fromDetail: true,
        )
        .whenComplete(() => updateActionModels(false));
    update();
    return res;
  }

  Future<void> toggleAdd(bool v) async {
    BotMarketPageController c;
    if (Get.isRegistered<BotMarketPageController>()) {
      c = Get.find<BotMarketPageController>();
    }
    if (c == null) return;
    final orgValue = addedValue;
    final String guildId = c.guildId;
    try {
      addedValue = v;
      await BotApi.botReceive(guildId, botId, v == true ? 1 : 0);
      if (addedValue == true) {
        c.addReceiveBot(botId);
      } else {
        c.removeReceiveBot(botId);
      }
    } catch (e) {
      addedValue = orgValue;
    }
    update();
  }

  /// 更新右侧按钮状态
  /// - 只有在显示的时候才执行改方法，避免不必要的更新
  void updateActionModels(bool isLoading) {
    if (appBarElementAlpha > 0) {
      return;
    }
    actionModels.forEach((element) {
      if (element is AppBarTextPrimaryActionModel) {
        element.isLoading = isLoading;
      } else if (element is AppBarTextLightActionModel) {
        element.isLoading = isLoading;
      }
    });
  }

  void showRequiredPermissions(BotInfo bot) {
    showBottomModal(
      Get.context,
      backgroundColor: Get.theme.backgroundColor,
      builder: (c, s) => BotRequiredPermissions(permissions: bot.permissions),
      footerBuilder: (context, state) => Padding(
        padding: EdgeInsets.fromLTRB(
            32, 12, 32, 12 + MediaQuery.of(context).padding.bottom),
        child: FadeButton(
          height: 44,
          // borderRadius: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFFF5F6FA),
          ),
          // backgroundColor:
          onTap: Get.back,
          // tapDownBackgroundColor: const Color(0xFFF5F6FA).withOpacity(0.7),
          child: Text('我知道了',
              style: Get.textTheme.bodyText2
                  .copyWith(fontSize: 16, color: primaryColor)),
        ),
      ),
    );
    DLogManager.getInstance().customEvent(
      actionEventId: "guild_bot_operate",
      actionEventSubId: "click_view_entrance",
      actionEventSubParam: 'bot_permission',
      extJson: {
        "guild_id": guildId,
        "bot_user_id": botId,
        "status": isAdded ? 1 : 0,
      },
    );
  }
}
