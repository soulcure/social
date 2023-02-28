import 'dart:io';

import 'package:flutter/material.dart';
import 'package:im/app/modules/direct_message/views/direct_message_view.dart';
import 'package:im/app/modules/home/views/guild_detail_view/landscape_guild_detail_view.dart';
import 'package:im/app/modules/home/views/guild_detail_view/portrait_guild_detail_view.dart';
import 'package:im/pages/home/model/chat_target_model.dart';

class GuildDetailView extends StatelessWidget {
  final GuildTarget target;
  const GuildDetailView({Key key, @required this.target}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return (Platform.isIOS || Platform.isAndroid)
        ? PortraitGuildDetailView(target: target)
        : target == null
            ? DirectMessageView()
            : LandscapeGuildDetailView(target: target);
  }
}
