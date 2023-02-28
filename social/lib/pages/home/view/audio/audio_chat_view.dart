// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:im/core/widgets/loading.dart';
// import 'package:im/hybrid/webrtc/room/audio_room.dart';
// import 'package:im/hybrid/webrtc/room_manager.dart';
// import 'package:im/icon_font.dart';
// import 'package:im/pages/home/home_page.dart';
// import 'package:im/pages/home/model/audio_chat_model.dart';
// import 'package:im/pages/home/model/chat_index_model.dart';
// import 'package:im/pages/home/model/chat_target_model.dart';
// import 'package:im/pages/home/view/check_permission.dart';
// import 'package:im/themes/const.dart';
// import 'package:im/utils/orientation_util.dart';
// import 'package:im/widgets/only.dart';
// import 'package:im/widgets/realtime_user_info.dart';
// import 'package:im/widgets/sound_meter.dart';
// import 'package:im/widgets/user_info_popup.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:provider/provider.dart';
//
// import '../bottom_bar/audio_chat_bottom_bar.dart';
//
// class AudioChatView extends StatefulWidget {
//   final ChatChannel channel;
//
//   AudioChatView(this.channel) : super(key: Key(channel.id.toString()));
//
//   @override
//   _AudioChatViewState createState() => _AudioChatViewState();
// }
//
// class _AudioChatViewState extends State<AudioChatView> {
//   Future<AudioRoomModel> _future;
//
//   @override
//   void initState() {
//     _creteRoom();
//     super.initState();
//   }
//
//   void _creteRoom() {
//     _future = AudioRoomModel.create(widget.channel.id);
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     AudioRoomModel.onError = (error) {
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: Text(error),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () {
//                 if (AudioRoomModel.instance != null) {
//                   Navigator.of(context).pop();
//                   AudioRoomModel.instance.closeAndDispose();
//                 }
//               },
//               child: const Text('确定'.tr),
//             ),
//           ],
//         ),
//       );
//     };
//     return FutureBuilder<AudioRoomModel>(
//       future: _future,
//       builder: (context, snapshot) {
//         switch (snapshot.connectionState) {
//           case ConnectionState.none:
//           case ConnectionState.waiting:
//             return Loading.getActivityIndicator(color: Colors.grey);
//           default:
//             void goBack() {
//               GlobalState.hangUp();
//               HomeScaffoldController.to.gotoWindow(0);
//               ChatTargetsModel.instance.selectedChatTarget
//                   .selectDefaultTextChannel();
//             }
//             if (snapshot.hasError) {
//               print(snapshot.error);
//               RoomManager.close();
//               if (snapshot.error == RoomManager.premissError) {
//                 checkSystemPermissions(
//                   context: context,
//                   permissions: [Permission.microphone],
//                   // rejectedTips: "请允许麦克风权限",
//                   onRejectedCancel: () {
//                     Navigator.of(context).pop();
//                     goBack();
//                   },
//                 ).then((value) {
//                   if (value == false) goBack();
//                   if (value == true) setState(_creteRoom);
//                 });
//                 return const SizedBox();
//               } else {
//                 return Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: <Widget>[
//                       const Text("连接语音超时，请稍后重试！".tr),
//                       sizeHeight20,
//                       Text(snapshot.error.toString()),
//                       sizeHeight20,
//                       TextButton(
//                         onPressed: () {
//                           _creteRoom();
//                           setState(() {});
//                         },
//                         child: const Text("点击重试".tr),
//                       ),
//                     ],
//                   ),
//                 );
//               }
//             } else {
//               return Column(
//                 children: <Widget>[
//                   if (OrientationUtil.landscape) const Divider(),
//                   _buildVoiceList(),
//                   const Divider(),
//                   // if (OrientationUtil.portrait)
//                   // Expanded(
//                   //   child: TextChatView(
//                   //     model: snapshot.data.textRoomModel,
//                   //     bottomBar:
//                   //         AudioChatBottomBar(widget.channel, snapshot.data),
//                   //   ),
//                   // )
//                   // else
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(8, 40, 8, 8),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: <Widget>[
//                         sizeWidth10,
//                         ValueListenableBuilder(
//                           valueListenable: snapshot.data.muted,
//                           builder: (context, value, child) {
//                             return AudioButton(
//                               bgColor: Theme.of(context).backgroundColor,
//                               icon: value
//                                   ? Icon(
//                                       IconFont.buffAudioVisualMicOff,
//                                       color: Theme.of(context)
//                                           .textTheme
//                                           .bodyText2
//                                           .color,
//                                     )
//                                   : SoundMic(Theme.of(context)
//                                       .textTheme
//                                       .bodyText2
//                                       .color),
//                               onTap: () {
//                                 snapshot.data.toggleMuted();
//                                 setState(() {});
//                               },
//                             );
//                             },
//                           ),
//                           sizeWidth10,
//                           AudioButton(
//                             bgColor: Theme.of(context).backgroundColor,
//                             icon: const Icon(Icons.call_end, color: Color(0xFFF2494A)),
//                             onTap: () {
//                               snapshot.data.closeAndDispose("语音聊天已结束".tr);
//                             },
//                           ),
//                           sizeWidth15,
//                         ],
//                       ),
//                     ),
//                 ],
//               );
//             }
//         }
//       },
//     );
//   }
//
//   Widget _buildVoiceList() {
//     return ChangeNotifierProvider.value(
//       value: AudioRoomModel.instance,
//       child: Consumer<AudioRoomModel>(
//         builder: (context, model, widget) {
//           final list = model.users;
//           return Container(
//             padding: const EdgeInsets.symmetric(horizontal: 15),
//             height: 95,
//             child: Row(
//               children: <Widget>[
//                 Expanded(
//                   child: ListView.builder(
//                     scrollDirection: Axis.horizontal,
//                     primary: true,
//                     itemCount: list.length,
//                     itemBuilder: (_, index) {
//                       return _buildItem(list[index]);
//                     },
//                   ),
//                 ),
//                 // 更多
//                 InkWell(
//                   onTap: () => HomeScaffoldController.to.gotoWindow(2),
//                   child: Padding(
//                     padding: const EdgeInsets.only(left: 10),
//                     child: Column(
//                       children: <Widget>[
//                         Container(
//                           margin: const EdgeInsets.fromLTRB(0, 15, 0, 5),
//                           alignment: Alignment.center,
//                           width: 48,
//                           height: 48,
//                           decoration: BoxDecoration(
//                             color: Theme.of(context).scaffoldBackgroundColor,
//                             shape: BoxShape.circle,
//                           ),
//                           child: Text(
//                             "${list.length}",
//                             style: Theme.of(context).textTheme.bodyText2,
//                           ),
//                         ),
//                         const Text(
//                           "全部".tr,
//                           style:
//                               TextStyle(color: Color(0xFF80868D), fontSize: 11),
//                         )
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildItem(AudioUser item) {
//     return GestureDetector(
//       onTap: () =>
//           showUserInfoPopUp(context, item.userId, showRemoveFromGuild: true),
//       child: Stack(
//         children: <Widget>[
//           Padding(
//             padding: const EdgeInsets.fromLTRB(0, 15, 10, 5),
//             child: Column(
//               children: <Widget>[
//                 RealtimeAvatar(userId: item.userId, size: 48),
//                 sizeHeight5,
//                 SizedBox(
//                     width: 52,
//                     child: RealtimeNickname(
//                       userId: item.userId,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(
//                         color: Color(0xFF80868D),
//                         fontSize: 11,
//                       ),
//                     ))
//               ],
//             ),
//           ),
//           // 说话状态
//           Positioned(
//             left: 37,
//             top: 47,
//             child: Only(
//               showIndex: item.muted ? 2 : item.talking ? 1 : 0,
//               children: <Widget>[
//                 Container(),
//                 Container(
//                   width: 16,
//                   height: 16,
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).primaryColor,
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     IconFont.buffAudioVisualMic,
//                     color: Colors.white,
//                     size: 10,
//                   ),
//                 ),
//                 Container(
//                   width: 16,
//                   height: 16,
//                   decoration: const BoxDecoration(
//                     color: Color(0xFFF24848),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     IconFont.buffAudioVisualMicOff,
//                     color: Colors.white,
//                     size: 10,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
