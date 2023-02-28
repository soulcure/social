// import 'package:flutter/material.dart';
// import 'package:im/global.dart';
// import 'package:im/hybrid/webrtc/room/audio_room.dart';
// import 'package:im/hybrid/webrtc/room/base_room.dart';
// import 'package:im/hybrid/webrtc/room_manager.dart';
// import 'package:im/pages/home/model/chat_target_model.dart';
// import 'package:im/pages/member_list/model/member_list_model.dart';
// import 'package:im/utils/utils.dart';
// import 'package:oktoast/oktoast.dart';
//
// class AudioRoomModel extends ChangeNotifier {
//   static AudioRoomModel instance;
//   static Function(String data) onError;
//
//   AudioRoom _audioRoom;
//
//   /// 是否静音
//   ValueNotifier<bool> muted = ValueNotifier<bool>(false);
//
//   /// 成员列表
//   List<AudioUser> get users => _audioRoom.users;
//
//   /// 文本聊天
//   // TextRoomModel textRoomModel;
//
//   // ValueKey<int> listKey = const ValueKey(0);
//   static Future<AudioRoomModel> create(String roomId) async {
//     final AudioRoom room = await RoomManager.create(
//       RoomType.audio,
//       roomId,
//       RoomParams(
//         userId: Global.user.id,
//         nickname: Global.user.nickname,
//         avatar: Global.user.avatar,
//       ),
//     );
//     room.join();
//     AudioRoomModel.instance = AudioRoomModel(room);
//     return instance;
//   }
//
//   AudioRoomModel(AudioRoom room) : assert(room != null) {
//     _audioRoom = room;
//     // textRoomModel = TextRoomModel(_audioRoom.textRoom);
//     // textRoomModel.joinChannel(
//     //   GlobalState.mediaChannel.item2,
//     // );
//     room.onEvent = _onEvent;
//   }
//
//   void _onEvent(RoomState state, [data]) {
//     if (instance == null) return;
//     switch (state) {
//       case RoomState.leaved:
//       case RoomState.joined:
//       case RoomState.changed:
//         notifyListeners();
//         if (GlobalState.selectedChannel.value?.id == _audioRoom.roomId)
//           MemberListModel.instance.mediaUsers = _audioRoom.users;
//         break;
//       case RoomState.error:
//         if (onError != null) {
//           onError('发生错误：$data');
//           onError = null;
//         }
//         break;
//       case RoomState.disconnected:
//         if (onError != null) {
//           onError('音频被中断，请检查网络后重试'.tr);
//           onError = null;
//         }
//         break;
//       default:
//         break;
//     }
//   }
//
//   void toggleMuted() {
//     _audioRoom.muted = !_audioRoom.muted;
//     muted.value = _audioRoom.muted;
//     showToast(_audioRoom.muted ? '麦克风已关闭'.tr : '麦克风已打开'.tr);
//   }
//
//   Future<void> _close([String msg]) async {
//     if (instance != null) {
//       instance = null;
//       _audioRoom = null;
//       if (isNotNullAndEmpty(msg)) showToast(msg);
//       await RoomManager.close();
//     }
//   }
//
//   /// 关闭+页面销毁
//   Future<void> closeAndDispose([String msg]) async {
//     if (instance == null) return;
//     await _close(msg);
//     GlobalState.hangUp();
//   }
// }
