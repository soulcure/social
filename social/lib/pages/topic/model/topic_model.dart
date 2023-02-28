// import 'dart:async';
//
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:im/api/text_chat_api.dart';
// import 'package:im/common/extension/list_extension.dart';
// import 'package:im/db/topic_db.dart';
// import 'package:im/global.dart';
// import 'package:im/pages/home/json/text_chat_json.dart';
// import 'package:im/pages/home/model/in_memory_db.dart';
// import 'package:im/pages/home/model/input_model.dart';
// import 'package:im/pages/home/model/text_channel_controller.dart';
// import 'package:im/pages/home/model/text_channel_event.dart';
// import 'package:im/pages/home/model/text_channel_util.dart';
// import 'package:im/pages/home/view/text_chat/items/components/message_reaction.dart';
// import 'package:im/widgets/list_view/position_list_view/src/item_positions_listener.dart';
// import 'package:im/widgets/list_view/proxy_index_list.dart';
// import 'package:im/widgets/load_more.dart';
// import 'package:im/ws/pin_handler.dart';
// import 'package:rxdart/rxdart.dart';
// import 'package:tuple/tuple.dart';
//
// import '../topic_page.dart';
//
// class TopicController extends GetxController {
//   static const PAGE_SIZE = 20;
//
//   static final Map<String, InputRecord> _inputCache = <String, InputRecord>{};
//
//   ProxyController listController = TopicPage.proxyController;
//
//   List<MessageEntity> messages = const [];
//
//   ValueKey<int> listKey = const ValueKey(0);
//   int listScrollIndex = 0;
//
//   StreamSubscription _subscription;
//
//   ProxyIndexListener indexListener =
//       ProxyIndexListener.fromItemListener(ItemPositionsListener.create());
//
//   int bottomIndex;
//
//   String messageId;
//   String channelId;
//
//   static void updateInputCache(String cacheKey, InputRecord inputRecord) {
//     _inputCache[cacheKey] = inputRecord;
//     redDotRefreshSubject.add(Tuple2(cacheKey, inputRecord.richContent));
//   }
//
//   static InputRecord getInputCache(String cacheKey) {
//     return _inputCache[cacheKey];
//   }
//
//   static void removeInputCache(String cacheKey) {
//     _inputCache.remove(cacheKey);
//     redDotRefreshSubject.add(Tuple2(cacheKey, null));
//   }
//
//   static final BehaviorSubject<Tuple2<String, String>> redDotRefreshSubject =
//       BehaviorSubject<Tuple2<String, String>>();
//
//   Future<void> initData(MessageEntity message, String gotoMessageId) async {
//     messageId = message.messageId;
//     channelId = message.channelId;
//     List<MessageEntity> value;
//     if (kIsWeb) {
//       value = await TextChatApi.getReplyList(
//           Global.user.id, channelId, messageId, null, PAGE_SIZE);
//     } else {
//       ///from db
//       value = await TopicTable.getTopics(message);
//
//       if (!value.every((e) => e.localStatus == MessageLocalStatus.normal)) {
//         /// 如果无历史消息查看权限，数据库就没有数据，从内存中取
//         value = InMemoryDb.getMessageList(channelId)
//             .list
//             .where((e) => e.messageId == messageId || e.quoteL1 == messageId)
//             ?.toList();
//       }
//
//       if (value.noValue) {
//         value = await TextChatApi.getReplyList(
//             Global.user.id, channelId, messageId, null, PAGE_SIZE);
//       }
//     }
//
//     messages = value
//       ..sort((a, b) => a.time.compareTo(b.time))
//       ..removeWhere((e) => e.messageId != messageId && e.deleted == 1);
//     if (messages.first?.messageId == messageId)
//       loadHistoryState = LoadMoreStatus.noMore;
//
//     bottomIndex = messages.length;
//
//     if (gotoMessageId == null) {
//       listScrollIndex = 0;
//     } else {
//       listScrollIndex =
//           messages.indexWhere((element) => element.messageId == gotoMessageId) +
//               1;
//     }
//     update();
//   }
//
//   void _initMessageListener() {
//     indexListener.itemPositionsListener.itemPositions.addListener(_onScroll);
//
//     _subscription = TextChannelUtil.instance.stream.listen((value) {
//       switch (value.runtimeType) {
//         case NewMessageEvent:
//           _onNewMessage(value as NewMessageEvent);
//           break;
//         case DeleteMessageEvent:
//           _onDeleteMessage(value as DeleteMessageEvent);
//           break;
//         case RecallMessageEvent:
//           _onRecallMessage(value as RecallMessageEvent);
//           break;
//         case PinEvent:
//           _onPinMessage(value as PinEvent);
//           break;
//         case UpdateMessageEvent:
//           _onUpdateMessage(value as UpdateMessageEvent);
//           break;
//         case ReactMessageEvent:
//           _onReactMessage(value as ReactMessageEvent);
//           break;
//         case String:
//           if (value == "stick" || value == "unStick") {
//             update();
//           }
//           break;
//       }
//     });
//   }
//
//   @override
//   void onInit() {
//     _initMessageListener();
//     super.onInit();
//   }
//
//   @override
//   void onReady() {
//     super.onReady();
//   }
//
//   @override
//   void onClose() {
//     _subscription.cancel();
//     super.onClose();
//   }
//
//   LoadMoreStatus loadHistoryState = LoadMoreStatus.ready;
//
//   Future<void> _loadHistory() async {
//     if (loadHistoryState != LoadMoreStatus.ready) return;
//
//     loadHistoryState = LoadMoreStatus.loading;
//
//     final res = await TextChatApi.getReplyList(Global.user.id, channelId,
//         messageId, messages.first.messageId, PAGE_SIZE);
//
//     loadHistoryState =
//         res.length < PAGE_SIZE ? LoadMoreStatus.noMore : LoadMoreStatus.ready;
//
//     messages.insertAll(0, res.reversed);
//     // unawaited(ChatTable.appendAll(messages));
//
//     _increaseListKey();
//     listScrollIndex = res.length;
//     update();
//   }
//
//   void _increaseListKey() {
//     listKey = ValueKey(listKey.value + 1);
//   }
//
//   void _onNewMessage(NewMessageEvent value) {
//     if (value.message.quoteL1 != messageId) return;
//
//     if (bottomIndex >= messages.length) {
//       _increaseListKey();
//     }
//
//     messages.add(value.message);
//
//     update();
//   }
//
//   void _onUpdateMessage(UpdateMessageEvent value) {
//     if (value.message.quoteL1 != messageId) return;
//
//     final index = messages
//         .indexWhere((element) => element.messageId == value.message.messageId);
//     if (index >= 0) {
//       messages[index] = value.message;
//       update();
//     }
//   }
//
//   void _onReactMessage(ReactMessageEvent value) {
//     final messageContent = value.message.content as ReactionEntity2;
//     final message = getMessage(messageContent.id);
//     if (message == null) return;
//     final reactions = message.reactionModel.reactions;
//     final reaction = reactions.firstWhere(
//         (v) => v.name == messageContent.emoji.name,
//         orElse: () => null);
//     final bool me = value.message.userId == Global.user.id;
//     if (messageContent.action == 'add') {
//       // if (reaction == null) {
//       //   reactions.add(ReactionEntity(
//       //       messageId: messageContent.id,
//       //       emoji: messageContent.emoji,
//       //       users: [value.message.userId]));
//       // } else {
//       //   if (!reaction.users.contains(value.message.userId))
//       //     reaction.users.add(value.message.userId);
//       // }
//       if (reaction != null) {
//         if (reaction.me && me) {
//           debugPrint("reaction app by me not topic");
//           return;
//         }
//         reaction.count++;
//         reaction.me = reaction.me || me;
//       } else {
//         reactions.add(ReactionEntity(emojiName, me: me));
//       }
//     } else if (messageContent.action == 'del') {
//       final reaction = reactions.firstWhere(
//           (v) => v.name == messageContent.emoji.name,
//           orElse: () => null);
//       if (reaction == null) return;
//       reaction.users.remove(value.message.userId);
//       if (reaction.users.isEmpty) reactions.remove(reaction);
//       update();
//     }
//
//     update();
//   }
//
//   void _onRecallMessage(RecallMessageEvent value) {
//     try {
//       final message =
//           messages.lastWhere((element) => element.messageId == value.id);
//       message.recall = value.recallBy;
//       message.content.messageState.value = MessageState.sent;
//       update();
//       // ignore: empty_catches
//     } catch (e) {
//       print(e);
//     }
//   }
//
//   void _onPinMessage(PinEvent value) {
//     final entity = value.message.content as PinEntity;
//     final oriMessageId = entity.id;
//     final pinned = entity.action == 'pin';
//     final message = messages.firstWhere(
//         (element) => element.messageId == oriMessageId,
//         orElse: () => null);
//     if (message != null) {
//       message.pin = pinned ? value.message.userId : '0';
//       update();
//     }
//   }
//
//   void _onDeleteMessage(DeleteMessageEvent value) {
//     final index =
//         messages.lastIndexWhere((element) => element.messageId == value.id);
//     if (index == -1) return;
//     // messages.firstWhere((element) => element.messageId == value.id).deleted =
//     //     1;
//     if (messages[index].messageId == messageId)
//       messages[index].deleted = 1;
//     else
//       messages.removeAt(index);
//     update();
//   }
//
//   void _onScroll() {
//     final positions = indexListener.itemPositionsListener?.itemPositions?.value;
//     if (positions.isEmpty) return;
//     final topIndex = positions
//         .where((position) => position.itemTrailingEdge > 0)
//         .reduce((min, position) =>
//             position.itemTrailingEdge < min.itemTrailingEdge ? position : min)
//         .index;
//     if (topIndex <= 0) {
//       _loadHistory();
//     }
//     bottomIndex = positions
//         .where((position) => position.itemLeadingEdge < 1)
//         .reduce((max, position) =>
//             position.itemLeadingEdge > max.itemLeadingEdge ? position : max)
//         .index;
//     // max(0, bottomIndex - 2);
//   }
//
//   MessageEntity getMessage(String messageId) {
//     return messages.firstWhere((element) => element.messageId == messageId,
//         orElse: () => null);
//   }
//
//   void resendMessage(MessageEntity message) {
//     messages.remove(message);
//     TextChannelController.to(channelId: message.channelId).resend(message);
//   }
// }
