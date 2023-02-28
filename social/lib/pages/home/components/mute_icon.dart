import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:im/api/entity/user_config.dart';
import 'package:im/db/db.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';

class MuteIcon extends StatelessWidget {
  final String channelId;

  const MuteIcon(this.channelId, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
        valueListenable:
            Db.userConfigBox.listenable(keys: [UserConfig.mutedChannel]),
        builder: (context, box, w) {
          final List mutedChannels = box.get(UserConfig.mutedChannel);
          final isMuted = mutedChannels?.contains(channelId) == true;
          return isMuted
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 使用svg在web上会闪动
                    Icon(
                      IconFont.buffChannelForbidNotice,
                      color: const Color(0xff8F959E).withOpacity(0.5),
                      size: 12,
                    ),
                    sizeWidth4
                  ],
                )
              : sizedBox;
        });
  }
}
