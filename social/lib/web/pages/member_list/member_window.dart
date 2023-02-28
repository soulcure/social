import 'package:flutter/material.dart';
import 'package:im/app/routes/app_pages.dart' as get_pages;
import 'package:im/pages/home/pin_list_page.dart';
import 'package:im/pages/member_list/model/member_list_route_model.dart';
import 'package:im/pages/topic/topic_page.dart';
import 'package:im/routes.dart';
import 'package:im/widgets/custom_route_page/custom_route_builder.dart';
import 'package:im/widgets/custom_route_page/custom_route_model.dart';
import 'package:provider/provider.dart';

class MemberWindow extends StatefulWidget {
  final Widget defaultChild;

  const MemberWindow({this.defaultChild});

  @override
  _MemberWindowState createState() => _MemberWindowState();
}

class _MemberWindowState extends State<MemberWindow> {
  CustomRouteModel get model => MemberListRouteModel.instance;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: model,
      builder: (context, child) {
        return CustomRouteBuilder(
          builder: (context, route) {
            switch (route.route) {
              case get_pages.Routes.TOPIC_PAGE:
                return TopicPage(
                    message: route.params['message'],
                    gotoMessageId: route.params['gotoMessageId']);
                break;
              case pinListRoute:
                return const PinListPage();
                break;
              default:
                break;
            }
            return null;
          },
          defaultChild: SizedBox(
            width: 220,
            child: widget.defaultChild,
          ),
        );
      },
    );
  }
}
