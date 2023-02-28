import 'dart:async';
import 'dart:collection';

import 'package:get/get.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

import '../../../../global.dart';

class WelcomeSettingController extends GetxController {
  static const toSelectedChannelList = "toSelectedChannelList";
  static const welcomePage = "welcomePage";

  final String guildId;

  WelcomeSettingController(this.guildId);

  StreamSubscription _permissionChangeStreamSubscription;

  @override
  void onInit() {
    super.onInit();

    _loadData();

    _permissionChangeStreamSubscription =
        PermissionModel.allChangeStream.listen((value) {
      // 自己权限变化导致的UI更新已经处理。这里需要处理因比较权限导致的UI更新。
      onChannelChanged();
    });

    ChatTargetsModel.instance.selectedChatTarget.addListener(onChannelChanged);
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    // Db.channelBox.listenable().removeListener(onChannelChanged);
    _permissionChangeStreamSubscription?.cancel();
    ChatTargetsModel.instance.selectedChatTarget
        .removeListener(onChannelChanged);
    super.onClose();
  }

  bool _isOpen = false;

  bool get isOpen => _isOpen;

  final List<ChatChannel> _allChannels = [];

  UnmodifiableListView<ChatChannel> get allChannels =>
      UnmodifiableListView(_allChannels);

  final List<ChatChannel> _selectedChannels = [];

  UnmodifiableListView<ChatChannel> get selectedChannels =>
      UnmodifiableListView(_selectedChannels);

  final List<ChatChannel> _serverSelectedChannels = [];

  UnmodifiableListView<ChatChannel> get serverSelectedChannels =>
      UnmodifiableListView(_serverSelectedChannels);

  bool isChannelSelected(ChatChannel channel) {
    if (selectedChannels.contains(channel)) {
      return true;
    }
    return false;
  }

  String selectChannel(ChatChannel channel, bool select) {
    if (!selectedChannels.contains(channel) && select) {
      if (selectedChannels.length >= 5) {
        return "最多选择5个频道".tr;
      } else {
        _selectedChannels.add(channel);
        update([WelcomeSettingController.toSelectedChannelList]);
      }
    } else if (selectedChannels.contains(channel) && !select) {
      _selectedChannels.remove(channel);
      update([WelcomeSettingController.toSelectedChannelList]);
    }
    return "".tr;
  }

  List<ChatChannel> _guildChannels(GuildTarget guildTarget) {
    // 各种类型的频道都可以设置
    // 私密频道不可以设置，自己不可见频道可以设置
    final gp = PermissionModel.getPermission(guildTarget.id);
    return guildTarget.channels.where((c) {
      if (c.type == ChatChannelType.guildText ||
          c.type == ChatChannelType.guildVoice ||
          c.type == ChatChannelType.guildVideo ||
          c.type == ChatChannelType.guildLive ||
          c.type == ChatChannelType.guildLink) {
        if (PermissionUtils.isPrivateChannel(gp, c.id)) return false;
        return true;
      } else {
        return false;
      }
    }).toList();
  }

  // 初始化数据
  void _loadData({bool isFirstLoad = true}) {
    final GuildTarget guildTarget = ChatTargetsModel.instance.chatTargets
        .firstWhere((e) => e.id == guildId, orElse: () => null) as GuildTarget;
    // 频道数据
    _allChannels.clear();
    _allChannels.addAll(_guildChannels(guildTarget));

    // 已选择的频道
    List<String> selectedIds;
    if (isFirstLoad) {
      // 首次从设置中获取已选择的频道
      selectedIds = guildTarget.welcome;
    } else {
      // 非首次更新 _selectedChannels 中的数据
      selectedIds = _selectedChannels.map((e) => e.id).toList();
    }

    _selectedChannels.clear();
    _serverSelectedChannels.clear();
    // 会过滤掉已设置的，不在频道列表中的频道
    // 会过滤掉后来又转成私密的频道
    final gp = PermissionModel.getPermission(guildTarget.id);
    _allChannels.forEach((channel) {
      final isPrivate = PermissionUtils.isPrivateChannel(gp, channel.id);
      if (selectedIds.contains(channel.id) && !isPrivate) {
        _selectedChannels.add(channel);
      }
      if (guildTarget.welcome.contains(channel.id) && !isPrivate) {
        _serverSelectedChannels.add(channel);
      }
    });

    _isOpen = guildTarget.isWelcomeOn ?? false;

    update();
  }

  void toggleSelectChannel() {
    // 点击选择频道，清除已选的数据，赋值上服务器的数据
    _selectedChannels.clear();
    _selectedChannels.addAll(_serverSelectedChannels);
  }

  void _reloadData() {
    _loadData(isFirstLoad: false);
  }

  void onChannelChanged() {
    _reloadData();
    update([toSelectedChannelList, welcomePage]);
  }

  Future _saveToServer({bool isOpen, List<String> welcomeChannels}) async {
    await GuildApi.updateGuildInfo(guildId, Global.user.id,
        isWelcomeOn: isOpen, welcome: welcomeChannels);
    final GuildTarget target = ChatTargetsModel.instance.chatTargets
        .firstWhere((e) => e.id == guildId, orElse: () => null) as GuildTarget;
    target.updateInfo(welcome: welcomeChannels, isWelcomeOn: _isOpen);
  }

  Future onSwitch(bool value) async {
    _isOpen = value;
    await _saveToServer(isOpen: value);
    update([WelcomeSettingController.welcomePage]);
  }

  Future onSaved() async {
    final welcomeChannels = _selectedChannels.map((e) => e.id).toList();
    if (welcomeChannels.isEmpty) return "请选择至少一个频道".tr;
    _isOpen = true;
    // 目前还没有isOpen为false的情况会调用到这里
    await _saveToServer(isOpen: true, welcomeChannels: welcomeChannels);
    Get.back();
    update([WelcomeSettingController.welcomePage]);
    return "";
  }

// 监听频道信息变化，监听频道列表变化，刷新UI
}
