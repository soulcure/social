import 'package:flutter/material.dart';
import 'package:im/widgets/share_link_popup/setting/share_link_setting_popup.dart';

import 'setting/share_link_setting_deadline.dart';
import 'setting/share_link_setting_remark.dart';
import 'setting/share_link_setting_times.dart';

final shareLinkKey = GlobalKey<NavigatorState>();

class ShareLinkNavigator extends StatefulWidget {
  final Widget Function(BuildContext) builder;
  const ShareLinkNavigator({this.builder});
  @override
  ShareLinkNavigatorState createState() => ShareLinkNavigatorState();
}

class ShareLinkNavigatorState extends State<ShareLinkNavigator> {
  static const linkHome = '/link/home';
  static const linkHomeSetting = '/link/home/setting';
  static const linkHomeSettingDeadline = '/link/home/setting/deadline';
  static const linkHomeSettingTimes = '/link/home/setting/times';
  static const linkHomeSettingRemark = '/link/home/setting/remark';

  Route _wrapper({@required Widget child, @required RouteSettings settings}) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 150),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset.zero,
                  end: const Offset(-1, 0),
                ).animate(secondaryAnimation),
                child: child),
          ),
        );
      },
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: shareLinkKey,
      initialRoute: linkHome,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case linkHome:
            return _wrapper(
              settings: settings,
              child: widget.builder(context),
            );
          case linkHomeSetting:
            final ShareLinkSettingParam arguments = settings.arguments;
            return _wrapper(
              settings: settings,
              child: ShareLinkSettingPopup(param: arguments),
            );
          case linkHomeSettingDeadline:
            final int deadline = settings.arguments;
            return _wrapper(
              settings: settings,
              child: ShareLinkSettingDeadline(
                defaultDeadLine: deadline,
              ),
            );
          case linkHomeSettingTimes:
            final int times = settings.arguments;
            return _wrapper(
              settings: settings,
              child: ShareLinkSettingTimes(
                defaultDeadLine: times,
              ),
            );
          case linkHomeSettingRemark:
            final String remark = settings.arguments;
            return _wrapper(
              settings: settings,
              child: ShareLinkSettingRemark(
                initContent: remark,
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}
