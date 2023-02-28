import 'package:get/get.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/api/user_api.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

class ChannelModel {
  final String id;
  final String name;
  final bool isCategory;
  bool selected;
  final bool isPrivate;

  ChannelModel(
      {this.id, this.name, this.isCategory, this.selected, this.isPrivate});
}

class NotificationManagerController extends GetxController {
  List<ChannelModel> channels = [];
  List<String> mutedChannels = [];

  Rx<List<String>> mutedChannelsRequestQueue = Rx<List<String>>(null);

  Worker worker;

  NotificationManagerController() {
    // 读取被屏蔽的频道id
    mutedChannels = Db.userConfigBox.get(UserConfig.mutedChannel);
    // 监听频道的变化
    if (ChatTargetsModel.instance.selectedChatTarget is GuildTarget) {
      updateChannelList(
          (ChatTargetsModel.instance.selectedChatTarget as GuildTarget)
              .channels);
      ChatTargetsModel.instance.selectedChatTarget.addListener(listenChange);
    }
  }

  @override
  void onInit() {
    worker = debounce<void>(mutedChannelsRequestQueue, doRequest,
        time: const Duration(seconds: 1));
    super.onInit();
  }

  @override
  void onClose() {
    worker.dispose();
    mutedChannelsRequestQueue.close();
    ChatTargetsModel.instance.selectedChatTarget.removeListener(listenChange);
    super.onClose();
  }

  Future<void> doRequest(void _) async {
    try {
      final List<String> mutedChannels = mutedChannelsRequestQueue.value;
      await UserApi.updateSetting(mutedChannels: mutedChannels);
      await UserConfig.update(mutedChannels: mutedChannels);
    } catch (e) {
      if (!isClosed)
        updateMutedChannels(
            Db.userConfigBox.get(UserConfig.mutedChannel) ?? []);
    }
  }

  /// 更新屏蔽列表
  void updateMutedChannels(List<String> mutedChannels) {
    this.mutedChannels = mutedChannels;
    channels = channels
        .map((e) => ChannelModel(
            id: e.id,
            name: e.name ?? '',
            isCategory: e.isCategory,
            selected: !mutedChannels.contains(e.id),
            isPrivate: e.isPrivate))
        .toList();
    update();
  }

  /// 更新频道列表
  void updateChannelList(List<ChatChannel> channels) {
    bool isPrivate(ChatChannel channel) {
      final gp = PermissionModel.getPermission(channel.guildId);
      final bool isPrivate = PermissionUtils.isPrivateChannel(gp, channel.id);
      return !isPrivate;
    }

    this.channels = channels
        .where((e) {
          final gp = PermissionModel.getPermission(
              ChatTargetsModel.instance.selectedChatTarget.id);

          // 过滤 非文字频道和非组
          if (e.type != ChatChannelType.guildText &&
              e.type != ChatChannelType.guildCategory) return false;

          // 过滤 空组
          if (e.type == ChatChannelType.guildCategory) {
            return channels.indexWhere((element) =>
                    element.type == ChatChannelType.guildText &&
                    element.parentId == e.id &&
                    PermissionUtils.isChannelVisible(gp, element.id)) >=
                0;
          }

          return PermissionUtils.isChannelVisible(gp, e.id);
        })
        .map((e) => ChannelModel(
            id: e.id,
            name: e.name ?? '',
            isCategory: e.type == ChatChannelType.guildCategory,
            selected: !mutedChannels.contains(e.id),
            isPrivate: isPrivate(e)))
        .toList();
    update();
  }

  /// 更新当个频道状态
  void updateChannel(int index, bool value) {
    final _channels = channels;
    _channels[index].selected = value;
    channels = _channels;
    update();
    updateSetting();
  }

  void listenChange() {
    final channels =
        (ChatTargetsModel.instance.selectedChatTarget as GuildTarget).channels;
    updateChannelList(channels);
  }

  /// 更新数据源
  Future<void> updateSetting() async {
    /// 根据列表ui数据获取最新的屏蔽频道
    List<String> getMutedChannels() {
      final List<String> mutedChannels =
          (Db.userConfigBox.get(UserConfig.mutedChannel) ?? []).toList();
      channels.forEach((element) {
        if (element.selected && mutedChannels.contains(element.id)) {
          mutedChannels.remove(element.id);
        } else if (!element.selected && !mutedChannels.contains(element.id)) {
          mutedChannels.add(element.id);
        }
      });
      return mutedChannels;
    }

    final List<String> mutedChannels = getMutedChannels();
    mutedChannelsRequestQueue.value = mutedChannels;
  }
}
