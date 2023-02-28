import 'package:flutter/material.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/routes/app_pages.dart' as get_pages show Routes;
import 'package:im/routes.dart';

class RouteModel {
  final String route;
  final Map params;
  final dynamic args;

  const RouteModel(
    this.route, {
    this.params,
    this.args,
  });
}

class CustomRouteModel with ChangeNotifier {
  @protected
  final List<RouteModel> _routes = [const RouteModel('')];

  List<RouteModel> get routes => _routes;

  void pushCirclePage(String guildId, String channelId,
      {bool autoPushCircleMessage = false}) {
    goBack();
    const String route = circleMainPageRoute;
    final param = CircleControllerParam(
      guildId,
      channelId,
      autoPushCircleMessage: autoPushCircleMessage,
    );
    _routes.add(RouteModel(route, args: param));
    notifyListeners();
  }

  void pushFriendListPage() {
    goBack();

    const String route = get_pages.Routes.FRIEND_LIST_PAGE;
    _routes.add(const RouteModel(route));
    notifyListeners();
  }

  void pushPinPage() {
    goBack();

    const String route = pinListRoute;
    _routes.add(const RouteModel(route));
    notifyListeners();
  }

  void goBack() {
    if (_routes.length > 1) {
      _routes.removeLast();
      notifyListeners();
    }
  }
}
