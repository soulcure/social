import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:im/api/api.dart';
import 'package:im/api/text_chat_api.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/db/db.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/search/model/search_model.dart';
import 'package:im/pages/search/search_util.dart';
import 'package:im/services/connectivity_service.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// 消息搜索 - Controller
class SearchMessageController extends GetxController {
  final String guildId;
  GuildTarget target;

  ///展开的消息
  final List<String> unFoldMessageList = [];

  /// 当前服务器所有的频道id和名称集合
  Map<String, String> _channelNameMap;

  SearchInputModel searchInputModel;
  SearchTabModel searchTabModel;
  RefreshController refreshController;

  /// 当前搜索的关键字
  String searchKey;

  ///分页参数
  final int size = 30;
  BigInt lastId;

  ///搜索结果
  List<MessageEntity> resultList = <MessageEntity>[];

  ///搜索方式：有网用服务端搜索；无网用本地搜索
  SearchType searchType = SearchType.network;
  SearchStatus searchStatus = SearchStatus.normal;

  ///是否有下一页
  bool hasNextPage = true;

  SearchMessageController(this.guildId, this.searchInputModel,
      this.searchTabModel, this.refreshController) {
    debugPrint('getChat search -- new: $guildId');
    target = ChatTargetsModel.instance.chatTargets
        .firstWhere((c) => c.id == guildId && c is GuildTarget);
    _channelNameMap ??= {};
    if (target != null) {
      target.channels?.forEach((e) {
        _channelNameMap[e.id] = e.name;
      });
    }

    ///监听输入框
    searchInputModel.searchStream
        .where((event) => searchTabModel.isSelectMessageTab())
        .where(SearchUtil.filterInput)
        .listen((searchKey) {
      debugPrint('getChat search listen key: $searchKey');
      search(searchKey);
    });
  }

  /// 根据关键字搜索聊天记录
  Future<void> search(String key) async {
    searchKey = key?.trim();
    resetData();
    update();
    if (searchKey == null || searchKey.isEmpty) return;
    if (kIsWeb || ConnectivityService.to.enabled)
      searchType = SearchType.network;
    else
      searchType = SearchType.local;
    debugPrint('getChat searchType: $searchType');
    await searchMore();
  }

  /// 搜索失败，点击重新发起
  Future<void> reSearch() async {
    await search(searchKey);
  }

  /// 搜索下一页
  Future<int> searchMore() async {
    List<MessageEntity> searchList;
    searchStatus = SearchStatus.searching;
    update();
    bool isCancel = false;
    if (searchType == SearchType.network) {
      searchList = await TextChatApi.searchMessage(
              guildId, searchKey, lastId, size,
              cancelToken: AutoCancelToken.getOnly(AutoCancelType.search))
          .catchError((e) {
        ///主动取消请求，不是异常
        if (e is DioError && e.type == DioErrorType.cancel) {
          isCancel = true;
        } else {
          searchStatus = SearchStatus.fail;
        }
        return <MessageEntity>[];
      });
    } else {
      searchList = await ChatTable.searchGuildChatHistory(
        guildId,
        keyword: searchKey,
        lastId: lastId,
        size: size,
      ).catchError((e) {
        debugPrint('getChat search e: $e');
        searchStatus = SearchStatus.fail;
        return <MessageEntity>[];
      });
    }
    if (isCancel) return 0;

    if (searchStatus != SearchStatus.fail) {
      searchStatus = SearchStatus.success;
    }
    if (searchList != null && searchList.isNotEmpty) {
      lastId = searchList.last.messageIdBigInt;
      resultList.addAll(await handleResult(searchList));
    }
    final curLoadLength = searchList != null ? searchList.length : 0;
    hasNextPage = curLoadLength >= size;
    debugPrint(
        'getChat search --> resultList: ${resultList.length} hasNextPage:$hasNextPage');

    update();
    return curLoadLength;
  }

  ///重置和清空
  void resetData() {
    AutoCancelToken.cancel(AutoCancelType.search);
    if (resultList.isNotEmpty) resultList.clear();
    if (unFoldMessageList.isNotEmpty) unFoldMessageList.clear();
    lastId = null;
    searchStatus = SearchStatus.normal;
    refreshController.loadComplete();
    hasNextPage = true;
  }

  /// 处理搜索结果
  Future<List<MessageEntity>> handleResult(
      List<MessageEntity> searchList) async {
    final List<MessageEntity> list = [];
    final gp = PermissionModel.getPermission(guildId);
    bool isValid;
    for (final msg in searchList) {
      //只搜索文本、富文本消息
      if (msg.content is! TextEntity && msg.content is! RichTextEntity)
        continue;
      //过滤用户不可见的频道
      isValid = PermissionUtils.isChannelVisible(gp, msg.channelId);
      if (!isValid) continue;
      list.add(msg);
    }
    return list;
  }

  /// 跳转到聊天窗口，并将聊天列表定位到指定的消息位置
  Future gotoChatWindow(BuildContext context, MessageEntity msg) async {
    // 是否成功跳转到频道
    final isSuccess = await gotoChannel(context, msg.channelId);
    final gp = PermissionModel.getPermission(guildId);
    // 是否有历史消息权限
    final isAllow = PermissionUtils.oneOf(
      gp,
      [Permission.READ_MESSAGE_HISTORY],
      channelId: msg.channelId,
    );
    // 无法跳转到频道，或跳转后聊天列表无法滚动到指定消息
    if (!isSuccess || !isAllow) return;

    // 延迟几毫秒才能让聊天列表跳转到指定消息
    await Future.delayed(const Duration(milliseconds: 100));
    // 聊天列表滚动到当前消息的位置
    await TextChannelController.to(channelId: msg.channelId)
        .gotoMessage(msg.messageId);
    DLogManager.getInstance()
        .extensionEvent(logType: "dlog_app_user_search_fb", extJson: {
      "guild_id": guildId ?? '',
      "opt_type": "search_jump_into",
      "opt_source": "2",
      "opt_sub_source": msg?.channelId ?? '',
      "opt_content": searchKey ?? '',
    });

    return;
  }

  /// 跳转到指定频道聊天窗口，返回是否跳转成功
  Future<bool> gotoChannel(BuildContext context, String channelId) async {
    final channel = Db.channelBox.get(channelId);
    // 当频道被删除，无法跳转
    if (channel == null) {
      showToast("该频道已被删除".tr);
      return false;
    }
    final gp = PermissionModel.getPermission(channel.guildId);
    final isVisible = PermissionUtils.isChannelVisible(gp, channelId);
    if (!isVisible) {
      // 没有权限进入该频道
      showToast("没有权限进入该频道".tr);
      return false;
    }
    FocusScope.of(context).unfocus();
    // 跳转到聊天窗口
    Navigator.pop(context);
    await target?.setSelectedChannel(channel);
    return true;
  }

  String getChannelName(String channelId) {
    return _channelNameMap[channelId] ?? '';
  }
}
