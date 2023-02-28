//
//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_audio_manager/flutter_audio_manager.dart';
//
// //
// class AudioWidget extends StatelessWidget {
//   final GestureTapCallback onTap;
//
//   const AudioWidget(this.onTap);
//
//   @override
//   Widget build(BuildContext context) {
//     final color = Theme.of(context).textTheme.bodyText2.color;
//     return InkWell(
//       onTap: onTap,
//       child: ValueListenableBuilder<AudioInput>(
//         valueListenable: currentOutput,
//         builder: (_, value, __) {
//           return Container(
//             padding: padding,
//             // color: Colors.red,
//             child: Icon(_getIconData(), color: color),
//           );
//         },
//       ),
//     );
//
//   }
//
//
//   IconData _getIconData() {
//     switch (currentOutput.value.port) {
//       case AudioPort.receiver:
//         return IconFont.buffAudioVisualVolumeClose;
//       case AudioPort.speaker:
//         return IconFont.buffAudioVisualVolumeUp;
//       case AudioPort.headphones:
//         return IconFont.buffAudioVisualHeadset;
//       case AudioPort.bluetooth:
//         return Icons.bluetooth;
//       default:
//         return IconFont.buffAudioVisualVolumeUp;
//     }
//   }
//
// }
