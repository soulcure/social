import 'package:flutter/widgets.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/live_status_model.dart';

// ignore: avoid_annotating_with_dynamic
void liveStatusHandler(dynamic data) {
  final jsonData = data as Map<String, dynamic> ?? {};
  if (jsonData.isEmpty) return;
  final LiveStatusNotice notice = LiveStatusNotice.fromMap(jsonData);
  debugPrint('live status handler: ${notice.toJson()}');

  final GuildTarget target =
      ChatTargetsModel.instance.getChatTarget(notice.guildId);
  if (target == null) return;

  // final GuildLivingStatus oldStatus = target.livingStatus.value;
  final _notifier = LiveStatusManager.instance.getNotifier(target.id);
  final GuildLivingStatus oldStatus = _notifier?.value;
  if (oldStatus == null) return;

  final ChannelLivingStatus foundCls = oldStatus.livingChannels.firstWhere(
    (element) => element.channelId == notice.channelId,
    orElse: () => null,
  );
  if (foundCls != null) {
    // 如果之前的频道统计数量与收到的通知数量一样，不需要更新UI
    // 此处场景防止频繁刷新直播列表数据时的更新通知
    if (foundCls.livingCount == notice.liveNumber) {
      return;
    }
    oldStatus.livingChannels.remove(foundCls);
  }
  final ChannelLivingStatus cls = ChannelLivingStatus(
    channelId: notice.channelId,
    livingCount: notice.liveNumber,
  );
  _notifier.value = GuildLivingStatus(
    guildId: notice.guildId,
    livingChannels: [...oldStatus.livingChannels, cls],
  );
}

class LiveStatusNotice {
  String guildId;
  String channelId;
  int liveNumber;

  LiveStatusNotice.fromMap(Map<String, dynamic> map) {
    guildId = map['guild_id'];
    channelId = map['channel_id'];
    try {
      liveNumber = int.parse(map['live_number'] ?? '0');
    } catch (e) {
      liveNumber = 0;
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['guildId'] = guildId;
    data['channelId'] = channelId;
    data['liveNumber'] = liveNumber;
    return data;
  }
}
