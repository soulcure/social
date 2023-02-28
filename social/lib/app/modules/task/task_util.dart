import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/task_bean.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/common/extension/future_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/http_middleware/interceptor/logging_interceptor.dart';
import 'package:im/db/db.dart';
import 'package:im/db/quote_message_db.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/task_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/utils.dart';
import 'package:im/ws/ws.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

class TaskUtil {
  static final TaskUtil instance = TaskUtil._internal();

  static const String undone_task_channel = "1"; //未完成任务频道
  static const String done_task_channel = "2"; //已完成任务频道

  List<TaskBean> undoneTasks; //所有未完成任务列表
  List<TaskBean> doneTasks; //所有已完成任务列表 暂未使用

  RxBool isNewGuy = false.obs; //是否有入门仪式任务
  RxString taskEntityTitle = ''.obs;
  TaskEntity takEntity; //isNewGuy true,获取入门仪式的内容
  TaskBean curTask;

  final Map<String, Future<MessageEntity>> _networkRequestCache = {};

  factory TaskUtil() {
    return instance;
  }

  ///构造函数
  TaskUtil._internal() {
    undoneTasks = [];
    doneTasks = []; //暂时未使用，内存中不保存

    ///初始化本地未完成任务
    final List undoneKeys = Db.undoneTaskBox.keys.toList();
    if (undoneKeys != null && undoneKeys.isNotEmpty) {
      undoneKeys.forEach((e) {
        final TaskBean item = Db.undoneTaskBox.get(e);
        undoneTasks.add(item);
      });
    }
    if (undoneTasks.isNotEmpty)
      undoneTasks
          .sort((left, right) => left.messageId.compareTo(right.messageId));

    ///初始化本地已完成任务
    final List doneKeys = Db.doneTaskBox.keys.toList();
    if (doneKeys != null && doneKeys.isNotEmpty) {
      doneKeys.forEach((e) {
        final TaskBean item = Db.doneTaskBox.get(e);
        doneTasks.add(item);
      });
    }
    if (doneTasks.isNotEmpty)
      doneTasks
          .sort((left, right) => left.messageId.compareTo(right.messageId));

    Ws.instance.on<TaskBean>().listen((event) async {
      if (event is TaskBean) {
        if (event.status == 1 && !hasTask(event)) {
          undoneTasks.add(event);
          final int id = event.taskMessageId.hashCode;
          await Db.undoneTaskBox.put(id, event);

          ///刷新当前服务台任务
          final gt = ChatTargetsModel.instance.selectedChatTarget;
          if (gt is GuildTarget) {
            await reqTaskByGuildId(gt.id);
          }
        } else if (event.status == 2) {
          await removeTask(event);
          doneTasks.add(event); //暂时未使用，内存中不保存
          final int id = event.taskMessageId.hashCode;
          await Db.doneTaskBox.put(id, event);

          if (curTask != null && curTask.taskMessageId == event.taskMessageId) {
            isNewGuy.value = false;
            takEntity = null;
            taskEntityTitle.value = takEntity?.taskTitle ?? '';
            //controller.updateNewGuy();
          }

          // Future.delayed(const Duration(milliseconds: 2000), () async {
          //
          // });

          await _updateGuildTargetInfo(event);
        }
      }
    });
  }

  /// 更新服务台信息(游客信息更新)
  Future<void> _updateGuildTargetInfo(TaskBean event) async {
    ///刷新服务台数据
    final selectGt =
        ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    if (selectGt is GuildTarget && selectGt.userPending) {
      final guildInfo = await GuildApi.getGuildInfo(
          guildId: event.guildId, userId: Global.user.id);
      final GuildTarget tempGuildTarget = GuildTarget.fromJson(guildInfo);
      if (tempGuildTarget.userPending == selectGt.userPending) return;

      selectGt.userPending = tempGuildTarget.userPending;

      final json = selectGt.toJson();
      // json["channel_lists"] = (json["channel_lists"] as List).join(",");
      unawaited(Db.guildBox.put(selectGt.id, json));
      for (final c in selectGt.channels) unawaited(Db.channelBox.put(c.id, c));

      ///修改内存里的GuildTarget的 userPending
      final dbTarget = ChatTargetsModel.instance.chatTargets
          .firstWhere((e) => e.id == selectGt.id);
      if (dbTarget != null && dbTarget is GuildTarget) {
        dbTarget.userPending = tempGuildTarget.userPending;
      }

      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      selectGt.notifyListeners();
    }
  }

