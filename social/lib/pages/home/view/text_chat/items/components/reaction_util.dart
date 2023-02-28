import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:im/app/routes/app_pages.dart' as get_pages;
import 'package:im/core/config.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/http_middleware/interceptor/logging_interceptor.dart';
import 'package:im/db/reaction_table.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/pages/home/model/text_channel_event.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/pages/home/view/text_chat/items/components/message_reaction.dart';
import 'package:im/pages/home/view/text_chat/items/components/reaction_cache_bean.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/utils.dart';
import 'package:im/ws/ws.dart';

import '../../../../../../global.dart';

enum ReactionResult {
  success, //表态成功
  error, //表态逻辑错误，如对重复表态，因为UI上已经计数，所有要扣除此次表态
  notPermission, //无表态权限
  fail, //表态失败，如网络不通，因为UI上已经计数，网络通后要补上协议
}

@immutable
class OffLineReaction {
  final int pullTime;

  const OffLineReaction(this.pullTime);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OffLineReaction &&
          runtimeType == other.runtimeType &&
          pullTime == other.pullTime;

  @override
  int get hashCode => pullTime.hashCode;
}

class ReactionUtil {
  static const TIMEOUT = 3000;
  static final ReactionUtil _singleton = ReactionUtil._internal();

  factory ReactionUtil() {
    return _singleton;
  }

  ReactionUtil._internal() {
    Ws.instance
        .on<OffLineReaction>()
        .distinct((previous, next) => previous == next)
        .listen((event) {
      if (event is OffLineReaction) {
        _asyncOffLineReaction();
      }
    });
  }

  Box<ReactionCacheBean> reactionCacheBox;

  ///open hive box for offline Reaction
  Future<void> initBox() async {
    if (reactionCacheBox == null || !reactionCacheBox.isOpen) {
      final adapter = ReactionCacheBeanAdapter();
      if (!Hive.isAdapterRegistered(adapter.typeId)) {
        Hive.registerAdapter(adapter);
      }

      reactionCacheBox =
          await Hive.openBox<ReactionCacheBean>("reactionCacheBox");
      debugPrint(
          "reaction initBox reactionCacheBox isOpen=${reactionCacheBox.isOpen}");
    }
  }

  ///noPull 执行完成后，同步离线的表态数据 ,使用广播去重机制，保证只执行一次
  void asyncOffLineReaction() {
    final int pullTime = SpService.to.getInt2("${Global.user.id}_pullTime");
    final OffLineReaction event = OffLineReaction(pullTime);
    Ws.instance.fire(event);
  }

