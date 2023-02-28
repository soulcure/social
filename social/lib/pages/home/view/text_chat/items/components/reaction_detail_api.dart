import 'package:dio/dio.dart';
import 'package:im/core/http_middleware/http.dart';

import '../../../../../../loggers.dart';
import 'reaction_detail_bean.dart';

class ReactionData {
  List<String> lists;
  int count;

  ReactionData(this.lists, this.count);
}

class ReactionDetailApi {
  static const String ReactionDetailUrl = '/api/msg/getReaction';

  static const String ReactionDetailSingle = '/api/reaction/getEmojiList';

  static Future<List<ReactionDetailBean>> getReactionDetail(
      String messageId, String channelId,
      {CancelToken token}) async {
    try {
      final res = await Http.request(ReactionDetailUrl,
          data: {'message_id': messageId, 'channel_id': channelId},
          cancelToken: token);
      return res
          .map((e) => ReactionDetailBean.fromMap(e))
          .cast<ReactionDetailBean>()
          .toList();
    } catch (e) {
      print(e);
    }
    return null;
  }

  static Future<ReactionData> getReactionDetailSingle(
      String messageId, String channelId, String emoji,
      {CancelToken token, String size = '100', String after}) async {
    final data = {
      'message_id': messageId,
      'channel_id': channelId,
      'emoji': Uri.encodeComponent(emoji),
      'size': size,
    };
    if (after != null && after.isNotEmpty) {
      data['after'] = after;
    }
    final res = await Http.request(
      ReactionDetailSingle,
      data: data,
      cancelToken: token,
      showDefaultErrorToast: true,
    ).catchError((e) {
      logger.severe("getReactionDetailSingle e=$e");
      return null;
    });

    if (res is Map) {
      final int count = int.tryParse(res["count"]);
      final List resList = res["lists"];
      final List<String> lists =
          resList.map((e) => BigInt.from(e).toString()).cast<String>().toList();

      return ReactionData(lists, count);
    }
    return null;
  }

  /// * 获取圈子回复表态单个表情的列表
  static Future<ReactionData> getCircleReactionDetailSingle(
      String messageId, String emoji,
      {CancelToken token, String size = '100', String listId}) async {
    final data = {
      'comment_id': messageId,
      'emoji': Uri.encodeComponent(emoji),
      'size': size,
    };
    if (listId != null && listId.isNotEmpty) {
      data['list_id'] = listId;
    }
    final res = await Http.request(
      '/api/circlePostCommentReaction/list',
      data: data,
      cancelToken: token,
      showDefaultErrorToast: true,
    ).catchError((e) {
      logger.severe("getCircleReactionDetailSingle e=$e");
      return null;
    });

    if (res is Map) {
      final int count = res["count"] ?? 0;
      final List resList = res["lists"] ?? [];
      final List<String> lists = resList?.cast<String>()?.toList();

      return ReactionData(lists, count);
    }
    return null;
  }
}
