import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/json/unsupported_entity.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:tuple/tuple.dart';

/// * 圈子回复消息
class CommentMessageEntity<T extends MessageContentEntity>
    extends MessageEntity {
  /// * 圈子topic的ID
  String topicId;

  /// * 动态ID
  String postId;

  /// * 回复ID，会赋值给消息的messageId
  String commentId;

  /// * 回复的类型，用来兼容旧版
  /// * 新版为'richText' 'image'
  CommentType contentType;

  /// * 发送图片时使用的两个Document
  Tuple2<Document, Document> tuple2;

  CommentMessageEntity({
    this.topicId,
    this.postId,
    this.commentId,
    this.contentType,
    String userId,
    String guildId,
    T content,
    DateTime time,
    List<dynamic> reactions,
    List<dynamic> mentionList,
    String quoteL1,
    String quoteL2,
  }) : super(null, topicId, userId, guildId, time, content,
            messageId: commentId,
            localStatus: MessageLocalStatus.normal,
            type: ChatChannelType.guildCircle,
            channelType: ChatChannelType.guildCircle,
            reactions: reactions,
            postId: postId,
            quoteL1: quoteL1,
            quoteL2: quoteL2) {
    if (mentionList != null && mentionList.isNotEmpty) {
      mentions = mentionList.map((e) => e['user_id']?.toString()).toList();
    }
  }

  /// * postTopicId: 编辑动态时，如果修改圈子话题topic，
  /// 服务端没有同步改回复的topicId，客户端优先使用动态的topicId
  factory CommentMessageEntity.fromJson(Map<String, dynamic> srcJson,
      {String postTopicId}) {
    CommentMessageEntity entity;
    try {
      MessageContentEntity contentEntity;
      CommentType type;
      final cType = srcJson['content_type'] as String;
      if (cType == null || cType.isEmpty || cType == 'richText') {
        type = CommentType.richText;
      } else if (cType == 'image') {
        type = CommentType.image;
      }
      type ??= CommentType.unKnown;
      // 测试时发现有脏数据,缺少user_id,加个判断
      final userId = (srcJson['user_id'] ?? '') as String;
      if (userId.hasValue) {
        /// 兼容：先判断是否不识别的类型
        if (type != CommentType.unKnown) {
          try {
            final contentV2 = (srcJson['content_v2'] ?? '') as String;
            final contentJson =
                contentV2.trim().hasValue ? contentV2 : srcJson['content'];
            final contentList =
                (jsonDecode(contentJson) as List).cast<Map<String, dynamic>>();
            contentEntity =
                RichTextEntity(document: Document.fromJson(contentList));
          } catch (e) {
            logger.severe("CommentMessageEntity contentFromJson error", e);
          }
        }
      } else {
        return null;
      }
      contentEntity ??= UnSupportedEntity(unSupportContent: {});
      contentEntity.messageState = Rx(MessageState.sent);
      final q1 = srcJson['quote_l1'] as String;
      final q2 = srcJson['quote_l2'] as String;
      entity = CommentMessageEntity(
        topicId: postTopicId ?? srcJson['topic_id'],
        postId: srcJson['post_id'],
        commentId: srcJson['comment_id'],
        guildId: srcJson['guild_id'],
        userId: srcJson['user_id'],
        time: timeFromJson(srcJson),
        content: contentEntity,
        contentType: type,
        reactions: srcJson['comment_reaction'],
        mentionList: srcJson['mentions'],
        quoteL1: q1.noValue || q1 == '0' ? null : q1,
        quoteL2: q2.noValue || q2 == '0' ? null : q2,
      );
      // entity.quoteL1 = '354518882804826112';
    } catch (e) {
      logger.severe("CommentMessageEntity fromJson error", e);
    }
    return entity;
  }

  /// * 重新设置回复ID和消息ID
  void setCommentId(String id) {
    if (id.noValue) return;
    commentId = id;
    messageId = id;
    messageIdBigInt = BigInt.parse(id);
    reactionModel.messageId = id;
  }
}

/// * 圈子回复类型
enum CommentType {
  richText,
  image,
  unKnown,
}

DateTime timeFromJson(Map<String, dynamic> srcJson) {
  final time = srcJson['created_at'];
  if (time is int && time > 0) {
    return DateTime.fromMillisecondsSinceEpoch(time);
  } else {
    ///如果消息时间非法，使用comment_id字段解析消息时间
    return msgIdStr2DateTime(srcJson['comment_id'].toString());
  }
}
