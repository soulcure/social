import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/db.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';
import 'package:im/utils/utils.dart';

import '../global.dart';
import 'avatar.dart';

export 'user_info/realtime_nick_name.dart';

class RealtimeAvatar extends StatelessWidget {
  final String userId;
  final double size;
  final bool tapToShowUserInfo;
  final BaseCacheManager cacheManager;
  final bool showBorder;
  final EnterType enterType;
  final bool useTexture;
  final String guildId;
  final String channelId;

  /// - 是否显示nft标识
  final bool showNftFlag;

  const RealtimeAvatar({
    this.userId,
    this.size = 30,
    this.tapToShowUserInfo = false,
    this.cacheManager,
    this.showBorder,
    this.enterType = EnterType.fromDefault,
    this.useTexture = true,
    this.guildId,
    this.channelId,
    this.showNftFlag = true,
  });

  @override
  Widget build(BuildContext context) {
    if (userId == null) return const SizedBox();

    var child = UserInfo.consume(userId, builder: (context, userInfo, _) {
      return isNotNullAndEmpty(userInfo.avatarNft)
          ? SizedBox(
              width: size,
              height: size,
              child: Stack(
                children: [
                  Avatar(
                    url: userInfo.avatarNft,
                    radius: size / 2,
                    cacheManager: cacheManager,
                    showBorder: showBorder,
                    useTexture: useTexture,
                  ),
                  if (showNftFlag)
                    // 宽大于40，除以3，使icon小一点
                    _buildDaoFlag(size > 40 ? size / 3 : size / 2.5),
                ],
              ),
            )
          : Avatar(
              url: userInfo.avatar,
              radius: size / 2,
              cacheManager: cacheManager,
              showBorder: showBorder,
              useTexture: useTexture,
            );
    });

    if (tapToShowUserInfo) {
      child = GestureDetector(
        onTap: () {
          showUserInfoPopUp(Global.navigatorKey.currentContext,
              userId: userId,
              guildId:
                  guildId ?? ChatTargetsModel.instance.selectedChatTarget?.id,
              channelId: channelId ?? GlobalState.selectedChannel.value?.id,
              showRemoveFromGuild: true,
              enterType: enterType);
        },
        child: child,
      );
    }

    return child;
  }

  /// - 构建数字藏品标识,头像/标识 = 3
  Align _buildDaoFlag(double size) {
    return Align(
      alignment: Alignment.bottomRight,
      child: SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(1.5),
            child: ClipOval(
              child: Container(
                color: Colors.blue,
                child: Icon(
                  IconFont.buffDaoFlag,
                  size: size - 6,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RealtimeChannelInfo extends StatelessWidget {
  final String channelId;

  final Widget Function(BuildContext, ChatChannel) builder;

  const RealtimeChannelInfo(this.channelId, {this.builder});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<ChatChannel>>(
      valueListenable: Db.channelBox.listenable(keys: [channelId]),
      builder: (c, box, child) {
        final channel = box.get(channelId);
        return builder(context, channel);
      },
    );
  }
}

class RealtimeChannelName extends StatelessWidget {
  final String channelId;
  final String prefix;
  final String suffix;
  final TextStyle style;

  const RealtimeChannelName(this.channelId,
      {this.style, this.prefix = '', this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<ChatChannel>>(
      valueListenable: Db.channelBox.listenable(keys: [channelId]),
      builder: (c, box, child) {
        final channel = box.get(channelId);
        final channelName =
            "$prefix${channel?.name ?? "尚未加入该频道".tr}$suffix".breakWord;
        return Text(
          channelName,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
