import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:im/community/interactive_entity/controllers/interactive_entity_controller.dart';
import 'package:im/community/interactive_entity/entity/interactive_entity.dart';

import 'channel_dialog.dart';

class ChannelDialogEntity extends InteractiveEntity {
  @override
  InteractiveEntityType get type => InteractiveEntityType.ChannelDialog;

  @override
  bool get isFullScreen => true;

  String _id;
  String _channelId;
  bool _mute;

  ChannelDialogEntity(String content) {
    final Map<String, String> map =
        Map<String, String>.from(jsonDecode(content));
    _id = map["id"] ?? "";
    _channelId = map["channelId"] ?? "";
    _mute = map["mute"] == "1";
  }

  @override
  Widget buildWidget(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color.fromARGB(128, 0, 0, 0),
      ),
      child: ChannelDialog(
        channelId: _channelId,
        mute: _mute,
        openSettingAction: openOption,
        changeVoiceAction: muteAudio,
        closeAction: closeDialog,
      ),
    );
  }

  void openOption() {
    sendToUnity({
      "method": "OpenOption",
      "id": _id,
    });
    closeDialog();
  }

  void closeDialog() {
    sendToUnity({
      "method": "CloseEntity",
      "id": _id,
    });
    InteractiveEntityController.get().hideEntity();
  }

  void muteAudio(bool mute) {
    _mute = mute;
    sendToUnity({
      "method": "MuteAudio",
      "id": _id,
      "mute": mute ? "1" : "0",
    });
  }
}
