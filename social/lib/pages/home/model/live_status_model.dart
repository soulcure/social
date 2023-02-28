import 'package:flutter/cupertino.dart';
import 'package:im/common/extension/string_extension.dart';

class LiveStatusManager {
  LiveStatusManager._();

  static final LiveStatusManager _instance = LiveStatusManager._();

  static LiveStatusManager get instance => _instance;

  /// 缓存服务器直播统计状态监听对象s
  /// K - 服务器id
  final _notifiers = <String, ValueNotifier<GuildLivingStatus>>{};

  /// 缓存某个服务器是否成功获取过一次频道列表的直播状态统计
  final _netPullStatusCache = <String>[];

  /// 缓存是否在频道内点击过频道直播数的提示UI
  final hintTappedCache = ValueNotifier(<String>[]);

  ValueNotifier<GuildLivingStatus> getNotifier(String guildId) {
    return guildId.noValue ? null : _notifiers[guildId];
  }

  /// 获取指定频道内的直播数量
  int getChannelLivingCount(String guildId, String channelId) {
    final gls = getNotifier(guildId);
    if (gls == null) return 0;
    final livingChannels = gls.value?.livingChannels ?? [];
    if (livingChannels == null || livingChannels.isEmpty) return 0;
    final cls = livingChannels.firstWhere(
      (c) => c.channelId == channelId,
      orElse: () => null,
    );

    return cls?.livingCount ?? 0;
  }

  void addNotifier(String guildId) {
    if (guildId.noValue) return;
    _notifiers.putIfAbsent(
      guildId,
      () => ValueNotifier(GuildLivingStatus(guildId: guildId)),
    );
  }

  bool hasNetPullCached(String guildId) =>
      _netPullStatusCache.contains(guildId);

  void updateNotifier(String guildId, GuildLivingStatus value) {
    if (guildId.noValue) return;
    if (!_netPullStatusCache.contains(guildId))
      _netPullStatusCache.add(guildId);
    _notifiers[guildId]?.value = value;
  }

  void removeNotifier(String guildId) {
    if (guildId.noValue) return;
    _notifiers.remove(guildId);
    _netPullStatusCache.remove(guildId);
  }

  // 清除缓存
  void clear() {
    _notifiers.clear();
    _netPullStatusCache.clear();
    hintTappedCache.value = <String>[];
  }
}

class ChannelLivingStatus {
  String channelId;
  String channelName;
  int livingCount;

  ChannelLivingStatus({this.channelId, this.channelName, this.livingCount});

  ChannelLivingStatus.fromMap(Map<String, dynamic> map) {
    channelId = map['channel_id'];
    channelName = map['channel_name'];
    livingCount = map['living_count'];
  }

  @override
  String toString() {
    return '{channelId:$channelId, channelName:$channelName, livingCount:$livingCount}';
  }
}

class GuildLivingStatus {
  String guildId;
  List<ChannelLivingStatus> livingChannels;

  GuildLivingStatus({this.guildId, this.livingChannels = const []});

  GuildLivingStatus.fromMap(Map<String, dynamic> map) {
    guildId = map['guild_id'];
    livingChannels = [
      ...(map['living_channels'] as List ?? [])
          .map((e) => ChannelLivingStatus.fromMap(e))
    ];
  }

  @override
  String toString() {
    return 'GuildLivingStatus {guildId:$guildId, livingChannels:$livingChannels}';
  }
}
