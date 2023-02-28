import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/model/online_user_count.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/pages/live_room/interface/live_interface.dart';
import 'package:fb_live_flutter/live/utils/other/fb_api_model.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../utils/func/utils_class.dart';

class TopThirdView extends StatefulWidget {
  final List<Users> dataList;
  final RoomInfon? roomInfoObject;
  final LiveInterface countBloc;

  const TopThirdView({Key? key,
    required this.dataList,
    this.roomInfoObject,
    required this.countBloc})
      : super(key: key);

  @override
  _TopThirdViewState createState() => _TopThirdViewState();
}

class _TopThirdViewState extends State<TopThirdView> {
  final List<Color> _colorList = [
    const Color(0xFFFFB700).withOpacity(0.9),
    const Color(0xFFA3A8BF).withOpacity(0.9),
    const Color(0xFFCCA670).withOpacity(0.9),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(children: _getUserWidget());
  }

  List<Widget> _getUserWidget() {
    return List.generate(widget.dataList.length, (index) {
      return Stack(
        children: [
          ClickEvent(
            onTap: () async {
              await widget.countBloc.rotationHandle(false);
              // 调用用户信息
              if (!(widget.dataList[index].isGuest ?? false)) {
                await FbApiModel.showUserInfoPopUp(
                    fbApi.globalNavigatorKey.currentContext,
                    widget.dataList[index].userId,
                    widget.roomInfoObject?.serverId);
              }
            },
            child: Stack(
              children: [
                Container(
                  width: FrameSize.px(34),
                  height: FrameSize.px(30),
                  padding: EdgeInsets.only(left: FrameSize.px(4)),
                  child: widget.dataList[index].avatarUrl == null ||
                      widget.dataList[index].userId == null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(FrameSize.px(15)),
                    child: Image(image: fbApi.getFanbookIcon()),
                  )
                      : fbApi.realtimeAvatar(
                    widget.dataList[index].userId!,
                    size: FrameSize.px(30),
                    showNftFlag: false,
                  ),
                ),
                Positioned(
                  right: FrameSize.px(4),
                  bottom: 0,
                  child: Container(
                    alignment: Alignment.center,
                    width: FrameSize.px(22),
                    height: FrameSize.px(12),
                    decoration: BoxDecoration(
                      color: _colorList[index],
                      borderRadius: BorderRadius.circular(FrameSize.px(6)),
                    ),
                    child: Text(
                      UtilsClass.calcNum(widget.dataList[index].coin ?? 0),
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }
}
