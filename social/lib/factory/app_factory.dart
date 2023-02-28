import 'package:flutter/material.dart';
import 'package:im/factory/portrait_factory.dart';
import 'package:im/utils/orientation_util.dart';

import 'landscape_factory.dart';

AppFactory appFactory =
    OrientationUtil.landscape ? LandscapeFactory() : PortraitFactory();

// ignore: one_member_abstracts
abstract class AppFactory {
  Widget createChannelCreation(String guildId, {String cateId});

  Widget createNotificationManager();
}
