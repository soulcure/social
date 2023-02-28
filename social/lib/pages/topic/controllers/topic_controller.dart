import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:im/api/text_chat_api.dart';
import 'package:im/common/extension/list_extension.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/db/db.dart';
import 'package:im/db/reaction_table.dart';
import 'package:im/db/topic_db.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/reaction_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/model/text_channel_event.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/pages/home/view/text_chat/items/components/message_reaction.dart';
import 'package:im/pages/home/view/text_chat/items/components/reaction_detail_api.dart';
import 'package:im/pages/home/view/text_chat/items/model/message_card_helper.dart';
import 'package:im/widgets/list_view/position_list_view/src/item_positions_listener.dart';
import 'package:im/widgets/list_view/proxy_index_list.dart';
import 'package:im/widgets/load_more.dart';
import 'package:im/ws/pin_handler.dart';
import 'package:im/ws/ws.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

import '../topic_page.dart';

@immutable
class OnlookerUser {
  final String userId;
  final bool isPush;

  const OnlookerUser(this.userId, this.isPush);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnlookerUser &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}

class TopicController extends GetxController {
  static const PAGE_SIZE = 20;
  static String emojiName = "围观".tr;

  static const NEW_MESSAGE = 1;
  static const NEW_BACK = 2;

  static const LOAD_SIZE = 100;
  RxBool isLoading = RxBool(false);
  bool isMore = false;

  static final Map<String, InputRecord> _inputCache = <String, InputRecord>{};

  List<MessageEntity> messages = <MessageEntity>[];

  int listScrollIndex = 0;

  StreamSubscription _subscription;

  ProxyIndexListener indexListener =
      ProxyIndexListener.fromItemListener(ItemPositionsListener.create());

  int bottomIndex;

  String messageId;
  String channelId;
  String topMessageUserId;

  bool _isTopicShare;
  List<OnlookerUser> users = <OnlookerUser>[];

  ReactionModel get autoReactionModel {
    if (messages != null && messages.isNotEmpty) {
      return messages.first.reactionModel;
    }
    return null;
  }

  bool get isTopicShare => _isTopicShare == true;

  ///是否双击回到顶部
  bool isTureTop = false;

  MessageEntity curMsg;

  CancelToken cancelToken;

  ScrollController scrollController;

  static TopicController to() {
    try {
      return Get.find<TopicController>();
    } catch (e) {
      return Get.put(TopicController());
    }
  }

  static void updateInputCache(String cacheKey, InputRecord inputRecord) {
    _inputCache[cacheKey] = inputRecord;
    redDotRefreshSubject.add(Tuple2(cacheKey, inputRecord.richContent));
  }

  static InputRecord getInputCache(String cacheKey) {
    return _inputCache[cacheKey];
  }

  static void removeInputCache(String cacheKey) {
    _inputCache.remove(cacheKey);
    redDotRefreshSubject.add(Tuple2(cacheKey, null));
  }

  static final BehaviorSubject<Tuple2<String, String>> redDotRefreshSubject =
      BehaviorSubject<Tuple2<String, String>>();

  static bool isSurrounding(String name) {
    return name == emojiName || name == 'Surrounding' || name == 'Onlookers';
  }

  void autoReaction() {
    ///有我的围观，不发起围观
    if (!isAutoReaction() && autoReactionModel != null) {
      autoReactionModel.toggle(
        emojiName,
        msgId: messageId,
        isShowMutedMsg: false,
      );
    }
  }

  bool isAutoReaction() {
    if (users != null && users.isNotEmpty) {
      final index = users.indexWhere((e) => e.userId == Global.user.id);
      if (index >= 0) {
        return true;
      }
    }
    return false;
  }

  bool hasContent(List<MessageEntity> value) => value?.first?.isContent == true;

  bool hasReaction(List<MessageEntity> value) {
    if (value != null &&
        value.first != null &&
        value.first.reactionModel != null &&
        value.first.reactionModel.reactions.hasValue) {
      return true;
    }
    return false;
  }

