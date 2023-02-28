import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/http_middleware/interceptor/channel_mutex_interceptor.dart';
import 'package:im/core/httpweb.dart' as web;
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/pin_list_model.dart';
import 'package:pedantic/pedantic.dart';
import 'package:tuple/tuple.dart';

import '../loggers.dart';
import 'entity/credits_bean.dart';
import 'entity/resend_resp.dart';

class TextChatApi {
  static Future<List<dynamic>> pullMessages(
    String userId,
    String channelId,
    String messageId, {
    bool before = true,
    int retryTimes = 0,
    MutexOption mutexOption,
  }) async {
    return kIsWeb
        ? await web.HttpWeb.request("/api/message/getList", data: {
            "user_id": userId,
            "channel_id": channelId,
            "message_id": messageId,
            "behavior": before ? "before" : "after",
          })
        : await Http.request("/api/message/getList",
            data: {
              "user_id": userId,
              "channel_id": channelId,
              "message_id": messageId,
              "behavior": before ? "before" : "after",
            },
            retries: retryTimes,
            mutexOption: mutexOption);
  }

  static Future<List<MessageEntity>> getMessages(
      String userId, String channelId, String messageId,
      {bool before = true, int retryTimes = 0, MutexOption mutexOption}) async {
    final List<dynamic> result = await pullMessages(
      userId,
      channelId,
      messageId,
      before: before,
      retryTimes: retryTimes,
      mutexOption: mutexOption,
    );
    unawaited(CreditsBean.updateIfCreditsChange(result));
    return result
        .map((e) {
          if (e.containsKey("author")) {
            final author = e["author"] as Map;
            UserInfo.updateIfChanged(
              userId: e["user_id"],
              nickname: author["nickname"],
              username: author["username"],
              avatar: author["avatar"],
              gNick: author["gNick"],
              guildId: author["guildId"],
              isBot: author["bot"],
              avatarNft: author["avatar_nft"] ?? '',
              avatarNftId: author["avatar_nft_id"] ?? '',
            );
          }
          return MessageEntity.fromJson(e);
        })
        .where((e) => e != null && e.isContent)
        .toList();
  }

  ///批量获取消息的所有数据(消息ID数，最大100)
  static Future<List<MessageEntity>> getBatchMessages(
    String channelId,
    List<String> messageIds, {
    bool showDefaultErrorToast = false,
    int retryTimes = 0,
    MutexOption mutexOption,
  }) async {
    final List<dynamic> result = await Http.request(
      "/api/msg/batchMsg",
      data: {
        "channel_id": channelId,
        "message_ids": messageIds,
      },
      cancelToken: CancelToken(),
      showDefaultErrorToast: showDefaultErrorToast,
      retries: retryTimes,
      mutexOption: mutexOption,
    );
    if (result == null) {
      return [];
    }
    return result
        .map((e) => MessageEntity.fromJson(e))
        .where((e) => e != null && e.isContent)
        .toList();
  }

  static Future<List<MessageEntity>> getReplyList(
      String userId,
      String channelId,
      String quoteId,
      String lastMessageId,
      int count,
      CancelToken cancelToken) async {
    List result;
    try {
      result = await Http.request("/api/message/quotes",
          data: {
            "user_id": userId,
            "channel_id": channelId,
            "quote_id": quoteId,
            "message_id": lastMessageId,
            "size": count,
          },
          cancelToken: cancelToken,
          autoRetryIfNetworkUnavailable: true);
    } catch (e) {
      debugPrint('error:$e');
    }

    return result
        ?.map((e) {
          e["channel_id"] = channelId;
          return MessageEntity.fromJson(e);
        })
        ?.where((e) => e != null)
        ?.toList();
  }

  static Future createReaction(
      String userId, String messageId, String channelId, String emoji) async {
    final res = await Http.request("/api/reaction/create",
        showDefaultErrorToast: true,
        data: {
          "user_id": userId,
          "message_id": messageId,
          "channel_id": channelId,
          "emoji": Uri.encodeComponent(emoji),
        });
    return res;
  }

  static Future deleteReaction(
      String userId, String messageId, String channelId, String emoji) async {
    final res = await Http.request("/api/reaction/del",
        showDefaultErrorToast: true,
        data: {
          "user_id": userId,
          "message_id": messageId,
          "channel_id": channelId,
          "emoji": Uri.encodeComponent(emoji),
        });

    return res;
  }

  static Future recall(String userId, String messageId, String channelId) {
    return Http.request("/api/message/recall",
        showDefaultErrorToast: true,
        data: {
          "user_id": userId,
          "message_id": messageId,
          "channel_id": channelId,
        });
  }

  static Future deleteMessage(
      String userId, String channelId, String messageId) async {
    final res = await Http.request("/api/message/del",
        showDefaultErrorToast: true,
        data: {
          "user_id": userId,
          "message_id": messageId,
          "channel_id": channelId,
        });
    return res;
  }

