import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_manager/flutter_audio_manager.dart';
import 'package:im/icon_font.dart';

class AudioHelp {
  static ValueNotifier<AudioInput> currentOutput =
      ValueNotifier<AudioInput>(const AudioInput("unknow", 0));

  Future<void> init() async {
    FlutterAudioManager.setListener(() async {
      await _getCurrentOutput();
      print("-----audio change---------------${currentOutput.value}");
    });
    await _getCurrentOutput();
    print("----init-------------------------${currentOutput.value}");
  }

  Future<void> _getCurrentOutput() async {
    print("----------_getCurrentOutput-------start");
    currentOutput.value = await FlutterAudioManager.getCurrentOutput();
    print("----------_getCurrentOutput-------end");
  }

  void changeToSpeaker() {
    print("-----------------------changeToSpeaker------");
    FlutterAudioManager.changeToSpeaker();
  }

  void dispose() {
    FlutterAudioManager.setListener(null);
  }

  static Widget getAudioIcon(BuildContext context,
      {EdgeInsets padding, Color color}) {
    color = color ?? Theme.of(context).textTheme.bodyText2.color;

    return InkWell(
      onTap: () {
        switchAudio(context);
      },
      child: ValueListenableBuilder<AudioInput>(
        valueListenable: currentOutput,
        builder: (_, value, __) {
          return Container(
            padding: padding,
            // color: Colors.red,
            child: Icon(_getIconData(), color: color),
          );
        },
      ),
    );
  }

  static IconData _getIconData() {
    switch (currentOutput.value.port) {
      case AudioPort.receiver:
        return IconFont.buffAudioVisualVolumeClose;
      case AudioPort.speaker:
        return IconFont.buffAudioVisualVolumeUp;
      case AudioPort.headphones:
        return IconFont.buffAudioVisualHeadset;
      case AudioPort.bluetooth:
        return Icons.bluetooth;
      default:
        return IconFont.buffAudioVisualVolumeUp;
    }
  }

  static Future<void> switchAudio(BuildContext context) async {
    final List<AudioInput> inputs =
        await FlutterAudioManager.getAvailableInputs();
    if (inputs.length < 2) {
      if (currentOutput.value.port == AudioPort.receiver) {
        await FlutterAudioManager.changeToSpeaker();
      } else {
        await FlutterAudioManager.changeToReceiver();
      }
    } else {
      await _showPortSheet(context, inputs);
    }
  }

  static Future<void> _showPortSheet(
      BuildContext context, List<AudioInput> inputs) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          actions: _getSheetAction(inputs, context),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: Text("取消".tr),
          ),
        );
      },
    );
  }

  static List<CupertinoActionSheetAction> _getSheetAction(
      List<AudioInput> inputs, context) {
    final List<CupertinoActionSheetAction> arr = [];
    inputs.forEach((f) {
      switch (f.port) {
        case AudioPort.receiver:
          arr.add(CupertinoActionSheetAction(
            onPressed: () {
              FlutterAudioManager.changeToReceiver();
              Navigator.pop(context);
            },
            child: Text("听筒".tr),
          ));
          arr.add(CupertinoActionSheetAction(
            onPressed: () {
              FlutterAudioManager.changeToSpeaker();
              Navigator.pop(context);
            },
            child: Text("外放".tr),
          ));
          break;
        case AudioPort.headphones:
          arr.add(CupertinoActionSheetAction(
            onPressed: () {
              FlutterAudioManager.changeToHeadphones();
              Navigator.pop(context);
            },
            child: Text("耳机".tr),
          ));
          break;
        case AudioPort.bluetooth:
          arr.add(CupertinoActionSheetAction(
            onPressed: () {
              FlutterAudioManager.changeToBluetooth();
              Navigator.pop(context);
            },
            child: Text("蓝牙".tr),
          ));
          break;
        default:
          break;
      }
    });
    return arr;
  }
}