  Future<void> reqReactionUserImage() async {
    // if (!autoReactionModel.isOnlookers) {
    //   ///无表态，不请求
    //   if (autoReactionModel == null ||
    //       autoReactionModel.actions == null ||
    //       autoReactionModel.actions.isEmpty) {
    //     if (InMemoryDb.getMessage(autoReactionModel.channelId,
    //             BigInt.parse(autoReactionModel.messageId)) ==
    //         null) {
    //       return;
    //     }
    //   }
    // }

    isLoading.value = true;
    final ReactionData reactionData =
        await ReactionDetailApi.getReactionDetailSingle(
            messageId, channelId, emojiName,
            size: LOAD_SIZE.toString());
    final list = reactionData?.lists;
    if (list != null && list.isNotEmpty) {
      list.remove(topMessageUserId);
      users.clear();
      for (final value in list) {
        final OnlookerUser item = OnlookerUser(value, false);
        users.add(item);
      }

      if (list.length == LOAD_SIZE) {
        isMore = true;
      } else {
        isMore = false;
      }
    } else {
      await listenConnected();
    }
    isLoading.value = false;
    update();
  }

  // 上拉加载
  Future<void> loadMore() async {
    if (isMore && !isLoading.value) {
      isLoading.value = true;
      final ReactionData reactionData =
          await ReactionDetailApi.getReactionDetailSingle(
              messageId, channelId, emojiName,
              size: LOAD_SIZE.toString(), after: users.last.userId);
      final list = reactionData?.lists;
      if (list != null && list.isNotEmpty) {
        list.remove(topMessageUserId);
        for (final value in list) {
          final OnlookerUser item = OnlookerUser(value, false);
          users.add(item);
        }
        if (list.length == LOAD_SIZE) {
          isMore = true;
        } else {
          isMore = false;
        }
      }
      isLoading.value = false;
      update();
    }
  }

  Future<void> initData(MessageEntity message, String gotoMessageId,
      bool isShare, ScrollController controller) async {
    cancelToken = CancelToken();
    scrollController = controller;

    messageId = message.messageId;
    channelId = message.channelId;
    topMessageUserId = message.userId;

    _isTopicShare = isShare;
    List<MessageEntity> value;
    bool isLoadNet = false;
    if (kIsWeb) {
      value = await TextChatApi.getReplyList(
          Global.user.id, channelId, messageId, null, PAGE_SIZE, cancelToken);
      isLoadNet = true;
    } else {
      final c = TextChannelController.to(channelId: channelId);

      if (!c.canReadHistory) {
        /// 如果无历史消息查看权限，数据库就没有数据，从内存中取
        value = InMemoryDb.getMessageList(channelId)
            .list
            .where((e) => e.messageId == messageId || e.quoteL1 == messageId)
            ?.toList();
      } else {
        ///from db
        value = await TopicTable.getTopics(message);

        ///从网络获取
        if (value.noValue || !hasContent(value)) {
          loadHistoryState = LoadMoreStatus.loading;
          value = await TextChatApi.getReplyList(Global.user.id, channelId,
              messageId, null, PAGE_SIZE, cancelToken);
          if (value != null) {
            loadHistoryState = value.length < PAGE_SIZE
                ? LoadMoreStatus.noMore
                : LoadMoreStatus.ready;
            isLoadNet = true;
          }
        }
      }
    }

    messages = value
      ..sort((a, b) => a.time.compareTo(b.time))
      ..removeWhere((e) => e.deleted == 1);

    if (messages.isNotEmpty && messages[0].messageId != message.messageId) {
      ///添加入口id
      messages.insert(0, message);
    }

    setSendingMessage();

    if (isLoadNet && messages.first?.messageId == messageId) {
      loadHistoryState = LoadMoreStatus.noMore;
    }

    bottomIndex = messages.length;

    if (gotoMessageId == null) {
      listScrollIndex = 0;
      curMsg = null;
    } else {
      final index =
          messages.indexWhere((element) => element.messageId == gotoMessageId);
      if (index > -1) {
        listScrollIndex = index + 1;
        curMsg = messages[index];
        curMsg.extra = NEW_BACK;
      } else {
        listScrollIndex = 0;
        curMsg = null;
      }
    }

    unawaited(reqReactionUserImage());

    update();

    if (curMsg != null) {
      await Future.delayed(const Duration(milliseconds: 300))
          .then((_) => clearHighLightMessage());
    }
  }

