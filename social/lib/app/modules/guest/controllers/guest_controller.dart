import 'package:get/get.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:pedantic/pedantic.dart';

class GuestController extends GetxController {
  //TODO: Implement GuestController

  final guestFlag = "GUEST";
  RxBool isOpen = false.obs;
  final String guildId;

  GuestController(this.guildId);

  @override
  void onInit() {
    super.onInit();

    final gt = ChatTargetsModel.instance.getChatTarget(guildId) as GuildTarget;

    isOpen.value = gt.featureList.contains(guestFlag);
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {}

  Future<void> changeState() async {
    final bool tempIsOpen = !isOpen.value;

    final status = tempIsOpen ? 1 : 0;

    try {
      await GuildApi.setGuildFeatures(guildId,
          featureList: [guestFlag], status: status);

      await updateGuildTargetInfo();
      isOpen.value = tempIsOpen;
    } catch (e, s) {
      logger.severe('', e, s);
    }
  }

  /// 更新服务台信息(游客信息更新)
  Future<void> updateGuildTargetInfo() async {
    ///刷新服务台数据
    final selectGt =
        ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    final guildInfo =
        await GuildApi.getGuildInfo(guildId: guildId, userId: Global.user.id);
    final GuildTarget tempGuildTarget = GuildTarget.fromJson(guildInfo);

    selectGt.featureList = List.from(tempGuildTarget.featureList ?? []);
    final json = selectGt.toJson();
    unawaited(Db.guildBox.put(selectGt.id, json));
    for (final c in selectGt.channels) unawaited(Db.channelBox.put(c.id, c));

    ///修改内存里的GuildTarget的 userPending
    final dbTarget = ChatTargetsModel.instance.chatTargets
        .firstWhere((e) => e.id == selectGt.id);
    if (dbTarget != null && dbTarget is GuildTarget) {
      dbTarget.featureList = tempGuildTarget.featureList;
    }
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    selectGt.notifyListeners();
  }
}