  ///noPull 执行完成后，同步离线的表态数据
  Future<void> _asyncOffLineReaction() async {
    await initBox();

    ///fix: 虽然在notPull完成后发起同步，但是有可能比notPull快
    await Future.delayed(const Duration(milliseconds: 500));

    debugPrint("reaction asyncOffLineReaction");
    if (reactionCacheBox != null && reactionCacheBox.isOpen) {
      final keys = reactionCacheBox.keys;
      if (keys != null && keys.isNotEmpty) {
        for (final String key in keys) {
          final bean = reactionCacheBox.get(key);
          if (bean != null) {
            if (bean.count >= 1) {
              final ReactionResult res = await ReactionUtil().createReaction(
                  Global.user.id,
                  bean.messageId,
                  bean.channelId,
                  bean.emojiName);
              if (res == ReactionResult.success ||
                  res == ReactionResult.notPermission ||
                  res == ReactionResult.error) {
                debugPrint("reaction createReaction offline success");
                await reactionCacheBox.delete(key);

                if (res == ReactionResult.notPermission) {
                  await removeReaction(
                      bean.channelId, bean.messageId, bean.emojiName);
                }
              }
            } else if (bean.count <= -1) {
              final ReactionResult res = await ReactionUtil().deleteReaction(
                  Global.user.id,
                  bean.messageId,
                  bean.channelId,
                  bean.emojiName);
              if (res == ReactionResult.success ||
                  res == ReactionResult.notPermission ||
                  res == ReactionResult.error) {
                debugPrint("reaction deleteReaction offline success");
                await reactionCacheBox.delete(key);

                if (res == ReactionResult.notPermission) {
                  await addReaction(
                      bean.channelId, bean.messageId, bean.emojiName);
                }
              }
            } else {
              await reactionCacheBox.delete(key);
            }
          }
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    }
  }

  /// 离线的表态数据无权限则回撤客户端本地计数的表态数据
  Future<void> removeReaction(
      String channelId, String messageId, String emojiName) async {
    final message = InMemoryDb.getMessage(channelId, BigInt.parse(messageId));

    if (message != null &&
        message.reactionModel != null &&
        message.reactionModel.actions != null) {
      final List<ReactionEntity> actions = message.reactionModel.actions;
      final reaction =
          actions.firstWhere((v) => v.name == emojiName, orElse: () => null);

      //todo 好的设计是ws发送消息，各个业务模块统一监听
      if (Get.currentRoute == get_pages.Routes.TOPIC_PAGE) {
        final OffLineReactionEvent offLineReactionEvent =
            OffLineReactionEvent(message.messageId, emojiName, 'del');
        TextChannelUtil.instance.stream.add(offLineReactionEvent);
      }

      if (reaction == null) {
        message.reactionModel.notify();
        await ReactionTable.remove(messageId, emojiName, 0, false);
        return;
      }

      reaction.count--;
      reaction.me = false; //无权限表态
      if (reaction.count <= 0) {
        actions.remove(reaction);
      }
      message.reactionModel.notify();
      await ReactionTable.remove(messageId, emojiName, reaction.count, false);
    } else {
      await ReactionTable.appendByNotPullDbCount(messageId, emojiName, false,
          count: -1);
    }
  }

  /// 离线的表态数据无权限则回撤客户端本地计数的表态数据
  Future<void> addReaction(
      String channelId, String messageId, String emojiName) async {
    final message = InMemoryDb.getMessage(channelId, BigInt.parse(messageId));

    if (message != null &&
        message.reactionModel != null &&
        message.reactionModel.actions != null) {
      final List<ReactionEntity> actions = message.reactionModel.actions;
      final reaction =
          actions.firstWhere((v) => v.name == emojiName, orElse: () => null);

      //todo 好的设计是ws发送消息，各个业务模块统一监听
      if (Get.currentRoute == get_pages.Routes.TOPIC_PAGE) {
        final OffLineReactionEvent offLineReactionEvent =
            OffLineReactionEvent(message.messageId, emojiName, 'add');
        TextChannelUtil.instance.stream.add(offLineReactionEvent);
      }
      if (reaction == null) {
        message.reactionModel.notify();
        await ReactionTable.remove(messageId, emojiName, 0, false);
        return;
      }

      reaction.count++;
      reaction.me = true; //无权限表态
      message.reactionModel.notify();
      await ReactionTable.remove(messageId, emojiName, reaction.count, false);
    } else {
      await ReactionTable.appendByNotPullDbCount(messageId, emojiName, true,
          count: 1);
    }
  }

  ///发送表态的http请求失败，缓存到hive db,等待下次notPull完成后同步离线表态
  Future<void> appendReactionToCache(ReactionCacheBean cacheBean) async {
    assert(cacheBean != null);
    await initBox();

    if (reactionCacheBox != null && reactionCacheBox.isOpen) {
      final bean = reactionCacheBox.get(cacheBean.getKey());
      if (bean == null) {
        await reactionCacheBox.put(cacheBean.getKey(), cacheBean);
      } else if (bean != null && bean.count < 1) {
        bean.count++;

        if (bean.count == 0) {
          await reactionCacheBox.delete(cacheBean.getKey());
        } else {
          await reactionCacheBox.put(cacheBean.getKey(), bean);
        }
      }
    }
  }

  ///同步离线表态成功后，则删除hive db中保持的离线表态数据
  Future<void> delReactionToCache(ReactionCacheBean cacheBean) async {
    await initBox();
    assert(cacheBean != null);
    if (reactionCacheBox != null && reactionCacheBox.isOpen) {
      final bean = reactionCacheBox.get(cacheBean.getKey());
      if (bean == null) {
        await reactionCacheBox.put(cacheBean.getKey(), cacheBean);
      } else if (bean != null && bean.count > -1) {
        bean.count--;

        if (bean.count == 0) {
          await reactionCacheBox.delete(cacheBean.getKey());
        } else {
          await reactionCacheBox.put(cacheBean.getKey(), bean);
        }
      }
    }
  }

  ///发起表态的http请求，设置超时3000毫秒
  Future<ReactionResult> createReaction(
      String userId, String messageId, String channelId, String emoji) {
    const path = "/api/reaction/create";
    final data = {
      "user_id": userId,
      "message_id": messageId,
      "channel_id": channelId,
      "emoji": Uri.encodeComponent(emoji)
    };
    return httpPost(path, data);
  }

  Future<ReactionResult> deleteReaction(
      String userId, String messageId, String channelId, String emoji) {
    const path = "/api/reaction/del";
    final data = {
      "user_id": userId,
      "message_id": messageId,
      "channel_id": channelId,
      "emoji": Uri.encodeComponent(emoji)
    };
    return httpPost(path, data);
  }

  /// * 增加圈子回复的表态
  Future<ReactionResult> createCircleReaction(String guildId, String channelId,
      String postId, String messageId, String emoji) {
    const path = "/api/circlePostCommentReaction/create";
    final data = {
      "guild_id": guildId,
      "channel_id": channelId,
      "post_id": postId,
      "comment_id": messageId,
      "emoji": Uri.encodeComponent(emoji),
    };
    return httpPost(path, data);
  }

  /// * 删除圈子回复的表态
  Future<ReactionResult> deleteCircleReaction(String guildId, String channelId,
      String postId, String messageId, String emoji) {
    const path = "/api/circlePostCommentReaction/del";
    final data = {
      "guild_id": guildId,
      "channel_id": channelId,
      "post_id": postId,
      "comment_id": messageId,
      "emoji": Uri.encodeComponent(emoji),
    };
    return httpPost(path, data);
  }

  ///发起表态的http请求
  Future<ReactionResult> httpPost(String path, Map data) async {
    final BaseOptions baseOptions = BaseOptions(
      connectTimeout: TIMEOUT,
      baseUrl: Config.host,
      headers: {
        HttpHeaders.userAgentHeader:
            "platform:${Global.deviceInfo.systemName.toLowerCase()};channel:${Config.channel};version:${Global.packageInfo.version};",
      },
    );

    final dio = Dio(baseOptions); //dio 构造为 factory 可以直接使用
    dio.interceptors.add(LoggingInterceptor());

    final options = Options();
    options
      ..responseType = ResponseType.json
      ..sendTimeout = TIMEOUT
      ..receiveTimeout = TIMEOUT;
    //options.extra = retryOptions.toExtra();
    options.headers = Http.getHeader(headers: options.headers, data: data);

    ///添加代理
    final String proxy = SpService.to.getString(SP.proxySharedKey);
    if (Http.useProxy && isNotNullAndEmpty(proxy)) Http.setProxy(dio, proxy);

    try {
      debugPrint("reaction httpPost start");
      final response = await dio.post(path, data: data, options: options);
      if (response.statusCode == 204) {
        debugPrint("reaction httpPost success");
        return ReactionResult.success;
      } else if (response.statusCode == 200) {
        final Map res = response.data;

        ///无表态权限
        if (res != null && res['code'] == 1012) {
          return ReactionResult.notPermission;
        }

        //重复表态了
        return ReactionResult.error;
      }
    } catch (e) {
      debugPrint("reaction httpPost error=$e");
    }

    return ReactionResult.fail; //表态失败，如网络不通，因为UI上已经计数，网络通后要补上协议
  }
}
