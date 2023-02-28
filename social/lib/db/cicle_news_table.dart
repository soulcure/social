import 'dart:collection';

import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/json/text_chat_json.dart';

import 'async_db/async_db.dart';

///圈子动态-消息表
class CircleNewsTable {
  static const table = "CircleNews";

  static const columnMessageId = "message_id";
  static const columnChannelId = "channel_id";
  static const columnGuildId = "guild_id";
  static const columnUserId = "user_id";
  static const columnPostId = "post_id";
  static const columnCommentId = "comment_id";
  static const columnQuote1 = "quote_l1";
  static const columnCircleType = "circle_type";
  static const columnAtMe = "at_me";

  ///0 正常(默认); 1 失效
  static const columnStatus = "status";

  static Future<void> createTable(AsyncDB db) async {
    ///如果存在先删除
    await db.execute("DROP TABLE IF EXISTS $table", isAsync: false);
    await db.execute('''
        CREATE TABLE $table (
          $columnMessageId INTEGER PRIMARY KEY,
          $columnChannelId TEXT,
          $columnUserId TEXT,
          $columnGuildId TEXT,
          $columnPostId TEXT,
          $columnCommentId INTEGER,
          $columnQuote1 INTEGER,
          $columnCircleType TEXT,
          $columnAtMe INTEGER,
          $columnStatus INTEGER
          )
        ''', isAsync: false);

    ///创建索引
    await db.execute(
        "CREATE INDEX circle_news_channel_index on"
        " $table ($columnChannelId)",
        isAsync: false);
  }

  static Future checkTable() async {
    await Db.db.select("select * from $table limit 1");
  }

  ///批量插入
  static Future<void> appendList(List<MessageEntity> list) async {
    if (list == null || list.isEmpty) return;
    final List<Map<String, Object>> mapList = [];
    for (final message in list) {
      final isDelete = await _deleteByMessage(message);
      if (!isDelete) mapList.add(message.toCircleNewsJson());
    }
    if (mapList.isNotEmpty) await Db.db.insertArray(table, mapList);
    // debugPrint('getChat table-circleNews appendList length: ${list.length}');
  }

  /// * 单条插入
  static Future<void> append(MessageEntity message) async {
    final isDelete = await _deleteByMessage(message);
    if (!isDelete) await Db.db.insert(table, message.toCircleNewsJson());
  }

  /// * 删除某些记录：删除回复或取消动态点赞时
  static Future<bool> _deleteByMessage(MessageEntity message) async {
    final content = message.content as CirclePostNewsEntity;
    final circleType = getCircleType(content.circleType);
    if (circleType == CirclePostNewsType.commentDel) {
      //删除回复时，把该回复的所有消息删除
      await Db.db.delete(
        "delete from $table where $columnCommentId = ${content.commentId}",
      );
      return true;
    } else if (circleType == CirclePostNewsType.postLikeCancel) {
      //取消点赞时，把原来点赞记录删除
      await Db.db.delete(
        "delete from $table where $columnPostId = '${content.postId}' "
        "and $columnUserId = '${message.userId}' "
        "and $columnCircleType = 'post_like'",
      );
      return true;
    }
    return false;
  }

  /// * 批量删除记录
  static Future<void> batchDelete(String channelId, {String commentId}) async {
    String sql = "delete from $table where $columnChannelId = '$channelId'";
    if (commentId != null) sql += " and $columnCommentId <= $commentId";
    await Db.db.delete(sql);
  }

  //查询某个圈子频道数量(测试用)
  // static Future<void> testQuery(String channelId) async {
  //   final res =
  //       await Db.db.query(table, where: "$columnChannelId = '$channelId' ");
  //   // print('getChat testQuery: $channelId - ${res?.length}');
  // }

  /// * 查询圈子频道的所有未读消息
  /// * firstId: 下版本可以去掉这个参数 - 因为圈子消息记录已读后，会直接删除
  static Future<CirclePostNewsPositionObj> queryCircleNews(String channelId,
      {BigInt firstId}) async {
    final obj = CirclePostNewsPositionObj();
    String where = "$columnChannelId = '$channelId' and $columnStatus = 0"
        " and $columnUserId != '${Global.user.id}'";
    if (firstId != null) where += " and $columnMessageId >= $firstId";

    final res = await Db.db
        .query(table, where: where, orderBy: '$columnMessageId DESC');
    if (res.isEmpty) return obj;

    CirclePostNewsType cType;
    BigInt commentId;
    res.forEach((e) {
      final type = e['circle_type'];
      cType = getCircleType(type);
      commentId = BigInt.from(e[columnCommentId] ?? 0);

      if (cType == CirclePostNewsType.postDel) {
        obj.postIsDel = true;
      } else if (cType == CirclePostNewsType.postAt ||
          cType == CirclePostNewsType.postUp) {
        // obj.toComment = false;
      } else if (cType == CirclePostNewsType.commentAt) {
        obj.atMap[commentId] ??= e[columnUserId];
        obj.newsMap[commentId] ??= e[columnUserId];
      } else if (cType == CirclePostNewsType.postComment ||
          cType == CirclePostNewsType.commentComment) {
        obj.newsMap[commentId] ??= e[columnUserId];
      }
    });
    return obj;
  }

