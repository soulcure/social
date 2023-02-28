import 'package:fb_live_flutter/live/model/colse_room_model.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../utils/func/check.dart';

mixin CloseRoomLogic {
  CloseRoomModel? closeRoomModel;

  /*
  * 计算直播时长
  * */
  String get timeStr {
    if (!strNoEmpty(closeRoomModel?.liveTime)) {
      return "00:00:00";
    }
    final liveTime = DateTime.parse(closeRoomModel?.liveTime ?? '');
    final closeTime = DateTime.parse(closeRoomModel?.closeTime ?? '');
    final def = closeTime.difference(liveTime);
    final String inHours = doubleNum((def.inHours).toString());
    final inMinutes = doubleNum((def.inMinutes % 60).toString());
    final inSeconds = doubleNum((def.inSeconds % 60).toString());
    return '$inHours:$inMinutes:$inSeconds';
  }

  /*
  * 是否生成回放
  * */
  bool get isLessOneMin {
    return !(closeRoomModel?.hasPlayback ?? false);
  }

  /*
  * 状态栏刷新
  * */
  void statusBarRefresh() {
    if (!kIsWeb) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    }
  }
}
