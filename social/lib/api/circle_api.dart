import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle_detail/entity/circle_detail_message.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/httpweb.dart';
import 'package:tuple/tuple.dart';

class CircleApi {
  static Future circlePostInfo(String guildId) async {
    final res = kIsWeb
        ? await HttpWeb.request("/api/circle/guildInfo", data: {
            "guild_id": guildId,
          })
        : await Http.request("/api/circle/guildInfo", data: {
            "guild_id": guildId,
          });
    return res;
  }

  static Future circleInfo(String guildId, String channelId,
      {String sortType, String orderType = ""}) async {
    final res = await Http.request("/api/circle/info", data: {
      "guild_id": guildId,
      "channel_id": channelId,
      "sort_type": sortType,
      "ordering": orderType
    });
    return res;
  }

  ///圈子通知列表
  static Future circleNewsList(String channelId,
      {String lastId = "", String size = "20"}) async {
    final res = await Http.request("/api/circleUserDynamic/lists", data: {
      "channel_id": channelId,
      "last_id": lastId,
      "size": size,
    });
    return res;
  }

  ///圈子通知清零
  static Future circleUpdateNewsReadState(
    String channelId,
    String relatedId,
  ) async {
    final res = await Http.request("/api/circleUserDynamic/up",
        data: {"channel_id": channelId, "related_id": relatedId, "status": 1});
    return res;
  }

  ///圈子通知数量
  static Future circleUnreadNewsCount(String channelId) async {
    final res = await Http.request("/api/circleUserDynamic/msgTotal",
        data: {"channel_id": channelId});
    return res;
  }

  ///圈子动态 关注/取消关注
  static Future circleFollow(
      String channelId, String postId, String flag) async {
    final res = await Http.request("/api/circle/follow",
        data: {"channel_id": channelId, "post_id": postId, "flag": flag},
        showDefaultErrorToast: true);
    return res;
  }

  static Future circlePostIsExsit(
      String channelId, String postId, String topicId) async {
    final res = await Http.request("/api/circlePost/check", data: {
      "channel_id": channelId,
      "topic_id": topicId,
      "post_id": postId
    });
    return res;
  }

  static Future circleDelReaction(String channelId, String postId,
      String topicId, String delType, String reactionId, String commentId,
      {bool showToast = true}) async {
    final res = await Http.request("/api/circlePost/delReaction",
        data: {
          "channel_id": channelId,
          "topic_id": topicId,
          "post_id": postId,
          "t": delType,
          "id": reactionId,
          "comment_id": commentId
        },
        showDefaultErrorToast: showToast);
    return res;
  }

  static Future circleAddReaction(String channelId, String postId,
      String topicId, String addType, String commentId,
      {bool showToast = true}) async {
    final res = await Http.request("/api/circlePost/addReaction",
        data: {
          "channel_id": channelId,
          "topic_id": topicId,
          "post_id": postId,
          "t": addType,
          "comment_id": commentId
        },
        showDefaultErrorToast: showToast);
    return res;
  }

  static Future circlePostList(String guildId, String channelId, String topicId,
      String size, String listId,
      {String sortType,
      String order = "",
      String hasVideo,
      String createAt}) async {
    final res = await Http.request("/api/circle/postList", data: {
      "guild_id": guildId,
      "channel_id": channelId,
      "topic_id": topicId,
      "size": size,
      "list_id": listId,
      "sort_type": sortType,
      "ordering": order,
      "has_video": hasVideo,
      "create_at": createAt
    });
    return res;
  }

  static Future circleFollowPostList(String guildId, String channelId,
      String topicId, String size, String listId,
      {String sortType,
      String order = "",
      String hasVideo,
      String createAt}) async {
    final res = await Http.request("/api/circle/followList", data: {
      "guild_id": guildId,
      "channel_id": channelId,
      "has_video": hasVideo,
      "page": listId,
      "page_size": size,
      "create_at": createAt
    });
    return res;
  }