  static Future<MessageEntity> getMessage(String channelId, String messageId,
      {bool autoRetryIfNetworkUnavailable = false}) async {
    const url = "/api/msg/get";
    dynamic res;
    try {
      res = await Http.request(url,
          data: {
            "channel_id": channelId,
            "message_id": messageId,
          },
          autoRetryIfNetworkUnavailable: autoRetryIfNetworkUnavailable);
    } on RequestArgumentError catch (_) {
      res = null;
    }
    if (res == null) return null;
    return MessageEntity.fromJson(res);
  }

  static Future pinMessage(
      String userId, String channelId, String messageId, bool pinned) async {
    final res = await Http.request("/api/message/pinned",
        showDefaultErrorToast: true,
        data: {
          "user_id": userId,
          "message_id": messageId,
          "channel_id": channelId,
          "pin": pinned ? 1 : 0,
        });
    return res;
  }

  static Future<List<PinListEntity>> getPinList(
      String channelId, int size, int listId) async {
    final res = await Http.request("/api/message/pinList",
        data: {"channel_id": channelId, "size": size, 'list_id': listId});
    return ((res['records'] as List) ?? [])
        .map((e) => PinListEntity.fromJson(e))
        .toList();
  }

  static Future<List<MessageEntity>> getMessagesNear(
      String channelId, String messageId,
      {bool showDefaultErrorToast}) async {
    final List res = await Http.request("/api/msg/around",
        data: {
          "message_id": messageId,
          "channel_id": channelId,
        },
        showDefaultErrorToast: showDefaultErrorToast);
    return res.map((e) => MessageEntity.fromJson(e)).toList()
      ..sort((a, b) => a.messageIdBigInt.compareTo(b.messageIdBigInt));
  }

  static Future<bool> stickMessage(
      String userId, String channelId, String messageId, bool status) async {
    final res = await Http.request("/api/message/top",
        showDefaultErrorToast: true,
        data: {
          "user_id": userId,
          "message_id": messageId,
          "channel_id": channelId,
          "status": status ? 1 : 0,
        });
    if (res["data"] != null && res["data"]["status"] == 0) {
      return true;
    }
    return false;
  }

  static Future<List<Tuple2<Map<String, dynamic>, MessageEntity>>>
      getStickMessageList(String channelId) async {
    final res = await Http.request("/api/message/TopList",
        data: {"channel_id": channelId});
    return ((res['records'] as List) ?? [])
        .map((e) {
          try {
            final MessageEntity m = MessageEntity.fromJson(e);
            final Map<String, String> info = {
              "stickId": e['top_id'] as String ?? "",
              'stickTime': ((e['top_time'] as int) ?? 0).toString(),
              'messageId': m.messageId,
              'isStickRead': e['is_stick_read'],
              'stickUserId': e['top_user_id'] as String ?? "",
            };
            return Tuple2(info, m);
          } catch (e) {
            return null;
          }
        })
        .where((el) => el != null)
        .toList();
  }

  ///搜索服务器消息
  static Future<List<MessageEntity>> searchMessage(
      String guildId, String key, BigInt lastId, int size,
      {CancelToken cancelToken}) async {
    debugPrint('getChat search ');
    final List<dynamic> res =
        await Http.request("/api/search/M", cancelToken: cancelToken, data: {
      "guild_id": guildId,
      "wd": key,
      "last_message_id": lastId?.toString() ?? '0',
      "limit": size,
    });
    final List<MessageEntity> list = res
        .map((e) => MessageEntity.fromJson(e))
        .where((e) => e != null)
        .toList();
    return list;
  }

  static Future<ResendResp> checkReSend(
      String channelId, int time, String nonce) async {
    if (nonce.noValue) return null;

    final res = await Http.request(
      "/api/msg/exists",
      data: {
        "channel_id": channelId,
        "time": time,
        "nonce": nonce,
      },
    ).catchError((e) {
      logger.severe("checkReSend e=$e");
      return null;
    });
    if (res is Map) {
      return ResendResp.fromJson(res);
    }
    return null;
  }
}

class MessageCardApi {
  static Future<void> setKey(
    String channelId,
    String messageId,
    String key,
  ) async {
    // print("假装 set 请求成功了");
    // return;
    await Http.request("/api/messageCard/click", data: {
      "channel_id": channelId,
      "message_id": messageId,
      "key": key,
    });
  }

  static Future<void> autoSetKey(
    String channelId,
    String messageId,
    int max,
  ) async {
    // print("假装 set 请求成功了");
    // return;
    await Http.request("/api/messageCard/auto", data: {
      "channel_id": channelId,
      "message_id": messageId,
      "max": max,
    });
  }

  static Future<void> clearKey(
    String channelId,
    String messageId,
    String action,
  ) async {
    // print("假装 clear 请求成功了");
    // return;
    final res = await Http.request("/api/messageCard/cancel", data: {
      "channel_id": channelId,
      "message_id": messageId,
      "key": action,
    });
    return res;
  }

  static Future<void> getList(
    String channelId,
    String messageId,
    String action,
  ) async {
    final res = await Http.request("/api/messageCard/lists", data: {
      "channel_id": channelId,
      "message_id": messageId,
      "key": action,
    });
    return res;
  }
}