  ///合并内存中正在发送的消息到话题详情页
  void setSendingMessage() {
    final tcController = TextChannelController.to(channelId: channelId);

    final internalList = tcController.internalList;
    //fix 话题有可能从其他的频道分享过来，tcController.internalList可能未初始化而为空
    if (internalList == null) return;

    messages = messages.map((e) {
      final MessageEntity msg = internalList.get(e.messageIdBigInt);
      if (msg?.content?.messageState?.value == MessageState.waiting) {
        return msg;
      } else {
        return e;
      }
    }).toList();
  }

  void _initMessageListener() {
    indexListener.itemPositionsListener.itemPositions.addListener(_onScroll);

    _subscription = TextChannelUtil.instance.stream.listen((value) {
      switch (value.runtimeType) {
        case MessageEntity:
          _handleOnlinePush(value);
          break;
        case NewMessageEvent:
          _onNewMessage(value as NewMessageEvent);
          break;
        case DeleteMessageEvent:
          _onDeleteMessage(value as DeleteMessageEvent);
          break;
        case RecallMessageEvent:
          _onRecallMessage(value as RecallMessageEvent);
          break;
        case PinEvent:
          _onPinMessage(value as PinEvent);
          break;
        case UpdateMessageEvent:
          _onUpdateMessage(value as UpdateMessageEvent);
          break;
        case ReactMessageEvent:
          _onReactMessage(value as ReactMessageEvent);
          break;
        case NotPullEvent:
          _onNotPullReaction(value as NotPullEvent);
          break;
        case OffLineReactionEvent:
          _offLineReactionAddEvent(value as OffLineReactionEvent);
          break;
        case String:
          if (value == "stick" || value == "unStick") {
            update();
          }
          break;
      }
    });
  }

  @override
  void onInit() {
    _initMessageListener();
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    indexListener.itemPositionsListener.itemPositions.removeListener(_onScroll);
    _subscription.cancel();
    super.onClose();
  }

  void cancelGetReplyList() {
    cancelToken?.cancel();
    cancelToken = null;
  }

  Future<void> clearHighLightMessage() async {
    if (curMsg != null && curMsg.extra != null) {
      curMsg.extra = null;
      curMsg = null;
      update();
    }
  }

  LoadMoreStatus loadHistoryState = LoadMoreStatus.ready;

  Future<void> _loadHistory() async {
    if (loadHistoryState == LoadMoreStatus.loading ||
        loadHistoryState == LoadMoreStatus.toTop ||
        loadHistoryState == LoadMoreStatus.noMore) return;
    if (messages.length <= 1) return;

    bool listIsChanged = false;
    loadHistoryState = LoadMoreStatus.loading;

    String lastId;
    if (kIsWeb) {
      lastId = messages[0].messageId;
    } else {
      lastId = messages[1].messageId;
    }

    final res = await TextChatApi.getReplyList(
        Global.user.id, channelId, messageId, lastId, PAGE_SIZE, cancelToken);
    loadHistoryState = (res?.length ?? 0) < PAGE_SIZE
        ? LoadMoreStatus.noMore
        : LoadMoreStatus.ready;
    if (res == null) {
      update();
      return;
    }
    final reversedList = res.reversed;
    if (kIsWeb) {
      messages.insertAll(0, reversedList);
    } else {
      if (loadHistoryState == LoadMoreStatus.noMore) {
        ///fix 服务器多发送了top message,导致重复
        for (final MessageEntity item in reversedList) {
          bool notMsg = true;
          for (final MessageEntity cur in messages) {
            if (item.messageId == cur.messageId) {
              notMsg = false;
              break;
            }
          }
          if (notMsg) {
            messages.insert(1, item);
            listIsChanged = true;
          }
        }
      } else {
        messages.insertAll(1, reversedList);
        listIsChanged = true;
      }

      unawaited(ChatTable.appendAll(res, isUpdate: true));
    }

    if (listIsChanged) {
      TopicPage.proxyController?.jumpToIndex(res.length);
      update();
    }
  }

