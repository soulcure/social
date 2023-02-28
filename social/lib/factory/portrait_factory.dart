import 'package:flutter/material.dart';
import 'package:im/pages/channel/channel_creation_page/portrait_channel_creation.dart';
import 'package:im/pages/guild_setting/channel/notification_manager_page/protrait_notification_manager_page.dart';

import 'app_factory.dart';

class PortraitFactory implements AppFactory {
  @override
  Widget createChannelCreation(String guildId, {String cateId}) =>
      PortraitChannelCreation(guildId, cateId: cateId);

  @override
  Widget createNotificationManager() => PortraitNotificationManagerPage();
}
