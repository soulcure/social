import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/image_operator_collection/image_builder.dart';
import 'package:im/utils/image_operator_collection/image_widget.dart';

class RoleBadge extends StatefulWidget {
  final String userId;
  final String guildId;
  final String channelId;

  RoleBadge(this.userId, this.guildId, this.channelId)

      /// 不加这个 key IM 列表可能会报错，右侧列表灰屏
      /// 重现路径：
      /// 测试环境，内部开发者频道，进入 pin 列表，点击第一条 pin 消息（一张图片），跳转到 IM 后，往下往出现
      : super(key: ValueKey('$userId$guildId$channelId'));

  @override
  _RoleBadgeState createState() => _RoleBadgeState();
}

class _RoleBadgeState extends State<RoleBadge> {
  String _key;

  Widget getRoleBadge(String img) {
    if (img.noValue) return sizedBox;
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: ImageWidget.fromCachedNet(CachedImageBuilder(
        imageUrl: img,
        height: 20,
      )),
    );
  }

  @override
  void initState() {
    if (widget.channelId.hasValue) {
      final channel = Db.channelBox.get(widget.channelId);
      if (channel == null) return;
      // 是否是部落频道
      final isGroupDmChannel = channel.type == ChatChannelType.group_dm;
      _key = isGroupDmChannel
          ? '${widget.channelId}-${widget.userId}'
          : '${widget.guildId}-${widget.userId}';
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_key.noValue) return const SizedBox();
    return ValueListenableBuilder(
        valueListenable: Db.creditsBox.listenable(keys: [_key]),
        builder: (context, box, _) {
          final Map map = box.get(_key);
          if (map == null) return sizedBox;
          final img = map['url'];
          return getRoleBadge(img);
        });
  }
}