  /// ws消息通知更新服务台信息(游客信息更新)
  Future<void> updateGuildTargetInfoWithGuildId(Map data) async {
    if (data.isEmpty) return;
    final String guildId = data['guild_id'];
    final bool userPending = data['user_pending'];
    if (guildId.noValue) return;

    await _updateGuildTargetWithUserPending(guildId, userPending);

    Future.delayed(const Duration(milliseconds: 600), () async {
      final selectGt =
          ChatTargetsModel.instance.selectedChatTarget as GuildTarget;

      ///刷新服务台数据
      if (selectGt == null || guildId == null) {
        await ChatTargetsModel.instance.loadRemoteData();
        return;
      }

      await _updateGuildTargetWithUserPending(guildId, userPending);

      isNewGuy.value = false;

      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      selectGt.notifyListeners();
    });
  }

  Future<void> _updateGuildTargetWithUserPending(
      String guildId, bool userPending) async {
    final selectGt =
        ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    if (selectGt.id == guildId) {
      selectGt.userPending = userPending;

      final json = selectGt.toJson();
      // json["channel_lists"] = (json["channel_lists"] as List).join(",");
      unawaited(Db.guildBox.put(selectGt.id, json));
      for (final c in selectGt.channels) unawaited(Db.channelBox.put(c.id, c));
    }

    ///修改内存里的GuildTarget的 userPending
    final dbTarget = ChatTargetsModel.instance.chatTargets
        .firstWhere((e) => e.id == guildId, orElse: () => null);
    if (dbTarget != null && dbTarget is GuildTarget) {
      dbTarget.userPending = userPending;
    }
  }

  ///请求未完成任务
  Future<void> reqUndoneTask() async {
    String lastTaskId;
    if (undoneTasks.isNotEmpty) {
      lastTaskId = undoneTasks.last.messageId;
    }

    try {
      final rsp = await Ws.instance.send({
        "action": MessageAction.mChannel,
        "channels": {undone_task_channel: lastTaskId},
      });

      if (rsp != null && rsp is Map) {
        final temp = rsp[undoneChannel] as List<dynamic>;
        if (temp == null || temp.isEmpty) return;
        temp.forEach((e) async {
          final String temp = e as String;
          final List<String> list = temp.split(';');
          final TaskBean item = TaskBean.fromList(list);
          item.status = 1; //未完成任务

          if (!hasTask(item)) {
            undoneTasks.add(item);

            final int id = item.taskMessageId.hashCode;
            await Db.undoneTaskBox.put(id, item);
          }
        });

        ///请求未完成任务后，只请求一次本地选中服务器任务详情
        final gt = ChatTargetsModel.instance.selectedChatTarget;
        if (gt != null) {
          await reqTaskByGuildId(gt.id);
        }
      }
    } catch (e, s) {
      logger.severe(e.toString(), s);
    }
  }

  ///任务是否本地有缓存
  bool hasTask(TaskBean undoneTask) {
    bool result = false;

    for (final item in undoneTasks) {
      if (item.messageId == undoneTask.messageId) {
        result = true;
        break;
      }
    }

    return result;
  }

  ///收到完成任务，移除未完成缓存
  Future<void> removeTask(TaskBean doneTask) async {
    try {
      undoneTasks.removeWhere((e) => e.taskMessageId == doneTask.taskMessageId);
      final int id = doneTask.taskMessageId.hashCode;
      await Db.undoneTaskBox.delete(id);
    } catch (e) {
      print(e);
    }
  }

  ///切换服务台，获取当前服务台任务
  Future<void> reqTaskByGuildId(String guildId) async {
    if (guildId == null || undoneTasks.isEmpty) return;

    try {
      curTask = undoneTasks.lastWhere((e) => e.guildId == guildId,
          orElse: () => null);

      if (curTask != null) {
        // final int index = doneTasks
        //     .indexWhere((e) => e.taskMessageId == curTask.taskMessageId);

        ///不在已完成任务列表
        //if (index == -1) {
        final String messageId = curTask.taskMessageId;
        final String channelId = curTask.channelId;

        MessageEntity messageEntity;
        if (_networkRequestCache.containsKey(guildId)) {
          // 如果上次请求网络异常了，比如无网络或者请求失败，需要重新请求
          messageEntity = await _networkRequestCache[guildId];
          // [QuoteMessageTable.getTask] 返回 null 说明错误发生，将允许下次重新请求
          if (messageEntity == null) {
            _networkRequestCache.remove(guildId).unawaited;
          }
        } else {
          final networkRequestFuture = _networkRequestCache[guildId] =
              QuoteMessageTable.getTask(channelId, messageId, undoneTasks);
          messageEntity = await networkRequestFuture;
        }

        if (messageEntity != null &&
            messageEntity.content != null &&
            messageEntity.content is TaskEntity) {
          takEntity = messageEntity.content as TaskEntity;
          taskEntityTitle.value = takEntity?.taskTitle ?? '';

          final gt = ChatTargetsModel.instance.selectedChatTarget;

          if (takEntity.isTaskIntroductionCeremony() &&
              gt != null &&
              gt is GuildTarget &&
              gt.userPending) {
            isNewGuy.value = true;
          } else {
            isNewGuy.value = false;
          }
          return;
        }
        //}
      }
    } catch (e) {
      //no task
      print(e);
    }

    isNewGuy.value = false;
    takEntity = null;
    taskEntityTitle.value = takEntity?.taskTitle ?? '';
    curTask = null;
  }

