import 'package:flutter/material.dart';
import 'package:im/pages/channel/channel_creation_page/landscape_channel_creation.dart';
import 'package:im/pages/guild_setting/channel/notification_manager_page/landscape_notification_manager_page.dart';

import 'app_factory.dart';

class LandscapeFactory implements AppFactory {
  @override
  Widget createChannelCreation(String guildId, {String cateId}) =>
      LanscapeChannelCreation(guildId, cateId: cateId);

  @override
  Widget createNotificationManager() => LandscapeNotificationManagerPage();
}
