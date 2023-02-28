import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:tuple/tuple.dart';

class CircleNewsDataModel {
  String circleId;
  bool initFinish = false;
  Map data = {};
  List circleNewsList = [];
  Map<String, dynamic> newsCommentQuoteInfo = {};
  Map<String, dynamic> newsPostQuoteInfo = {};
  final List<CircleNewsInfoDataModel> _circleNewsDataModelInfoList = [];

  CircleNewsDataModel(this.circleId);

  Future initFromNet() async {
    initFinish = false;
    final result = await CircleApi.circleNewsList(circleId);
    data = result;
    circleNewsList = result['dynamic'] ?? [];
    _circleNewsDataModelInfoList.clear();
    for (final item in circleNewsList) {
      _circleNewsDataModelInfoList.add(CircleNewsInfoDataModel.fromJson(item));
    }
    newsCommentQuoteInfo = result['comment'] ?? {};
    newsPostQuoteInfo = result['post'] ?? {};
    initFinish = true;
  }

  Future loadMore() async {
    final result = await CircleApi.circleNewsList(circleId,
        lastId: _circleNewsDataModelInfoList.last.reletedId);
    final items = result['dynamic'] ?? [];
    for (final item in items) {
      _circleNewsDataModelInfoList.add(CircleNewsInfoDataModel.fromJson(item));
    }
    circleNewsList.addAll(items);
    newsCommentQuoteInfo.addAll(result['comment'] ?? {});
    newsPostQuoteInfo.addAll(result['post'] ?? {});
  }

  int get circleNewsListCount => _circleNewsDataModelInfoList.length;

  CircleNewsInfoDataModel circleNewsInfoDataModelAtIndex(int index) {
    return _circleNewsDataModelInfoList[index];
  }

  CircleNewsCommentQuoteInfoDataModel
      circleNewsCommentQuoteInfoDataModelWithSrcId(String srcId) {
    if (newsCommentQuoteInfo.containsKey(srcId)) {
      return CircleNewsCommentQuoteInfoDataModel.fromJson(
          newsCommentQuoteInfo[srcId]);
    } else {
      return null;
    }
  }

  CircleNewsPostQuoteInfoDataModel circleNewsPostQuoteInfoDataModelWithSrcId(
      String srcId) {
    if (newsPostQuoteInfo.containsKey(srcId)) {
      return CircleNewsPostQuoteInfoDataModel.fromJson(
          newsPostQuoteInfo[srcId]);
    } else {
      return null;
    }
  }
}

class CircleNewsInfoDataModel {
  String channelId;
  String userId;
  String avatar;
  String nickName;
  String reletedId;
  String content;
  String createdAt;
  String newsType;
  String guildId;
  String objectId;
  String postId;
  String srcId;
  String status;
  String topicId;
  String receiveId;

  CircleNewsInfoDataModel(
      {this.channelId,
      this.userId,
      this.nickName,
      this.avatar,
      this.reletedId,
      this.content,
      this.createdAt,
      this.newsType,
      this.guildId,
      this.objectId,
      this.postId,
      this.srcId,
      this.status,
      this.topicId,
      this.receiveId});

  factory CircleNewsInfoDataModel.fromJson(Map<String, dynamic> json) =>
      CircleNewsInfoDataModel(
        channelId: json['channel_id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        nickName: json['nickname']?.toString() ?? '',
        avatar: json['avatar']?.toString() ?? '',
        reletedId: json['related_id']?.toString() ?? '',
        content: json['content']?.toString() ?? '', //动态
        createdAt: json['created_at']?.toString() ?? '',
        newsType: json['dynamic_type']?.toString() ?? '', //是点赞还是回复
        guildId: json['guild_id']?.toString() ?? '',
        objectId: json['object_id']?.toString() ?? '',
        postId: json['post_id']?.toString() ?? '',
        srcId: json['src_id']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        topicId: json['topic_id']?.toString() ?? '',
        receiveId: json['receive_id']?.toString() ?? '',
      );
}

class CircleNewsCommentQuoteInfoDataModel {
  String postId;
  String level;
  String commentId;
  String channelId;
  String content;
  String createdAt;
  String guildId;
  String quotel1;
  String quotel2;
  String quoteStatus;
  String reaction;
  String topicId;
  String userId;

  CircleNewsCommentQuoteInfoDataModel(
      {this.postId,
      this.level,
      this.commentId,
      this.channelId,
      this.content,
      this.createdAt,
      this.guildId,
      this.quotel1,
      this.quotel2,
      this.quoteStatus,
      this.reaction,
      this.topicId,
      this.userId});

