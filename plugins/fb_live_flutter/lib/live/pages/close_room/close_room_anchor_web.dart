import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/model/colse_room_model.dart';
import 'package:fb_live_flutter/live/model/room_infon_model.dart';
import 'package:fb_live_flutter/live/pages/room_list/widget/share_link.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/nil.dart';
import 'package:fb_live_flutter/live/utils/theme/my_theme.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/bloc/close_room/close_room_logic.dart';
import 'package:fb_live_flutter/live/widget_common/button/sw_web_button.dart';
import 'package:fb_live_flutter/live/widget_common/dialog/sw_web_dialog.dart';

class CloseRoomAnchorWeb extends StatefulWidget {
  final CloseRoomModel? closeRoomModel;
  final RoomInfon? roomInfoObject;

  const CloseRoomAnchorWeb({this.closeRoomModel, this.roomInfoObject});

  @override
  _CloseRoomAnchorWebState createState() => _CloseRoomAnchorWebState();
}

class _CloseRoomAnchorWebState extends State<CloseRoomAnchorWeb>
    with CloseRoomLogic {
  List get list {
    return [
      [UtilsClass.calcNum(widget.closeRoomModel?.audience ?? 0), '观看次数'],
      [UtilsClass.calcNum(widget.closeRoomModel?.thumbCount ?? 0), '点赞数'],
      [
        UtilsClass.calcNum(int.parse(widget.closeRoomModel?.coin ?? "0")),
        '乐豆数'
      ],
    ];
  }

  @override
  void initState() {
    super.initState();
    closeRoomModel = widget.closeRoomModel;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: FrameSize.winWidth(),
          decoration: BoxDecoration(
            image: DecorationImage(
              image:
                  CachedNetworkImageProvider(widget.roomInfoObject!.avatarUrl!),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          width: FrameSize.winWidth(),
          height: FrameSize.winHeight(),
          color: Colors.black.withOpacity(0.8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '直播结束',
                style: TextStyle(
                  fontSize: 24.px,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16.px),
              Text(
                () {
                  if (isLessOneMin) {
                    return '直播时间较短，将不会生成回放';
                  } else if (widget.roomInfoObject!.status == 4) {
                    return '直播可能存在不良信息，可前往回放观看内容';
                  } else {
                    return '回放将在几分钟之后生成';
                  }
                }(),
                style: TextStyle(
                  fontSize: 14.px,
                  color: Colors.white.withOpacity(0.49),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 40.px),
                child: Text(
                  '你的直播很精彩，期待下次直播！',
                  style: TextStyle(
                    fontSize: 24.px,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '用户昵称 的直播',
                style: TextStyle(
                  fontSize: 16.px,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              SizedBox(height: 16.px),
              Text(
                '直播时长$timeStr',
                style: TextStyle(
                  fontSize: 16.px,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 80.px),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(list.length, itemBuilder),
              ),
              SizedBox(height: 52.px),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SwWebButton(
                    text: '关闭',
                    bgColor: MyTheme.transparent,
                    isBorder: true,
                    isSpace:
                        !isLessOneMin || widget.roomInfoObject!.status == 4,
                    width: 100.px,
                    height: 32.px,
                    isBold: false,
                  ),
                  if (isLessOneMin || widget.roomInfoObject!.status == 4)
                    const Nil()
                  else
                    SwWebButton(
                      text: '分享回放',
                      width: 100.px,
                      height: 32.px,
                      isBold: false,
                      isPop: false,
                      bgColor: MyTheme.blueColor,
                      onPressed: () {
                        confirmSwWebDialog(
                          context,
                          title: '邀请好友观看直播回放',
                          isNoButton: true,
                          isCloseIcon: true,
                          child: ShareLink(),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget itemBuilder(int index) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 32.px),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                list[index][0],
                style: TextStyle(
                  fontSize: 24.px,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10.px),
              Text(
                list[index][1],
                style: TextStyle(
                  fontSize: 14.px,
                  color: Colors.white.withOpacity(0.49),
                ),
              ),
            ],
          ),
          if (index == list.length - 1)
            const Nil()
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 37.px),
              child: VerticalLine(
                color: Colors.white.withOpacity(0.5),
                height: 32.px,
              ),
            ),
        ],
      ),
    );
  }
}
