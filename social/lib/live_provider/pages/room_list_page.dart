import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/pages/room_list/room_list.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';

/// 频道内直播点击后进入的直播列表页面
/// UI结构不一样，所以这里再封装一下供Fanbook用
class RoomListPage extends StatefulWidget {
  const RoomListPage({Key key}) : super(key: key);

  @override
  _RoomListPageState createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final orientation = mq.orientation;
    final marginToTop = (orientation == Orientation.portrait
            ? HomeScaffoldController.to.windowPadding
            : 0) +
        mq.padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Container(
        margin: EdgeInsets.only(top: marginToTop),
        child: const RoomList(),
      ),
    );
  }
}
