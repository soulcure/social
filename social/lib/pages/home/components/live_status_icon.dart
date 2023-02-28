import 'package:flutter/material.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/live_status_model.dart';
import 'package:im/themes/const.dart';

import '../model/live_status_model.dart';

class LiveStatusIcon extends StatelessWidget {
  final ChatChannel channel;

  const LiveStatusIcon(this.channel, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GuildTarget target =
        ChatTargetsModel.instance.getChatTarget(channel.guildId);
    final _notifier = LiveStatusManager.instance.getNotifier(target?.id);
    if (target == null || _notifier == null) return sizedBox;

    final hasLiveChannel = target?.hasLiveChannel ?? false;

    return ValueListenableBuilder<GuildLivingStatus>(
      valueListenable: _notifier,
      builder: (context, livingStatus, child) {
        final livingChannels = livingStatus.livingChannels ?? [];
        final ChannelLivingStatus cls = livingChannels.firstWhere(
          (element) => element.channelId == channel.id,
          orElse: () => null,
        );
        final isLiving = (cls?.livingCount ?? 0) > 0;
        return hasLiveChannel && isLiving
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    IconFont.buffChatLive,
                    color: Color(0xFFFF6040),
                    size: 16,
                  ),
                  sizeWidth4,
                ],
              )
            : sizedBox;
      },
    );
  }
}
