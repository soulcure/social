import 'package:flutter/material.dart';
import 'package:im/pages/guild_setting/circle/entry/circle_entry_view.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/web/pages/main/main_model.dart';

import '../../../../routes.dart';

class CrossPlatformCircleEntryView extends StatelessWidget {
  const CrossPlatformCircleEntryView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (OrientationUtil.portrait) {
      return CircleEntryView(key: key);
    } else {
      return _buildLandscapeView(context);
    }
  }

  Widget _buildLandscapeView(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: GlobalState.selectedChannel,
        builder: (context, channel, _) {
          final bgColor = (OrientationUtil.landscape &&
                  MainRouteModel.instance.routes.last.route ==
                      circleMainPageRoute)
              ? Colors.white
              : Theme.of(context).scaffoldBackgroundColor;
          return DecoratedBox(
            decoration: BoxDecoration(color: bgColor),
            child: CircleEntryView(key: key),
          );
        });
  }
}