  ///圈子搜索接口
  static Future searchCircle(String guildId, String channelId, String size,
      String lastId, String searchKey,
      {CancelToken cancelToken}) async {
    final res = await Http.request(
      "/api/circle/postList",
      data: {
        "guild_id": guildId,
        "channel_id": channelId,
        "size": size,
        "last_post_id": lastId,
        "wd": searchKey,
      },
      cancelToken: cancelToken,
    );
    return res;
  }

  ///删除动态
  static Future circlePostDelete(
      String postId, String channelId, String topicId,
      {String reason, bool showToast = true}) async {
    final res = await Http.request("/api/circle/postDelete",
        data: {
          "post_id": postId,
          "channel_id": channelId,
          "topic_id": topicId,
          if (reason != null) "reason": reason,
        },
        showDefaultErrorToast: showToast);
    return res;
  }

  static Future circlePostDetail(String postId,
      {bool showErrorToast = false}) async {
    final res = await Http.request("/api/circlePost/detail",
        data: {
          "post_id": postId,
          // "channel_id": channelId,
          // "topic_id": topicId,
        },
        showDefaultErrorToast: showErrorToast);
    return res;
  }

  static Future circleReactionList(String postId, String listId, String size,
      {bool isDesc = true}) async {
    final res = await Http.request("/api/circlePost/reactionList", data: {
      "post_id": postId,
      "list_id": listId,
      "size": size,
      "order": isDesc ? 'desc' : 'asc',
    });
    return res;
  }

  static Future createCircle(
      String guildId, String channelId, String topicId, String postId,
      {String title = '',
      String postType = '',
      String content = '[{"insert":"当前版本暂不支持此信息类型"}]',
      String contentV2 = '[{"insert":"\n"}]',
      List<String> mentions = const [],
      String fileId = '',
      String hash}) async {
    mentions ??= [];
    final data = {
      "guild_id": guildId,
      "post_type": postType,
      "channel_id": channelId,
      "topic_id": topicId,
      "content": content,
      "content_v2": contentV2,
      "title": title,
      "post_id": postId,
      "mentions": mentions,
      "file_id": fileId,
    };
    if (hash.isNotEmpty) {
      data['c_hash'] = hash;
    }

    final res = await Http.request("/api/circle/postUpdate",
        showDefaultErrorToast: true, data: data);
    return res;
  }

  static Future createComment(String guildId, String channelId, String topicId,
      String content, String postId, String quote1, String quote2,
      {List<String> mentions = const [],
      String contentV2,
      String contentType}) async {
    mentions ??= [];
    final res = await Http.request("/api/circlePostComment/comment",
        showDefaultErrorToast: true,
        data: {
          "guild_id": guildId,
          "channel_id": channelId,
          "topic_id": topicId,
          "content": content,
          "content_v2": contentV2,
          "content_type": contentType,
          "post_id": postId,
          "quote_l1": quote1,
          "quote_l2": quote2,
          "mentions": mentions,
        });
    return res;
  }

  static Future circleDynamicPinList(String guildId, String channelId,
      {bool showToast = true}) async {
    final res = await Http.request("/api/circlePost/topList",
        showDefaultErrorToast: showToast,
        data: {"channel_id": channelId, "guild_id": guildId});
    return res;
  }

  static Future pinCircleDynamic(String channelId, String topicId,
      String postId, String title, String typeId,
      {bool showToast = true}) async {
    final res = await Http.request("/api/circlePost/top",
        showDefaultErrorToast: showToast,
        data: {
          "channel_id": channelId,
          "topic_id": topicId,
          "post_id": postId,
          "title": title,
          "type_id": typeId,
          "status": "1"
        });
    return res;
  }

  static Future unpinCircleDynamic(
      String channelId, String topicId, String postId,
      {bool showToast = true}) async {
    final res = await Http.request("/api/circlePost/top",
        showDefaultErrorToast: showToast,
        data: {
          "channel_id": channelId,
          "topic_id": topicId,
          "post_id": postId,
          "status": "0"
        });
    return res;
  }

