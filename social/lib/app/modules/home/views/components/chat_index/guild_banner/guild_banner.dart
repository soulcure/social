import 'package:flutter/material.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/orientation_util.dart';
import 'guild_banner_state.dart';
import 'landscape_guild_banner_state.dart';
import 'portrait_guild_banner_state.dart';

class GuildBanner extends StatefulWidget {
  final GuildTarget target;

  const GuildBanner({@required this.target});

  @override
  // ignore: no_logic_in_create_state
  GuildBannerState createState() => OrientationUtil.portrait
      ? PortraitGuildBannerState()
      : LandscapeGuildBannerState();
}