  /// * 查询圈子频道的所有未读艾特消息
  static Future<CirclePostNewsPositionObj> queryAtCircleNews(String channelId,
      {BigInt firstId}) async {
    final obj = CirclePostNewsPositionObj();
    String where = "$columnChannelId = '$channelId' and $columnStatus = 0"
        " and $columnUserId != '${Global.user.id}'";
    if (firstId != null) where += " and $columnMessageId >= $firstId";
    final res = await Db.db
        .query(table, where: where, orderBy: '$columnMessageId DESC');
    if (res.isEmpty) return obj;

    CirclePostNewsType cType;
    BigInt commentId;
    res.forEach((e) {
      final type = e[columnCircleType];
      cType = getCircleType(type);
      commentId = BigInt.from(e[columnCommentId] ?? 0);
      if (cType == CirclePostNewsType.postDel) {
        obj.postIsDel = true;
      } else if (cType == CirclePostNewsType.commentAt) {
        obj.atMap[commentId] ??= e[columnUserId];
        obj.newsMap[commentId] ??= e[columnUserId];
      }
    });
    return obj;
  }

  ///查询某条回复的圈子消息
  static Future<MessageEntity> getMessage(String commentId) async {
    if (commentId.noValue) return null;

    final res = await Db.db.query(table,
        where: "$columnCommentId = $commentId"
            " and ($columnCircleType = 'post_comment'"
            " or $columnCircleType = 'comment_comment'"
            " or $columnCircleType = 'comment_comment_at'"
            " or $columnCircleType = 'post_comment_at')");
    if (res.isEmpty) return null;
    final map = res.single;
    final c = CirclePostNewsEntity.fromJson(map);
    return MessageEntity(null, map[columnChannelId], map[columnUserId],
        map[columnGuildId], null, c,
        messageId: map[columnMessageId]?.toString());
  }

  ///根据type得到CirclePostNewsType
  static CirclePostNewsType getCircleType(String type) {
    CirclePostNewsType result;
    switch (type) {
      case "post_like":
        result = CirclePostNewsType.postLike;
        break;
      case "post_like_cancel":
        result = CirclePostNewsType.postLikeCancel;
        break;
      case "post_comment":
        result = CirclePostNewsType.postComment;
        break;
      case "post_at":
        result = CirclePostNewsType.postAt;
        break;
      case "post_up":
        result = CirclePostNewsType.postUp;
        break;
      case "post_del":
        result = CirclePostNewsType.postDel;
        break;
      case "post_comment_at":
        result = CirclePostNewsType.commentAt;
        break;
      case "comment_comment":
        result = CirclePostNewsType.commentComment;
        break;
      case "comment_comment_at":
        result = CirclePostNewsType.commentAt;
        break;
      case "comment_like":
        result = CirclePostNewsType.commentLike;
        break;
      case "comment_del":
        result = CirclePostNewsType.commentDel;
        break;
    }
    return result;
  }

  ///是否更新未读数
  static bool isUpdateUnread(CirclePostNewsType type) {
    return type != null &&
        type != CirclePostNewsType.commentDel &&
        type != CirclePostNewsType.postLikeCancel &&
        type != CirclePostNewsType.postDel;
  }

  ///是否更新lastDesc
  static bool isUpdateLastDesc(CirclePostNewsType type) {
    return type != null &&
        type != CirclePostNewsType.postLikeCancel &&
        type != CirclePostNewsType.postDel;
  }
}

///圈子消息定位的数据对象
class CirclePostNewsPositionObj {
  ///动态点赞的总数
  int totalLike = 0;

  ///进入详情页时，是否定位到回复
  bool toComment;

  ///动态是否已删除
  bool postIsDel = false;

  ///艾特消息Map：<commentId，userId>
  SplayTreeMap<BigInt, String> atMap = SplayTreeMap();

  ///是否有未读的艾特消息
  bool get hasAt => atMap.isNotEmpty;

  ///第一条未读艾特
  BigInt get firstAtKey => atMap.firstKey();

  ///最后一条未读艾特
  BigInt get lastAt => atMap.lastKey();

  ///未读消息Map：key为commentId
  SplayTreeMap<BigInt, String> newsMap = SplayTreeMap();

  ///是否有未读的消息
  bool get hasNews => newsMap.isNotEmpty;

  ///最后一条未读消息
  BigInt get lastNewsKey => newsMap.lastKey();

  ///是否有未读消息
  bool get hasUnRead => hasAt || hasNews;

  ///最新的那条未读消息的类型
  String lastCircleType;
}

class CirclePostNewsPositionItem {
  ///用户ID
  String userId;

  CirclePostNewsPositionItem({this.userId});
}

///圈子消息的操作类型
enum CirclePostNewsType {
  postLike, //动态点赞
  postLikeCancel, //取消动态点赞
  postComment, //普通回复
  postAt, //动态艾特
  postUp, //动态编辑
  postDel, //动态删除
  commentComment, //回复的回复
  commentLike, //回复点赞
  commentAt, //回复艾特
  commentDel, //回复被删除
}