  factory CircleNewsCommentQuoteInfoDataModel.fromJson(
          Map<String, dynamic> json) =>
      CircleNewsCommentQuoteInfoDataModel(
        postId: json['post_id']?.toString() ?? '',
        level: json['level']?.toString() ?? '',
        commentId: json['comment_id']?.toString() ?? '',
        channelId: json['channel_id']?.toString() ?? '', //动态
        content: json['content']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ?? '', //是点赞还是回复
        guildId: json['guild_id']?.toString() ?? '',
        quotel1: json['quote_l1']?.toString() ?? '',
        quotel2: json['quote_l2']?.toString() ?? '',
        quoteStatus: json['quote_status']?.toString() ?? '',
        reaction: json['reaction']?.toString() ?? '',
        topicId: json['topic_id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
      );

  String toPlainText() {
    try {
      if (content.isNotEmpty && content != "null") {
        final document = Document.fromJson(jsonDecode(content));
        return document.toPlainText().replaceAll('\n', '');
      }
    } catch (e) {
      return '';
    }
    return '';
  }

  Tuple2<Operation, String> fetchRichFirstFrame() {
    try {
      final doc = Document.fromJson(jsonDecode(content));
      final deltaList = doc.toDelta().toList();
      String firstFrameUrl = '';
      final firstFrame = deltaList.firstWhere(
        (element) => element.isMedia,
        orElse: () => null,
      );
      if (firstFrame == null ||
          firstFrame.attributes == null ||
          firstFrame.key != Operation.insertKey) firstFrameUrl = '';
      if (firstFrame?.isImage ?? false) {
        firstFrameUrl = RichEditorUtils.getEmbedAttribute(firstFrame, 'source');
      } else if (firstFrame?.isVideo ?? false) {
        firstFrameUrl =
            RichEditorUtils.getEmbedAttribute(firstFrame, 'thumbUrl');
      }
      return Tuple2(firstFrame, firstFrameUrl);
    } catch (e) {
      logger.severe(e);
    }
    return const Tuple2(null, '');
  }
}

class CircleNewsPostQuoteInfoDataModel {
  String postId;
  String channelId;
  String content;
  String contentV2;
  String postType;
  String topicId;
  String title;

  CircleNewsPostQuoteInfoDataModel(
      {this.postId,
      this.channelId,
      this.content,
      this.contentV2,
      this.postType,
      this.topicId,
      this.title});

  factory CircleNewsPostQuoteInfoDataModel.fromJson(
          Map<String, dynamic> json) =>
      CircleNewsPostQuoteInfoDataModel(
        postId: json['post_id']?.toString() ?? '',
        channelId: json['channel_id']?.toString() ?? '', //动态
        content: json['content']?.toString() ?? '',
        contentV2: json['content_v2']?.toString() ?? '',
        postType: json['post_type']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
      );

  String toPlainText() {
    try {
      if (title.isNotEmpty && title != "null") {
        return title;
      }
      final content = fetchContent();
      if (content.isNotEmpty && content != "null") {
        final document = Document.fromJson(jsonDecode(content));
        return document.toContent().replaceAll('\n', '');
      }
    } catch (e) {
      return '';
    }
    return '';
  }

  String postContent() {
    if (postType.isEmpty) {
      return content;
    } else if (postType == CirclePostDataType.article) {
      return contentV2;
    } else {
      return null;
    }
  }

  String fetchContent() {
    String content = RichEditorUtils.defaultDoc.encode();
    if ((postType?.isEmpty ?? true) || postType == "null") {
      content = this.content;
    } else if (postType == CirclePostDataType.article) {
      content = contentV2;
    }
    return content;
  }

  Tuple2<Operation, String> fetchRichFirstFrame() {
    try {
      final content = fetchContent();
      final doc = Document.fromJson(jsonDecode(content));
      final deltaList = doc.toDelta().toList();
      String firstFrameUrl = '';
      final firstFrame = deltaList.firstWhere(
        (element) => element.isMedia,
        orElse: () => null,
      );
      if (firstFrame == null ||
          firstFrame.attributes == null ||
          firstFrame.key != Operation.insertKey) firstFrameUrl = '';

      if (firstFrame?.isImage ?? false) {
        firstFrameUrl = RichEditorUtils.getEmbedAttribute(firstFrame, 'source');
      } else if (firstFrame?.isVideo ?? false) {
        firstFrameUrl =
            RichEditorUtils.getEmbedAttribute(firstFrame, 'thumbUrl');
      }
      return Tuple2(firstFrame, firstFrameUrl);
    } catch (e) {
      logger.severe(e);
    }
    return const Tuple2(null, '');
  }
}