  void _onNewMessage(NewMessageEvent value) {
    if (value.message.quoteL1 == null ||
        messageId == null ||
        value.message.quoteL1 != messageId) return;

    value.message.extra = NEW_MESSAGE;

    final index = messages
        .indexWhere((element) => element.messageId == value.message.messageId);
    if (index >= 0) {
      messages[index] = value.message;
    } else {
      messages.add(value.message);
    }

    update();
  }

  void _onUpdateMessage(UpdateMessageEvent value) {
    if (value.message.quoteL1 != messageId) return;

    final index = messages
        .indexWhere((element) => element.messageId == value.message.messageId);
    if (index >= 0) {
      messages[index] = value.message;
      update();
    }
  }

  void _onReactMessage(ReactMessageEvent value) {
    final messageContent = value.message.content as ReactionEntity2;

    ///for 话题的围观（隔离普通表态）
    final topMsg = getTopMessage(messageContent.id);
    if (topMsg != null) {
      if (messageContent.id == autoReactionModel.messageId) {
        final lastAutoReactionUserId = value.message.userId;
        final lastAutoReactionName = messageContent.emoji.name;
        if (messageContent.action == 'add' &&
            lastAutoReactionName == TopicController.emojiName &&
            lastAutoReactionUserId != topMessageUserId) {
          final OnlookerUser item = OnlookerUser(lastAutoReactionUserId, true);
          users.insert(0, item);
          update();
        } else if (messageContent.action == 'del' &&
            lastAutoReactionName == TopicController.emojiName) {
          final int index =
              users.indexWhere((e) => e.userId == lastAutoReactionUserId);
          if (index >= 0) {
            users.removeAt(index);
          }
          update();
        }

        final message =
            InMemoryDb.getMessage(channelId, BigInt.parse(messageId));
        if (message != null &&
            message.reactionModel != null &&
            identical(message.reactionModel, autoReactionModel)) {
          return;
        }
      }
    }

    ///for 普通表态
    final message = getMessage(messageContent.id);
    if (message == null) return;

    if (message.extra != null && message.extra == NEW_MESSAGE) return;

    final List<ReactionEntity> reactions = message.reactionModel.reactions;
    final reaction = reactions.firstWhere(
        (v) => v.name == messageContent.emoji.name,
        orElse: () => null);

    final bool me = value.message.userId == Global.user.id;
    final String emojiName = messageContent.emoji.name;
    final int count = messageContent.emoji.count;

    if (messageContent.action == 'add') {
      if (reaction != null) {
        if (reaction.me && me && reaction.count == count) {
          debugPrint("reaction app by me not topic");
          return;
        }

        reaction.count = count;
        reaction.me = reaction.me || me;
      } else {
        reactions.add(ReactionEntity(emojiName, me: me));
        reactions.sort((a, b) => (b.name).compareTo(a.name));
      }
    } else if (messageContent.action == 'del') {
      if (reaction != null) {
        if (reaction.me && me && reaction.count == count) {
          debugPrint("reaction deleteReaction by me not topic");
          return;
        }
        reaction.count = count;
        if (me) {
          reaction.me = false;
        }
        if (count <= 0) {
          reactions.remove(reaction);
        }
      }
    } else if (messageContent.action == 'delAll') {
      if (reaction != null) {
        reaction.count = 0;
        reaction.me = me;
        reactions.remove(reaction);
      }
    }
    update();
  }

