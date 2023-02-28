// import 'dart:convert';
//
// import 'package:flutter/material.dart';
// import 'package:im/api/data_model/user_info.dart';
// import 'package:im/hybrid/webrtc/room/base_room.dart';
// import 'package:im/hybrid/webrtc/room/text_room.dart';
// import 'package:im/pages/home/json/text_chat_json.dart';
// import 'package:im/pages/home/model/chat_target_model.dart';
// import 'package:im/pages/home/model/in_memory_db.dart';
// import 'package:im/pages/home/model/text_channel_event.dart';
// import 'package:im/widgets/load_more.dart';
// import 'package:uuid/uuid.dart';
//
// class TextRoomModel extends TextChatModel {
//   final TextRoom textRoom;
//
//   TextRoomModel(this.textRoom) {
//     loadHistoryState = LoadMoreStatus.noMore;
//     textRoom.onEvent = _onEvent;
//   }
//
//   @override
//   String get channelId => textRoom.roomId;
//
//   @override
//   Future<void> sendContent(
//     MessageContentEntity content, {
//     String channelId,
//     String guildId,
//     MessageEntity relay,
//   }) async {
//     String type;
//     switch (content.runtimeType) {
//       case TextEntity:
//         type = "text";
//         // 注意：文字发的内容是文本内容，与其他格式不统一
//         textRoom.sendMessage(type, (content as TextEntity).text);
//         return;
//       case ImageEntity:
//         type = "image";
//         break;
//       case VideoEntity:
//         type = "video";
//         break;
//       case VoiceEntity:
//         type = "voice";
//         break;
//     }
//     try {
//       await content.startUpload();
//       textRoom.sendMessage(type, jsonEncode(content.toJson()));
//     } catch (_) {
//       // 注意，这里不会生效，因为 sendMessage 不会抛出错误
//       content.messageState.value = MessageState.timeout;
//     }
//     notifyListeners();
//   }
//
//   // 往消息列表添加新消息
//   void _onEvent(RoomState state, [TextMessage data]) {
//     if (data != null) {
//       UserInfo.set(UserInfo(
//         userId: data.userId,
//         avatar: data.avatar,
//         nickname: data.nickname,
//       ));
//     }
//
//     switch (state) {
//       case RoomState.messaged:
//         _onMessage(data);
//         break;
//       case RoomState.joined:
//         _onJoined(data);
//         break;
//       // case RoomState.leaved:
//       // _onLeaved(data);
//       // break;
//       case RoomState.ready:
//         isReady = true;
//         notifyListeners();
//         break;
//       default:
//         break;
//     }
//   }
//
//   void _onJoined(TextMessage data) {
//     final MessageEntity message = MessageEntity<WelcomeEntity>(
//       MessageAction.message,
//       channelId,
//       data.userId,
//       null,
//       DateTime.parse(data.date).toLocal(),
//       WelcomeEntity(),
//     );
//     internalList?.add(message);
//     notifyListeners();
//   }
//
//   // _onLeaved(TextMessage data) {
//   //   MessageEntity message = MessageEntity<TextEntity>(
//   //       MessageAction.message,
//   //       channelId,
//   //       data.userId,
//   //       '',
//   //       0,
//   //       DateTime.parse(data.date).toLocal(),
//   //       TextEntity(text: "我离开了"));
//   //   internalList.add(message);
//   //   notifyListeners();
//   // }
//
//   void _onMessage(TextMessage data) {
//     MessageEntity message;
//     switch (data.type) {
//       case 'text':
//         message = MessageEntity<TextEntity>(
//           MessageAction.message,
//           channelId,
//           data.userId,
//           null,
//           DateTime.parse(data.date).toLocal(),
//           TextEntity(text: data.content),
//           messageId: const Uuid().v4(),
//         );
//         break;
//       case 'image':
//         final jsonMap = jsonDecode(data.content);
//         message = MessageEntity<ImageEntity>(
//           MessageAction.message,
//           channelId,
//           data.userId,
//           null,
//           DateTime.parse(data.date).toLocal(),
//           ImageEntity.fromJson(jsonMap),
//           messageId: const Uuid().v4(),
//         );
//         break;
//       case 'video':
//         final jsonMap = jsonDecode(data.content);
//         message = MessageEntity<VideoEntity>(
//           MessageAction.message,
//           channelId,
//           data.userId,
//           null,
//           DateTime.parse(data.date).toLocal(),
//           VideoEntity.fromJson(jsonMap),
//           messageId: const Uuid().v4(),
//         );
//         break;
//       default:
//     }
//     internalList.add(message);
//     if (!visible) unReadNum.value++;
//     notifyListeners();
//   }
//
//   @override
//   Future<void> loadHistory() async {
//     loadHistoryState = LoadMoreStatus.noMore;
//   }
//
//   bool visible = false;
//   ValueNotifier<int> unReadNum = ValueNotifier(0);
//
//   // 是否显示文本聊天面板
//   void updateVisible({bool visible}) {
//     visible = visible;
//     if (visible) unReadNum.value = 0;
//   }
//
//   @override
//   Future<void> sendContents(List<MessageContentEntity> contents,
//       {String channelId,
//       String guildId,
//       MessageEntity<MessageContentEntity> relay}) async {
//     for (final MessageContentEntity content in contents) {
//       String type;
//       switch (content.runtimeType) {
//         case TextEntity:
//           type = "text";
//           // 注意：文字发的内容是文本内容，与其他格式不统一
//           textRoom.sendMessage(type, (content as TextEntity).text);
//           return;
//         case ImageEntity:
//           type = "image";
//           break;
//         case VideoEntity:
//           type = "video";
//           break;
//         case VoiceEntity:
//           type = "voice";
//           break;
//       }
//       try {
//         await content.startUpload();
//         textRoom.sendMessage(type, jsonEncode(content.toJson()));
//       } catch (_) {
//         // 注意，这里不会生效，因为 sendMessage 不会抛出错误
//         content.messageState.value = MessageState.timeout;
//       }
//       notifyListeners();
//     }
//   }
//
//   @override
//   void joinChannel(ChatChannel channel, {bool force = false}) {
//     this.channel = channel;
//     internalList = MessageList(channel.id);
//     super.joinChannel(channel);
//   }
// }
