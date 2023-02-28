import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/bot_market/bot_utils.dart';
import 'package:im/pages/bot_market/model/bot_market_controller.dart';
import 'package:im/pages/bot_market/model/channel_cmds_model.dart';
import 'package:im/pages/bot_market/model/robot_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';

class ChannelCommandSettingPageController extends GetxController
    with GetTickerProviderStateMixin, StateMixin {
  // 服务器添加的机器人列表
  List<String> addedRobots;

  // 当前设置的频道
  ChatChannel channel;

  TabController tabController;

  /// 已添加指令列表
  List<BotCommandItem> addedCommandItems = [];

  /// 保存机器人future
  final Map<String, Future<List<BotCommandItem>>> _futureMap = {};

  List<AppBarActionModelInterface> actionModels = [];

  ChannelCommandSettingPageController(this.channel) {
    actionModels.add(AppBarIconActionModel(
      IconFont.buffHelpCircle,
      actionBlock: _showTip,
    ));
  }

  @override
  void onInit() {
    initPage().then((value) {
      final isFirstSetBotCommand =
          SpService.to.getBool(SP.isFirstSetBotCommand);
      if (isFirstSetBotCommand != true) {
        _showTip();
        SpService.to.setBool(SP.isFirstSetBotCommand, true);
      }
    });
    super.onInit();
  }

  Future<void> initPage() async {
    change(null, status: RxStatus.loading());
    tabController?.dispose();
    return Future.wait([_initAddedCmds(), initializeAddedRobots()])
        .then((value) {
      tabController = TabController(length: addedRobots.length, vsync: this);
      if (addedRobots.isNotEmpty) {
        // 默认选中第一个机器人
        onSelectBot(addedRobots[0]);
        // 清空已添加机器人缓存的命令
        addedRobots.forEach(RobotModel.instance.refreshRobot);
      }
      change(null, status: RxStatus.success());
    }).catchError((e) {
      logger.severe('频道快捷指令初始化错误', e);
      final errorMsg =
          Http.isNetworkError(e) ? networkErrorText : '数据异常，请重试'.tr;
      change(e, status: RxStatus.error(errorMsg));
    });
  }

  @override
  void onClose() {
    tabController?.dispose();
    _futureMap.clear();
    super.onClose();
  }

  // 初始化已添加的指令
  Future<void> _initAddedCmds() async {
    final res = await BotUtils.getChannelCmds(channel.guildId, channel.id);
    addedCommandItems = res;
  }

  Future<List<BotCommandItem>> getFutureByBotId(String botId) {
    return _futureMap[botId] ??= fetchCommands(botId).catchError((e) {
      _futureMap.remove(botId);
      throw e;
    });
  }

  // 获取某个机器人的所有指令名称list
  List<String> _getBotAddedCommandNames(String botId) {
    return addedCommandItems
        .where((element) => element.botId == botId)
        .map((e) => e.command)
        .toList();
  }

  // 获取当前选中机器人的指令
  Future<List<BotCommandItem>> fetchCommands(String botId) async {
    final res = await RobotModel.instance.getCommands(botId);
    return res
        ?.where(
          // 频道快捷指令只能添加机器人的公开指令或管理员指令
          (command) => command.visibleLevel == 0 || command.isAdminVisible,
        )
        ?.toList();
  }

  // 初始化
  Future<void> initializeAddedRobots() async {
    addedRobots = (await getAddedRobots()).map((u) => u.userId).toList();
  }

  // 切换选中的机器人
  void onSelectBot(String botId) {
    tabController.animateTo(addedRobots.indexOf(botId));
  }

  // 删除失效的的机器人
  Future removeInvalidRobot() async {
    final guildId = channel.guildId;
    final botId = addedRobots[tabController.index];
    await BotUtils.removeBot(guildId, botId);
    // 从添加的机器人中移除
    addedRobots.remove(botId);
    bool containInvalid = false;
    // 本地缓存删除失效机器人的快捷指令
    channel.botSettingList.forEach((element) {
      final kv = element.entries.first;
      if (kv.key == botId) {
        channel.botSettingList.remove(element);
        containInvalid = true;
      }
    });
    if (containInvalid) {
      // 发起网络请求，删除失效机器人的频道快捷指令
      await ChannelCmdsModel.instance.removeChannelCommands(
        channel.id,
        channel.guildId,
        botId,
      );
    }
    await initPage();
  }

  // 添加命令到频道，返回所有已添加的指令名集合
  Future<void> addCommand(BotCommandItem command) async {
    if (_isCommandAdded(command)) return;
    await _setChannelCommand(command.botId,
        _getBotAddedCommandNames(command.botId)..add(command.command));
    addedCommandItems.add(command);
    update();
  }

  // 移除此快捷指令
  Future<void> removeCommand(BotCommandItem command) async {
    if (!_isCommandAdded(command)) return;
    await _setChannelCommand(command.botId,
        _getBotAddedCommandNames(command.botId)..remove(command.command));
    addedCommandItems.removeWhere((element) =>
        element.botId == command.botId && element.command == command.command);
    update();
  }

  // 发送网络请求，用来添加或删除指令
  Future _setChannelCommand(String botId, List<String> commands) {
    if (commands == null) return Future.value();
    return ChannelCmdsModel.instance.setChannelCommands(
      [channel.id],
      channel.guildId,
      botId,
      commands,
    );
  }

  // 获取指令状态
  AddedStatus getCommandStatus(BotCommandItem cmd) {
    final isAdded = addedCommandItems.firstWhere(
            (element) =>
                element.botId == cmd.botId && element.command == cmd.command,
            orElse: () => null) !=
        null;
    return isAdded ? AddedStatus.Added : AddedStatus.UnAdded;
  }

  // 指令是否已被添加
  bool _isCommandAdded(BotCommandItem command) {
    final cmd = addedCommandItems.firstWhere((element) => element == command,
        orElse: () => null);
    return cmd != null;
  }

  void _showTip() {
    showBottomModal(Get.context, backgroundColor: Get.theme.backgroundColor,
        builder: (c, s) {
      return Center(
        child: Column(children: [
          sizeHeight32,
          Text('频道快捷指令'.tr,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          sizeHeight12,
          Text('快捷指令将会添加到频道输入框上方'.tr,
              style: TextStyle(
                  fontSize: 14, color: appThemeData.textTheme.headline2.color)),
          sizeHeight24,
          Image.asset(
            'assets/images/command_shortcut_screen.png',
            width: 251,
            height: 128,
          ),
          sizeHeight32,
          FadeButton(
            width: 240,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: appThemeData.dividerColor,
            ),
            onTap: Get.back,
            child: Text(
              '知道了'.tr,
              style: TextStyle(
                fontSize: 16,
                color: primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            height: 32 + Get.mediaQuery.viewPadding.bottom,
          ),
        ]),
      );
    });
  }
}
