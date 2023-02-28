import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';

class CouponsTabBar extends TabBar {
  CouponsTabBar({
    TabController? controller,
    required List<Widget> tabs,
  }) : super(
          isScrollable: true,
          controller: controller,
          indicatorPadding: const EdgeInsets.all(0),
          labelPadding: EdgeInsets.symmetric(horizontal: 12.px),
          labelStyle: TextStyle(
            color: const Color(0xff000000).withOpacity(0.65),
            fontSize: 14.px,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle:
              TextStyle(color: const Color(0xff646A73), fontSize: 14.px),
          indicatorColor: const Color(0xff363940),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: tabs,
        );
}
