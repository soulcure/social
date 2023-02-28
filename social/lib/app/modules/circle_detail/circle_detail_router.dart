import 'package:get/get.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/utils/track_route.dart';

import 'controllers/circle_detail_controller.dart';

enum FindAndRemoveExistingDetailPageResult {
  isCurrent,
  removed,
  notFound,
}

class CircleDetailRouter {
  /// 由于不允许打开相同的详情页所，所以打开详情页有两种特殊情况
  /// 1. 当前页就是指定详情页，则什么都不做
  /// 2. 路由栈中存在指定详情页，则移除旧页面，重新 push 到路由顶层
  static FindAndRemoveExistingDetailPageResult findAndRemoveExistingDetailPage(
      String postId) {
    final currentRoute = PageRouterObserver.instance.topPage;
    if (currentRoute.settings.name == Routes.CIRCLE_DETAIL) {
      final args = currentRoute.settings.arguments as CircleDetailData;
      // 如果当前已经打开了相同的详情页，没必要再打开
      if (args.postId == postId) {
        return FindAndRemoveExistingDetailPageResult.isCurrent;
      }
    }

    // 如果路由栈内有相同的详情页，则移除
    final existingRoute = PageRouterObserver.instance.getRoute((route) =>
        route.settings.name == Routes.CIRCLE_DETAIL &&
        (route.settings.arguments as CircleDetailData).postId == postId);
    if (existingRoute != null) {
      Get.removeRoute(existingRoute);

      /// Get.removeRoute 不会走 bindings 的声明周期
      /// 所以需要手动 delete
      Get.delete<CircleDetailController>(tag: postId);
      return FindAndRemoveExistingDetailPageResult.removed;
    }

    return FindAndRemoveExistingDetailPageResult.notFound;
  }

  static Future push(CircleDetailData data) async {
    switch (findAndRemoveExistingDetailPage(data.postId)) {
      case FindAndRemoveExistingDetailPageResult.isCurrent:
        return;
      case FindAndRemoveExistingDetailPageResult.removed:
      case FindAndRemoveExistingDetailPageResult.notFound:
        break;
    }

    return Get.toNamed(
      Routes.CIRCLE_DETAIL,
      arguments: data,
      preventDuplicates: false,
    );
  }
}
