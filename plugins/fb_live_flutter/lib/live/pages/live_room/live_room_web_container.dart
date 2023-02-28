import 'package:fb_live_flutter/live/bloc/with/live_mix.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc_model/online_user_count_bloc_model.dart';
import 'live_room_web.dart';
import 'widget/online_userlist_widget.dart';

class LiveRoomWebContainer extends StatefulWidget {
  final String roomId;
  final bool? isWebFlip;

  // 是否来自直播列表页面
  final bool? isFromList;
  final LiveValueModel? liveValueModel;

  const LiveRoomWebContainer({
    Key? key,
    required this.roomId,
    this.isWebFlip,
    this.isFromList,
    required this.liveValueModel,
  }) : super(key: key);

  @override
  _LiveRoomWebContainerState createState() => _LiveRoomWebContainerState();
}

class _LiveRoomWebContainerState extends State<LiveRoomWebContainer> {
  bool? _isAnchor;
  RoomInfon? roomInfoObject; //房间信息对象

  @override
  void initState() {
    _isAnchor = widget.liveValueModel!.isAnchor;
    super.initState();
    getRoomInfo();
  }

  Future getRoomInfo() async {
    final Map resultData = await Api.getRoomInfo(widget.roomId);
    if (resultData["code"] == 200) {
      roomInfoObject = RoomInfon.fromJson(resultData["data"]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<OnlineUserCountBlocModel>(
          create: (context) {
            return OnlineUserCountBlocModel(0);
          },
        ),
      ],
      child: Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LiveRoomWeb(
                isAnchor: _isAnchor,
                roomId: widget.roomId,
                isWebFlip: widget.isWebFlip,
                roomLogo: widget.liveValueModel?.roomInfoObject?.roomLogo ??
                    roomInfoObject!.roomLogo,
                refreshCallBlock: (value) {
                  setState(() {
                    _isAnchor = value;
                  });
                },
                liveValueModel: widget.liveValueModel,
              ),
            ),
            SizedBox(
              width: 250,
              child: OnlineUserList(
                roomId: widget.roomId,
                isAnchor: _isAnchor,
                roomInfoObject: roomInfoObject!,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