  void _onRecallMessage(RecallMessageEvent value) {
    try {
      final message =
          messages.lastWhere((element) => element.messageId == value.id);
      message.recall = value.recallBy;
      message.content.messageState.value = MessageState.sent;
      update();
      // ignore: empty_catches
    } catch (e) {
      print(e);
    }
  }

  void _onPinMessage(PinEvent value) {
    final entity = value.message.content as PinEntity;
    final oriMessageId = entity.id;
    final pinned = entity.action == 'pin';
    final message = messages.firstWhere(
        (element) => element.messageId == oriMessageId,
        orElse: () => null);
    if (message != null) {
      message.pin = pinned ? value.message.userId : '0';
      update();
    }
  }

  void _onDeleteMessage(DeleteMessageEvent value) {
    final index =
        messages.lastIndexWhere((element) => element.messageId == value.id);
    if (index == -1) return;
    // messages.firstWhere((element) => element.messageId == value.id).deleted =
    //     1;
    if (messages[index].messageId == messageId)
      messages[index].deleted = 1;
    else
      messages.removeAt(index);
    update();
  }

  void _handleOnlinePush(MessageEntity value) {
    switch (value.content.type) {
      case MessageType.unSupport:
      case MessageType.start:
      case MessageType.text:
      case MessageType.image:
      case MessageType.video:
      case MessageType.voice:
      case MessageType.newJoin:
      case MessageType.call:
      case MessageType.del:
      case MessageType.richText:
      case MessageType.empty:
      case MessageType.stickerEntity:
      case MessageType.goodsShareEntity:
      case MessageType.externalShareEntity:
      case MessageType.task:
      case MessageType.redPack:
      case MessageType.friend:
      case MessageType.circle:
      case MessageType.file:
      case MessageType.messageCard:
      case MessageType.vote:
      case MessageType.circleShareEntity:
      case MessageType.topicShare:
        break;
      case MessageType.upMsg:
        // TODO: Handle this case.
        break;
      case MessageType.recall:
        // TODO: Handle this case.
        break;
      case MessageType.pinned:
        // TODO: Handle this case.
        break;
      case MessageType.reaction:
        // TODO: Handle this case.
        break;

      case MessageType.du:
        // TODO: Handle this case.
        break;

      case MessageType.messageCardKey:
        MessageCardHelper.applyKeyPushToMemoryMessage(value, getMessage);
        break;
      case MessageType.document:
        // TODO: Handle this case.
        break;
    }
  }

  ///for 离线后重连更新表态
  void _onNotPullReaction(NotPullEvent value) {
    final message = getMessage(value.messageId);
    if (message == null) return;

    ///话题详情页top message 和外面频道共享内存，所以只用刷新频道UI就可以
    if (value.messageId == getTopMessage(messageId)?.messageId) return;

    if (message.extra != null && message.extra == NEW_MESSAGE) return;

    final List<ReactionEntity> reactions = message.reactionModel.reactions;
    final reaction = reactions.firstWhere((v) => v.name == value.emojiName,
        orElse: () => null);

    if (reaction != null) {
      reaction.me = reaction.me || value.me;

      if (reaction.me == value.me) {
        reaction.me = false;
      } else {
        reaction.me = true;
      }
      reaction.count = reaction.count + value.count;
      if (reaction.count <= 0) {
        reactions.remove(reaction);
      }
    } else {
      if (value.count <= 0) return;

      reactions.add(
          ReactionEntity(value.emojiName, count: value.count, me: value.me));
      reactions.sort((a, b) => (b.name).compareTo(a.name));
    }
    update();
  }

