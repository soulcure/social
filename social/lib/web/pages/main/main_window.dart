import 'package:flutter/material.dart';
import 'package:im/app/modules/circle/views/circle_view.dart';
import 'package:im/app/modules/friend_list_page/views/friend_list_page_view.dart';
import 'package:im/app/routes/app_pages.dart' as get_pages show Routes;
import 'package:im/routes.dart';
import 'package:im/web/pages/main/main_model.dart';
import 'package:im/widgets/custom_route_page/custom_route_builder.dart';
import 'package:im/widgets/custom_route_page/custom_route_model.dart';
import 'package:provider/provider.dart';

class MainWindow extends StatefulWidget {
  final Widget defaultChild;
  const MainWindow({this.defaultChild});
  @override
  _MainWindowState createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  CustomRouteModel get model => MainRouteModel.instance;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
        value: model,
        child: CustomRouteBuilder(
          builder: (context, route) {
            switch (route.route) {
              case circleMainPageRoute:
                return CircleView();
                // return CircleMainPage(
                //   route.item2['guildId'],
                //   route.item2['channelId'],
                //   topicId: route.item2['topicId'],
                //   commentId: route.item2['commentId'],
                //   postId: route.item2['postId'],
                //   circleType: route.item2['circleType'],
                // );
                break;
              case get_pages.Routes.FRIEND_LIST_PAGE:
                return const FriendListPageView();
                break;
              default:
                break;
            }
            return null;
          },
          defaultChild: widget.defaultChild,
        ));
  }
}
