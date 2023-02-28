import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/pages/guild_setting/circle/component/circle_user_avatar.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/utils.dart';

import 'circle_user_nickname.dart';

class CircleUserInfoRow extends StatelessWidget {
  const CircleUserInfoRow({
    Key key,
    @required this.userId,
    @required this.createdAt,
    @required this.updatedAt,
    this.avatarUrl = "",
    this.nickName = "",
    this.avatarAndNameSpace = 12,
    this.nameAndTimeSpace = 3,
    this.guildId,
  }) : super(key: key);

  final int createdAt;
  final int updatedAt;
  final String userId;
  final String avatarUrl;
  final String nickName;
  final double avatarAndNameSpace;
  final double nameAndTimeSpace;
  final String guildId;

  @override
  Widget build(BuildContext context) {
    return _buildLoginUserInfoRow(context);
  }

  Widget _buildLoginUserInfoRow(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 47,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleUserAvatar(
            userId,
            36,
            avatarUrl: avatarUrl,
            tapToShowUserInfo: true,
            cacheManager: CircleCachedManager.instance,
            guildId: guildId,
          ),
          SizedBox(width: avatarAndNameSpace),
          Flexible(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleUserNickName(
                  userId,
                  TextStyle(
                      color: theme.textTheme.bodyText2.color,
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w500),
                  preferentialRemark: true,
                  guildId: guildId,
                  nickName: nickName),
              SizedBox(height: nameAndTimeSpace),
              Text(
                '${formatDate2Str(DateTime.fromMillisecondsSinceEpoch(updatedAt).toLocal())}  ${createdAt != updatedAt ? '更新动态'.tr : '发布动态'.tr}',
                style: TextStyle(
                    fontSize: 12, height: 1.25, color: theme.disabledColor),
              ),
              const SizedBox(
                height: 1,
              ),
            ],
          ))
        ],
      ),
    );
  }
}