  ///for 离线表态后，无权限回撤
  void _offLineReactionAddEvent(OffLineReactionEvent value) {
    if (value == null) return;

    final message = getMessage(value.messageId);
    if (message == null) return;

    ///话题详情页top message 和外面频道共享内存，所以只用刷新频道UI就可以
    if (value.messageId == getTopMessage(messageId)?.messageId) return;

    final List<ReactionEntity> reactions = message.reactionModel.reactions;
    final reaction = reactions.firstWhere((v) => v.name == value.emojiName,
        orElse: () => null);

    if (reaction != null) {
      if (value.action == 'del') {
        reaction.count--;
        reaction.me = false; //无权限表态
        if (reaction.count <= 0) {
          reactions.remove(reaction);
        }
      } else {
        reaction.count++;
        reaction.me = true; //无权限表态
      }
      update();

      _check(value.messageId, value.emojiName, reaction.count, reaction.me);
    }
  }

  void _check(String messageId, String emojiName, int count, bool me) {
    final message = InMemoryDb.getMessage(channelId, BigInt.parse(messageId));
    if (message != null &&
        message.reactionModel != null &&
        message.reactionModel.actions != null) {
      final List<ReactionEntity> actions = message.reactionModel.actions;
      final reaction =
          actions.firstWhere((v) => v.name == emojiName, orElse: () => null);
      if (reaction == null) return;

      reaction.count = count;
      reaction.me = me; //无权限表态
      if (reaction.count <= 0) {
        actions.remove(reaction);
      }
      message.reactionModel.notify();
    }
  }

  void _onScroll() {
    final positions = indexListener.itemPositionsListener?.itemPositions?.value;
    if (positions.isEmpty) return;
    final topIndex = positions
        .where((position) => position.itemTrailingEdge > 0)
        .reduce((min, position) =>
            position.itemTrailingEdge < min.itemTrailingEdge ? position : min)
        .index;
    if (topIndex <= 1) {
      isTureTop = true;
      final ScrollPosition position = scrollController.position;
      //向下滑动
      if (position.userScrollDirection != ScrollDirection.idle) {
        _loadHistory();
        return;
      }
    } else {
      if (isTureTop && loadHistoryState == LoadMoreStatus.toTop) {
        isTureTop = false;
        loadHistoryState = LoadMoreStatus.ready;
      }
      bottomIndex = positions
          .where((position) => position.itemLeadingEdge < 1)
          .reduce((max, position) =>
              position.itemLeadingEdge > max.itemLeadingEdge ? position : max)
          .index;
      // max(0, bottomIndex - 2);
    }
  }

  MessageEntity getMessage(String messageId) {
    final index =
        messages.indexWhere((element) => element.messageId == messageId);
    //排除第一个 index=0
    if (index >= 0) {
      return messages[index];
    }
    return null;
  }

  MessageEntity getTopMessage(String messageId) {
    /// - list = [] 的时候，.first 将报错 Bad state: No element
    if (messages == null || messages.isEmpty) return null;
    if (messages.first.messageId == messageId) {
      return messages.first;
    }
    return null;
  }

  void resendMessage(MessageEntity message) {
    //messages.remove(message);
    TextChannelController.to(channelId: message.channelId).resend(message);
  }

  Future<void> listenConnected() async {
    final where =
        "${ReactionTable.columnMsgId} = $messageId AND ${ReactionTable.columnName} = '$emojiName'";
    final top = await Db.db.query(ReactionTable.table, where: where);

    if (top != null && top.isNotEmpty) {
      Ws.instance.on<Connected>().listen((event) async {
        if (event is Connected) {
          final ReactionData reactionData =
              await ReactionDetailApi.getReactionDetailSingle(
                  messageId, channelId, emojiName,
                  size: LOAD_SIZE.toString());
          final list = reactionData?.lists;
          if (list != null && list.isNotEmpty) {
            for (final value in list) {
              final OnlookerUser item = OnlookerUser(value, false);
              if (!users.contains(item)) {
                users.add(item);
              }
            }
            update();
          }
        }
      });
    }
  }
}
