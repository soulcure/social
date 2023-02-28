import 'package:flutter/material.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/channel_icon.dart';

class UiIconExample extends StatelessWidget {
  const UiIconExample();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppbar(title: "图标"),
      body: ListView(
        children: [
          Row(
            children: [const Text("公开频道"), ...channelIconRow(false)],
          ),
          Row(
            children: [const Text("私密频道"), ...channelIconRow(true)],
          ),
        ],
      ),
    );
  }

  List<Widget> channelIconRow(bool private) {
    return [
      ChannelIcon(ChatChannelType.guildText, private: private),
      ChannelIcon(ChatChannelType.guildVoice, private: private),
      ChannelIcon(ChatChannelType.guildVideo, private: private),
      ChannelIcon(ChatChannelType.guildLink, private: private),
      ChannelIcon(ChatChannelType.guildLive, private: private),
      ChannelIcon(ChatChannelType.guildCircleTopic, private: private),
    ];
  }
}
