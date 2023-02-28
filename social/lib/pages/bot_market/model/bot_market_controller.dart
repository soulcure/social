import 'dart:async';
import 'dart:collection';
import 'package:get/get.dart';
import 'package:im/api/bot_api.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/db/db.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/bot_market/bot_utils.dart';
import 'package:im/pages/bot_market/model/robot_model.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/member_list/model/member_list_model.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/widgets/toast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class BotMarketPageController extends GetxController with StateMixin {
  double updateContent = -1;
  double updateIdAddedBot = 0;
  double updateIdBotList = 1;
  int page = 1;
  int pageSize = 10;
  final RefreshController refreshController = RefreshController();
  StreamSubscription _subscription;

  @override
  void onInit() {
    initPage();
    super.onInit();
  }

  // 已添加的机器人
  List<UserInfo> _addedBots = [];

  UnmodifiableListView<UserInfo> get addedBots =>
      UnmodifiableListView(_addedBots?.toList() ?? []);

  // 列表里的机器人
  final List<BotInfo> _allBots = [];

  UnmodifiableListView<BotInfo> get allRobots =>
      UnmodifiableListView(_allBots?.toList() ?? []);

  Future<void> fetchAddedBots() async {
    RobotModel.instance.reset();
    _addedBots = [...await getAddedRobots()];
    update([updateIdAddedBot, updateIdBotList]);
  }

  Future<void> initPage() async {
    page = 1;
    change(null, status: RxStatus.loading());
    await Future.wait([
      fetchAddedBots(),
      fetchBots(),
    ]).then((value) {
      change(null, status: RxStatus.success());
    }).catchError((e, s) {
      logger.severe('机器人市场错误', e, s);
      final errorMsg =
          Http.isNetworkError(e) ? networkErrorText : '数据异常，请重试'.tr;
      change(e, status: RxStatus.error(errorMsg));
    });
  }

  Future<void> fetchBots() async {
    await BotApi.getBots(page: page, pageSize: pageSize, guildId: guildId)
        .then((res) {
      _allBots.addAll(res ?? []);
      page++;
      update([updateIdBotList]);
      refreshController.loadComplete();
      if ((res ?? []).length < pageSize) {
        refreshController.loadNoData();
      }
    }).catchError((_) {
      refreshController.loadFailed();
    });
  }

  void onLoading() {
    fetchBots();
  }

  String get guildId {
    return (ChatTargetsModel.instance.selectedChatTarget as GuildTarget).id;
  }

  List<String> receiveBots() {
    return (ChatTargetsModel.instance.selectedChatTarget as GuildTarget)
            .receiveBots ??
        [];
  }

  void addReceiveBot(String botId) {
    final guild = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    guild.addReceiveBot(botId);
  }

  void removeReceiveBot(String botId) {
    final guild = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    guild.removeReceiveBot(botId);
  }

  /// 添加机器人到服务器
  /// markAsNew，默认需要显示新标识红点，在机器人详情页添加机器人不需要显示红点
  /// fromDetail，是否由详情页调用
  Future<bool> addRobot(
    UserInfo bot, {
    bool markAsNew = true,
    int permissions = 0,
    bool fromDetail = false,
  }) async {
    if (isRobotAdded(bot.userId)) return false;
    await BotApi.joinGuild(guildId, bot.userId, permissions, '0')
        .catchError((e) {
      BotUtils.dLogAddEvent(guildId, bot.userId,
          fromDetail: fromDetail, success: false);
      throw e;
    });
    Toast.iconToast(icon: ToastIcon.success, label: '添加成功'.tr);
    BotUtils.dLogAddEvent(guildId, bot.userId, fromDetail: fromDetail);
    await RobotModel.instance.addGuildRobot(guildId, bot.userId);
    if (markAsNew) {
      BotUtils.addBotRedDotQuest(guildId: guildId, botId: bot.userId);
    }
    if (!isRobotAdded(bot.userId)) {
      _addedBots.add(bot);
      update([updateIdAddedBot, updateIdBotList]);
    }
    return true;
  }

  /// 展示移除机器确认弹窗，如果用户确认删除，则返回true，否则返回false
  Future<bool> showRemoveRobotDialog() async {
    final isRemove = await showConfirmDialog(
      title: "确定要移除机器人？移除后将无法在服务器内使用".tr,
      confirmText: '确定移除'.tr,
      confirmStyle: Get.textTheme.bodyText2.copyWith(color: CustomColor.red),
    );
    return isRemove == true;
  }

  /// 剔出已添加的机器人
  Future<bool> removeRobot(String botId, {bool fromDetail = false}) async {
    if (!isRobotAdded(botId)) return false;
    try {
      await BotUtils.removeBot(guildId, botId);
      _addedBots.removeWhere((e) => e.userId == botId);
      removeReceiveBot(botId);
      unawaited(MemberListModel.instance.remove(botId));
      update([updateIdBotList, updateIdAddedBot]);
      BotUtils.dLogDelEvent(
        guildId,
        botId,
        botRemovePosition: fromDetail
            ? BotRemovePosition.bot_detail
            : BotRemovePosition.bot_market,
      );
      final user = Db.userInfoBox.get(botId);
      if (user != null) {
        user.removeGuildNickName(guildId);
      }
    } catch (e) {
      BotUtils.dLogDelEvent(
        guildId,
        botId,
        success: false,
        botRemovePosition: fromDetail
            ? BotRemovePosition.bot_detail
            : BotRemovePosition.bot_market,
      );
      return false;
    }
    return true;
  }

  // 机器人是否已添加
  bool isRobotAdded(String robotId) {
    return _addedBots.indexWhere((e) => e.userId == robotId) > -1;
  }

  @override
  void dispose() {
    refreshController.dispose();
    _subscription.cancel();
    super.dispose();
  }
}

Future<List<UserInfo>> getAddedRobots() async {
  final List<UserInfo> bots = await BotApi.getAddedBots(
    guildId: (ChatTargetsModel.instance.selectedChatTarget as GuildTarget).id,
    limit: 100,
  );
  return bots;
}