  ///任务填写完成，回调合作方服务器
  Future<bool> postTaskResult(Map<String, dynamic> map) async {
    if (takEntity == null || takEntity.url == null || curTask == null)
      return false;

    String path = takEntity.url;
    final String guildId = curTask.guildId;
    final String channelId = curTask.channelId;
    final String messageId = curTask.taskMessageId;

    const String oldPath = 'http://49.234.139.212:8299';
    const String newPath = 'https://fanbot.fanbook.mobi:8299';

    if (kIsWeb && path.contains(oldPath)) {
      path = path.replaceFirst(oldPath, newPath);
    }

    final Options options = Options(headers: {
      "user_id": Global.user.id,
      "guild_id": guildId,
      "channel_id": channelId,
      "task_id": messageId,
      "params_ws": curTask.toString(),
    });

    try {
      final dio = Dio(); //dio 构造为 factory 可以直接使用
      dio.interceptors.add(LoggingInterceptor());
      dio.options.connectTimeout = 5000;

      ///添加代理
      final String proxy = SpService.to.getString(SP.proxySharedKey);
      if (Http.useProxy && isNotNullAndEmpty(proxy)) Http.setProxy(dio, proxy);

      final text = jsonEncode(map);
      print("postTaskResult path =$path");

      final response =
          await dio.post(path, options: options, data: {"text": text});

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print("post task result success");
        return true;
      } else {
        print("post task result failed");

        Future.delayed(const Duration(milliseconds: 500), () {
          showToast(networkErrorText);
        });

        return false;
      }
    } catch (e) {
      print("postTaskResult $e");
      Future.delayed(const Duration(milliseconds: 500), () {
        showToast(networkErrorText);
      });
      return false;
    }
  }

  //服务器定义 userId+1 = 未完成任务频道
  String get undoneChannel {
    final userId = BigInt.parse(Global.user.id ?? "0");
    final undoneChannelId = (userId + BigInt.from(1)).toString();
    return undoneChannelId;
  }

  //服务器定义 userId+2 = 已完成任务频道 暂未使用
  String get doneChannel {
    final userId = BigInt.parse(Global.user.id ?? "0");
    final undoneChannelId = (userId + BigInt.from(2)).toString();
    return undoneChannelId;
  }

  List<TaskBean> undoneTask(Map map) {
    final List<TaskBean> res = [];
    // final undoneChannel =
    //     (int.parse(Global.user.id) + 1).toString(); //服务器定义 userId+1 = 未完成任务频道

    final temp = map[undoneChannel] as List<dynamic>;
    if (temp == null || temp.isEmpty) return null;
    temp.forEach((e) async {
      final String temp = e as String;
      final List<String> list = temp.split(';');
      final TaskBean item = TaskBean.fromList(list);
      item.status = 1; //未完成任务
      res.add(item);
    });
    return res;
  }

  List<TaskBean> doneTask(Map map) {
    final List<TaskBean> res = [];
    // final doneChannel = (int.parse(Global.user.id) + 2)
    //     .toString(); //服务器定义 userId+2 = 已完成任务频道 暂未使用

    final temp = map[doneChannel] as List<dynamic>;
    if (temp == null || temp.isEmpty) return null;
    temp.forEach((e) async {
      final String temp = e as String;
      final List<String> list = temp.split(';');
      final TaskBean item = TaskBean.fromList(list);
      item.status = 2; //未完成任务
      res.add(item);
    });
    return res;
  }

  void clear() {
    isNewGuy.value = false; //是否有入门仪式任务
    takEntity = null;
    taskEntityTitle.value =
        takEntity?.taskTitle ?? ''; //isNewGuy true,获取入门仪式的内容
    curTask = null;
    Db.undoneTaskBox.clear();
    Db.doneTaskBox.clear();
    undoneTasks.clear();
    doneTasks.clear();
  }
}
