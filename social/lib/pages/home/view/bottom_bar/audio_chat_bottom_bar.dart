// import 'package:flutter/material.dart';
// import 'package:im/hybrid/webrtc/tools/audio_help.dart';
// import 'package:im/icon_font.dart';
// import 'package:im/pages/home/model/audio_chat_model.dart';
// import 'package:im/pages/home/model/chat_target_model.dart';
// import 'package:im/pages/home/view/bottom_bar/text_chat_bottom_bar.dart';
// import 'package:im/themes/const.dart';
// import 'package:im/widgets/sound_meter.dart';
//
// class AudioChatBottomBar extends TextChatBottomBar {
//   final AudioRoomModel _model;
//
//   const AudioChatBottomBar(ChatChannel channel, this._model) : super(channel);
//
//   @override
//   _AudioChatBottomBarState createState() => _AudioChatBottomBarState();
// }
//
// class _AudioChatBottomBarState
//     extends TextChatBottomBarState<AudioChatBottomBar> {
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   @override
//   Row buildTextFieldRow(BuildContext context) {
//     return Row(
//       // crossAxisAlignment: CrossAxisAlignment.end,
//       children: <Widget>[
//         sizeWidth16,
//         Expanded(
//           child: getTextField(),
//         ),
//         if (FocusScope.of(context).hasFocus)
//           getSendButton()
//         else
//           _buildButtons(context),
//       ],
//     );
//   }
//
//   Padding _buildButtons(BuildContext context) {
//     final iconColor = Theme.of(context).textTheme.bodyText2.color;
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
//       child: Row(
//         children: <Widget>[
//           sizeWidth10,
//           ValueListenableBuilder(
//             valueListenable: widget._model.muted,
//             builder: (context, value, child) {
//               return AudioButton(
//                 bgColor: Theme.of(context).backgroundColor,
//                 icon: value
//                     ? Icon(
//                         IconFont.buffAudioVisualMicOff,
//                         color: iconColor,
//                       )
//                     : SoundMic(iconColor),
//                 onTap: () {
//                   widget._model.toggleMuted();
//                   setState(() {});
//                 },
//               );
//             },
//           ),
//           sizeWidth10,
//           AudioButton(
//             bgColor: Theme.of(context).backgroundColor,
//             icon: AudioHelp.getAudioIcon(context),
//           ),
//           sizeWidth10,
//           AudioButton(
//             bgColor: Theme.of(context).backgroundColor,
//             icon: const Icon(Icons.call_end, color: Color(0xFFF2494A)),
//             onTap: () {
//               widget._model.closeAndDispose("语音聊天已结束".tr);
//             },
//           ),
//           sizeWidth15,
//         ],
//       ),
//     );
//   }
// }
//
// class AudioButton extends StatelessWidget {
//   final Color bgColor;
//   final Function onTap;
//   final Widget icon;
//
//   const AudioButton({this.bgColor, this.icon, this.onTap});
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         width: 40,
//         height: 40,
//         decoration: BoxDecoration(
//           color: bgColor,
//           shape: BoxShape.circle,
//           boxShadow: const [
//             BoxShadow(
//               blurRadius: 8,
//               offset: Offset(0, 1),
//               color: Color(0x1A6A7480),
//             )
//           ],
//         ),
//         child: icon,
//       ),
//     );
//   }
// }
