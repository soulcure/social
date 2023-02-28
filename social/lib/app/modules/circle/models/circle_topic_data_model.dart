import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';

class CircleTopicDataModel {
  String topicId;
  String guildId;
  String channelId;
  String topicName;
  CircleTopicType type;
  int showType;
  int listDisplay;
  List<PermissionOverwrite> overwrite;

  CircleTopicDataModel({
    this.topicId = '',
    this.guildId = '',
    this.channelId = '',
    this.topicName = '',
    this.type,
    this.showType = 0, //浏览样式设置， 0：默认（普通列表），  1：双卡（卡片样式列表）
    this.listDisplay = 0, // 圈子频道显示， 0：关闭（默认），  1：显示
    this.overwrite,
  });

  factory CircleTopicDataModel.fromJson(Map<String, dynamic> json) {
    final topicId = (json['topic_id'] ?? '').toString();
    final channelId = (json['channel_id'] ?? '').toString();
    final permissionOverwrites = json['overwrite'] as List;
    final overwrites = permissionOverwrites?.map((e) {
      return PermissionOverwrite.fromJson(e);
    })?.toList();
    return CircleTopicDataModel(
      topicId: topicId,
      guildId: (json['guild_id'] ?? '').toString(),
      channelId: channelId,
      topicName:
          changeIfAll(topicId, channelId, (json['name'] ?? '').toString()),
      type: toTopicType(json['type'] ?? 1, topicId),
      showType: json['show_type'] ?? 0,
      listDisplay: json['list_display'] ?? 0,
      overwrite: overwrites,
    );
  }

  /// 话题名称：全部(topicId == channelId) 改为 最新
  /// 服务端不方便改变，客户端做修改
  static String changeIfAll(String topicId, String channelId, String name) {
    return topicId.hasValue && topicId == channelId ? '最新' : name;
  }
}

CircleTopicType toTopicType(int type, String topicId) {
  switch (type) {
    case 5:
      return CircleTopicType.all;
    case 11:
      if (topicId == circleSubscriptionId) return CircleTopicType.subscribe;
      return CircleTopicType.common;
    default:
      return CircleTopicType.unknown;
  }
}

/// * 圈子"订阅"话题的ID
String circleSubscriptionId = '1';

/// * 圈子话题的类型
enum CircleTopicType {
  /// 最新：表示全部，默认就有，无法删除
  all,

  /// 订阅：默认就有，无法删除
  subscribe,

  /// 普通话题：用户可以新增和删除
  common,

  /// 未知
  unknown,
}