  //圈子动态详情页，回复列表
  //behavior: true 向后，false 向前
  // static Future<dynamic> getCommentList(
  //     String channelId, String topicId, String postId, int size, String listId,
  //     {bool showToast = true, bool behavior = true}) async {
  //   final res = await Http.request("/api/circlePostComment/Lists",
  //       showDefaultErrorToast: showToast,
  //       data: {
  //         "channel_id": channelId,
  //         "topic_id": topicId,
  //         "post_id": postId,
  //         "list_id": listId,
  //         "size": '$size',
  //         "behavior": behavior ? 'after' : 'before',
  //       });
  //   return res;
  // }

  /// * 圈子动态详情页，回复列表v2版本
  /// * behavior: true 向后 (id小到大)；false, 向前
  /// * commentId: 起始回复ID
  static Future<List<CommentMessageEntity>> getCommentListV2(
      String channelId, String postId, int size,
      {String commentId,
      String topicId,
      bool showToast = true,
      bool behavior = true}) async {
    final res = await Http.request("/api/v2/circlePostComment/Lists",
        showDefaultErrorToast: showToast,
        data: {
          "channel_id": channelId,
          "post_id": postId,
          "comment_id": commentId,
          "size": '$size',
          "behavior": behavior ? 'after' : 'before',
        });
    if (res == null || res['lists'] == null) return [];
    final lists = res['lists'] as List<dynamic>;
    return lists
        .map((e) => CommentMessageEntity.fromJson(e, postTopicId: topicId))
        .where((e) => e != null && e.isContent)
        .toList();
  }

  /// * 圈子动态详情页 - 跳转到某条回复 v2版本
  static Future<Tuple3<List<CommentMessageEntity>, int, int>>
      getAroundCommentListV2(String channelId, String postId, String commentId,
          {String topicId, int size = 25, bool showToast = true}) async {
    final res = await Http.request(
      "/api/v2/circlePostComment/around",
      showDefaultErrorToast: showToast,
      data: {
        "channel_id": channelId,
        "post_id": postId,
        "comment_id": commentId,
        "size": size,
      },
    );
    if (res == null) return const Tuple3([], 0, 0);
    final before = (res['before'] ?? []) as List<dynamic>;
    final after = (res['after'] ?? []) as List<dynamic>;
    final current = (res['current'] ?? {}) as Map<String, dynamic>;
    final List<dynamic> lists = [...before, current, ...after];
    return Tuple3(
      lists
          .map((e) => CommentMessageEntity.fromJson(e, postTopicId: topicId))
          .where((e) => e != null && e.isContent)
          .toList(),
      before.length,
      after.length,
    );
  }

  // ///圈子动态详情页 - 跳转到某条回复
  // static Future<dynamic> getAroundCommentList(
  //     String channelId, String postId, String commentId,
  //     {bool showToast = true}) async {
  //   final res = await Http.request("/api/circlePostComment/around",
  //       showDefaultErrorToast: showToast,
  //       data: {
  //         "channel_id": channelId,
  //         "post_id": postId,
  //         "comment_id": commentId,
  //       });
  //   return res;
  // }

  ///圈子动态回复详情页，二级回复列表
  static Future<dynamic> getReplyList(
      String commentId, String postId, int size, String listId,
      {bool showToast = true}) async {
    final res = await Http.request("/api/circlePostComment/replyLists",
        showDefaultErrorToast: showToast,
        data: {
          "comment_id": commentId,
          "post_id": postId,
          "list_id": listId,
          "size": '$size',
        });
    return res;
  }

  ///删除回复
  static Future<dynamic> deleteReply(
      String commentId, String postId, String level,
      {bool toast = true}) async {
    final res = await Http.request("/api/circlePostComment/del",
        showDefaultErrorToast: toast,
        data: {
          "comment_id": commentId,
          "post_id": postId,
          "level": level,
        });
    return res;
  }

