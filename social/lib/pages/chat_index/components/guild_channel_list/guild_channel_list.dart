import 'package:flutter/material.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

abstract class GuildChannelListContent {
  /// 构建某个频道
  Widget buildChannelItem(GuildTarget gt, ChatChannel channel,
      BuildContext context, bool hasManagePermission);

  /// 构建某个分类的频道
  Widget buildCategoryItem(GuildTarget gt, ChatChannel channel);
}
