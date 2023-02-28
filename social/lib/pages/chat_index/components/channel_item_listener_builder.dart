import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/chat_index/components/ui_channel_item.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/widgets/segment_list/segment_member_list_service.dart';

class ChannelItemListenerBuilder extends StatelessWidget {
  final ChatChannel channel;
  final GuildTarget gt;

  const ChannelItemListenerBuilder(this.channel, this.gt);

  @override
  Widget build(BuildContext context) {
    //只有语音频道需要此监听
    if (channel.type == ChatChannelType.guildVoice) {
      return ValueListenableBuilder(
          valueListenable: GlobalState.mediaChannel,
          builder: (context, c, child) {
            return ValueListenableBuilder<Box<ChatChannel>>(
              valueListenable: Db.channelBox.listenable(keys: [channel.id]),
              builder: (c, box, child) {
                final listDM = SegmentMemberListService.to.getDataModel(
                    channel.guildId, channel.id, channel.type,
                    autoCreate: channel.active, initWithPersistenceData: false);
                if (listDM == null || channel.active != true) {
                  return createBuilder();
                } else {
                  return ObxValue<RxInt>(
                    (data) {
                      return createBuilder(key: ValueKey(data.value));
                    },
                    listDM.notify,
                  );
                }
              },
            );
          });
    } else {
      return createBuilder();
    }
  }

  ValueListenableBuilder<Box<int>> createBuilder({ValueKey key}) {
    return ValueListenableBuilder<Box<int>>(
      key: key,
      valueListenable: Db.numUnrealOfChannelBox.listenable(keys: [channel.id]),
      builder: (context, box, child) {
        return Visibility(
          visible: !shouldCollapse(gt, channel),
          child: child,
        );
      },
      child: UIChannelItem(channel),
    );
  }

  /// 是否应该折叠指定频道，排除所有不折叠因素后，剩下的结果就是折叠
  bool shouldCollapse(GuildTarget guild, ChatChannel channel) {
    // 没有分类的不折叠
    if (channel.parentId.noValue) return false;

    // 有未读数的不折叠
    if (ChannelUtil.instance.getUnread(channel.id) > 0) return false;
    // 当前选中频道不折叠
    if (GlobalState.selectedChannel.value == channel) return false;
    // 正在语音不折叠
    if (UIChannelItem.isBoldVoiceChannel(channel)) return false;

    final category = guild.channels
        .firstWhere((e) => e.id == channel.parentId, orElse: () => null);
    // 找不到分类，不折叠
    if (category == null) return false;
    // 分类展开时，全都不折叠
    if (category.expanded) return false;

    //有人的语音频道不隐藏
    if (channel.type == ChatChannelType.guildVoice) {
      final listDM = SegmentMemberListService.to.getDataModel(
          channel.guildId, channel.id, channel.type,
          autoCreate: channel.active, initWithPersistenceData: false);
      if (listDM != null && channel.active && listDM.memberCount > 0) {
        return false;
      }
    }

    return true;
  }
}