  static Future updateCircle(
    String channelId,
    String guildId, {
    String icon,
    String name,
    String description,
    String banner,
    String sortType,
  }) async {
    final data = {"guild_id": guildId, "channel_id": channelId};
    if (icon != null) {
      data['icon'] = icon;
    }
    if (name != null) {
      data['name'] = name;
    }
    if (description != null) {
      data['description'] = description;
    }
    if (banner != null) {
      data['banner'] = banner;
    }
    if (sortType != null) {
      data['sort_type'] = sortType;
    }

    final res = await Http.request(
      '/api/channel/manage',
      showDefaultErrorToast: true,
      data: data,
    );
    return res;
  }

  /// - 1. 圈子动态的权限检查
  /// - 2. 话题管理的地方调用
  /// - guildId: 服务台Id
  /// - channelId: 频道ID
  static Future<List<dynamic>> getTopics(String guildId,
      {String channelId, bool showDefaultErrorToast = true}) async {
    final res = await Http.request(
      '/api/circle/topic',
      showDefaultErrorToast: showDefaultErrorToast,
      data: {
        'guild_id': guildId,
        'channel_id': channelId,
      },
    );
    return res;
  }

  static Future setupViewStyleTopic(
      String channelId, String guildId, int showType,
      {String topicId}) async {
    final res = await Http.request('/api/circle/topicAdd',
        showDefaultErrorToast: true,
        data: {
          'channel_id': channelId,
          'guild_id': guildId,
          'topic_id': topicId,
          'show_type': showType,
        });
    return res;
  }

  static Future addTopic(String channelId, String guildId, String name,
      {String topicId, int listDisplay = 0}) async {
    final data = {
      'channel_id': channelId,
      'guild_id': guildId,
      'name': name,
      'topic_id': topicId,
      'list_display': listDisplay,
    };

    final res = await Http.request('/api/circle/topicAdd',
        showDefaultErrorToast: true, data: data);

    return res;
  }

  static Future deleteTopic(
      String topicId, String channelId, String guildId) async {
    final res = await Http.request('/api/circle/topicDelete',
        showDefaultErrorToast: true,
        data: {
          'topic_id': topicId,
          'channel_id': channelId,
          'guild_id': guildId,
        });
    return res;
  }

  static Future reorderTopics(
    String channelId,
    String guildId,
    List<Map<String, dynamic>> topics,
  ) async {
    final res = await Http.request(
      "/api/circle/topicUpdate",
      showDefaultErrorToast: true,
      data: {
        'topic': topics,
        'channel_id': channelId,
        'guild_id': guildId,
      },
    );
    return res;
  }

  ///修改动态所属频道
  static Future circleTopicUp(String guildId, String channelId, String postId,
      String topicId, String toTopicId,
      {bool showToast = false}) async {
    final res = await Http.request("/api/circle/upPostTopic",
        data: {
          'guild_id': guildId,
          "channel_id": channelId,
          "post_id": postId,
          "topic_id": topicId,
          "to_topic_id": toTopicId,
        },
        showDefaultErrorToast: showToast);
    return res;
  }

  /// * 获取某条回复
  static Future<CommentMessageEntity> getComment(
      String postId, String commentId,
      {String topicId, bool showToast = false}) async {
    final res = await Http.request(
      "/api/circleComment/getComment",
      showDefaultErrorToast: showToast,
      data: {
        "post_id": postId,
        "comment_id": commentId,
      },
    );
    if (res == null) return null;
    final map = res as Map<String, dynamic>;
    if (map.isEmpty) return null;
    return CommentMessageEntity.fromJson(map, postTopicId: topicId);
  }
}

typedef OnRequestError = void Function(int code);

///表示整个动态不存在
const int postNotFound = 1034;
const int postNotFound2 = 1089;

/// * 动态是否已被删除
bool postIsDelete(int code) {
  return code == postNotFound || code == postNotFound2;
}

String postNotFoundToast = '内容已被删除'.tr;

///评论被删除
const int commentNotFound = 1089;
