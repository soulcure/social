import 'package:flutter/material.dart';
import 'package:im/app/modules/friend_list_page/views/protrait_friend_list_page_view.dart';
import 'package:im/utils/orientation_util.dart';

import 'landscape_friend_list_page_view.dart';

class FriendListPageView extends StatelessWidget {
  const FriendListPageView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrientationUtil.portrait
        ? const PortraitFriendListPageView()
        : const LandscapeFriendListPageView();
  }
}
