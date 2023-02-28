import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/utils/config/route_path.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:flutter/material.dart';

class RouteUtil {
  /// 路由名字记录，无空路由名
  static List<String?> routeNames = [];

  /// 路由名字记录，含有空路由名
  static List<String?> routeNamesContainNull = [];

  /// 路由中包含直播预览页面
  ///
  /// 因为路由拦截的时候`previousRoute.settings.name`如果打开过对话框再跳转会为空，
  /// 所以还是嘚用[routeHasPreView]来记录是否包含直播页面路由。
  static bool routeHasPreView = false;

  /// 路由是直播预览页面
  static bool routeIsPreview = false;

  /// 路由中包含直播页面
  ///
  /// 因为路由拦截的时候`previousRoute.settings.name`如果打开过对话框再跳转会为空，
  /// 所以还是嘚用[routeHasLive]来记录是否包含直播页面路由。
  static bool routeHasLive = false;

  /// 路由是直播页面
  static bool get routeIsLive {
    return listNoEmpty(routeNamesContainNull) &&
        routeNamesContainNull[routeNamesContainNull.length - 1] ==
            RoutePath.liveRoom;
  }

  /// 路由是直播页面【不包含空路由】
  static bool get routeIsLiveNotContainNull {
    return listNoEmpty(routeNames) &&
        routeNames[routeNames.length - 1] == RoutePath.liveRoom;
  }

  static bool routeCanRotate() {
    if (!listNoEmpty(routeNamesContainNull)) {
      return false;
    }
    if (routeNamesContainNull[routeNamesContainNull.length - 1] ==
        RoutePath.liveRoom) {
      return true;
    }
    if (routeNamesContainNull.length > 2 &&
        routeNamesContainNull[routeNamesContainNull.length - 1] ==
            DialogRoutePath.confirmDialog &&
        routeNamesContainNull[routeNamesContainNull.length - 2] ==
            RoutePath.liveRoom) {
      return true;
    }
    return false;
  }

  /// 路由跳转判断路由重复
  ///
  /// 后续对话框也将采用此方式
  static Future push(BuildContext? context, Widget page, String name,
      {bool isReplace = false, bool fadeIn = false}) async {
    // try {
    /// 【2021 12.15】回放页面替换跳转不需要检测重复路由，
    /// 因为有替换重复路由的需求
    ///
    /// 解决正在看回放时点左上角头像后再去看回放无法跳转
    final bool isPlayBackAndReplace = name == RoutePath.playBack && isReplace;

    final int endIndex = routeNames.length - 1;
    final String? endRouteName = routeNames[endIndex];
    if (name == endRouteName && !isPlayBackAndReplace) {
    } else {
      /// 必须加return，否则接收参数的地方就出错了，全部为空
      return fbApi.push(context!, page, name,
          isReplace: isReplace, fadeIn: fadeIn);
    }
    // } catch (e) {
    //   return Future.value();
    // }
  }

  /*
  * 返回上一页
  * */
  static void pop<T extends Object>([T? result]) {
    return fbApi.globalNavigatorKey.currentState!.pop(result);
  }

  /*
  * pop返回到直播间页面路由为止
  *
  * popUtil某些情况会出现爆红错误，所以自己手动记录路由进行返回
  * */
  static void popToLive() {
    if (!routeNamesContainNull.contains(RoutePath.liveRoom)) {
      return;
    }

    /// 【2021 12.15】关闭支付原生页面接口
    /// 3.flutter层，不需要调用之前的关闭支付接口了
    // fbApi.closePayPage();

    /// 取直播路由的索引
    final newRoutersIndex = routeNamesContainNull.indexOf(RoutePath.liveRoom);

    /// 从直播路由到最后一个路由的列表
    final newRoutersData = routeNamesContainNull.sublist(newRoutersIndex);

    /// 拿【从直播路由到最后一个路由的列表】进行forEach，再进行判断是否返回到了直播页面；
    newRoutersData.forEach((_) {
      final popRoute = routeNamesContainNull[routeNamesContainNull.length - 1];
      if (popRoute != RoutePath.liveRoom) {
        pop();
      }
    });
  }
}
