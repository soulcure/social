import 'package:flutter/cupertino.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/circle_detail/entity/circle_detail_message.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/global.dart';
import 'package:im/pages/guild_setting/circle/entry/circle_entry_controller.dart';
import 'package:im/pages/home/model/text_channel_event.dart';

///圈子入口信息的缓存
final Map<String, CircleEntryBean> circleEntryCache = {};

/// 圈子入口信息更新
// ignore: type_annotate_public_apis
void circleEntryHandler(data) {
  if (data == null) return;
  try {
    final guildId = data["guild_id"] as String;
    if (guildId.noValue) return;
    if (data["records"] == null && data["new_post_total"] == null) return;

    final map = data["records"] as Map;
    //最新动态有更新
    if (map != null && map.isNotEmpty) {
      final records = Map<String, dynamic>.from(map);
      final newBean = CircleEntryBean.fromJson(records);
      circleEntryCache[guildId] = newBean;
    } else {
      circleEntryCache[guildId] = CircleEntryBean();
    }

    //新动态数量有更新
    if (data["new_post_total"] != null) {
      final newTotal = data["new_post_total"] as int;
      if (newTotal >= 0) circleEntryCache[guildId].newPostTotal = newTotal;
    }

    // print(
    //     'getChat circleEntryHandler：$guildId, ${circleEntryCache[guildId]?.title}, ${circleEntryCache[guildId]?.newPostTotal}');

    final c = CircleEntryController.to();
    if (c != null && c.guildId == guildId) c.updateData(guildId);
  } catch (_) {
    // print('getChat circleEntryHandler error: $e');
  }
}

/// 圈子动态回复的推送
// ignore: type_annotate_public_apis
void circlePostHandler(data) {
  if (data == null) return;
  try {
    final postId = data["post_id"] as String;
    if (postId.noValue) return;
    final controller = CircleDetailController.to(postId: postId);
    if (controller == null || controller.postId != postId) return;

    final map = Map<String, dynamic>.from(data);
    final contentType = (map['content_type'] ?? '') as String;
    map['topic_id'] = controller.topicId;

    final message =
        CommentMessageEntity.fromJson(map, postTopicId: controller.topicId);
    if (contentType == 'comment_del') {
      controller.removeCommentMessage(message, fromWs: true);
    } else if (contentType == 'reaction') {
      final name = (map['content'] ?? '') as String;
      final count = (map['count'] ?? 1) as int;
      controller.addReaction(message.messageIdBigInt, name,
          message.userId == Global.user.id, count);
    } else if (contentType == 'reaction_del') {
      final name = (map['content'] ?? '') as String;
      final count = (map['count'] ?? 0) as int;
      controller.delReaction(message.messageIdBigInt, name,
          message.userId == Global.user.id, count);
    } else if (contentType.noValue ||
        contentType == 'richText' ||
        contentType == 'image') {
      debugPrint('getChat add：${message.messageIdBigInt}, $message');
      controller.eventStream.add(NewMessageEvent(message));
      Future.delayed(const Duration(milliseconds: 50)).then((_) {
        controller.addCommentMessage(message, isUpdate: true, fromWs: true);
      });
    }
  } catch (_) {
    debugPrint('getChat circlePostHandler error: $_');
  }
}
