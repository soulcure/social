import 'dart:async';

import 'package:flutter/services.dart';

export 'live/api/jigou_live_api.dart';
export 'live/api/fblive_provider.dart';
export 'live/api/fblive_model.dart';

export 'live/utils/other/float_plugin.dart';
export 'live/utils/other/ios_screen_util.dart';
export 'live/utils/other/screen_orientation_util.dart';

export 'live/utils/config/route_path.dart';
export 'live/utils/ui/listview_custom_view.dart';
export 'live/utils/func/router.dart';
export 'live/utils/other/float_util.dart';
export 'live/utils/ui/overlay.dart';
export 'live/pages/create_room/create_room_web.dart';
export 'live/pages/create_room/create_room.dart';
export 'live/net/api.dart';
export 'live/utils/theme/my_toast.dart';
export 'live/pages/live_room/room_middle_page.dart';
export 'live/utils/ui/loading.dart';
export 'live/utils/ui/draggable_widget.dart';
export 'live/utils/live_status_enum.dart';
export 'live/utils/ui/theme_dialog.dart';
export 'live/utils/ui/dialog_util.dart';
export 'live/utils/manager/permission_manager.dart';
export 'live/pages/room_list/room_list.dart';
export 'live/utils/fb_navigator_observer.dart';
export 'live/event_bus_model/ios_screen_even.dart';
export 'live/utils/pop_route.dart';
export 'live/api/community_live_api.dart';

class FbLiveFlutter {
  static const MethodChannel _channel = MethodChannel('fb_live_flutter');

  //
  // static Future<String?> get platformVersion async {
  //   final String? version = await _channel.invokeMethod('getPlatformVersion');
  //   return version;
  // }

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
