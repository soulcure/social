import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as cm;
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';

class CircleUserAvatar extends StatelessWidget {
  final String userId;
  final String avatarUrl;
  final double size;
  final bool tapToShowUserInfo;
  final cm.BaseCacheManager cacheManager;
  final EnterType enterType;
  final String guildId;

  const CircleUserAvatar(
    this.userId,
    this.size, {
    this.avatarUrl = "",
    this.tapToShowUserInfo = false,
    this.cacheManager,
    this.enterType = EnterType.fromCircle,
    this.guildId,
  });

  @override
  Widget build(BuildContext context) {
    return RealtimeAvatar(
      userId: userId,
      size: size,
      tapToShowUserInfo: tapToShowUserInfo,
      cacheManager: cacheManager,
      enterType: enterType,
      guildId: guildId,
    );
  }
}
