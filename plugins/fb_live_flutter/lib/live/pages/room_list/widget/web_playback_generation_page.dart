import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/model/room_list_model.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';
import 'package:fb_live_flutter/live/widget_common/view/blurred_picture.dart';

///回放生成中
class WebPlaybackGenerationPage extends StatelessWidget {
  final RoomListModel? item;

  const WebPlaybackGenerationPage({this.item});

  @override
  Widget build(BuildContext context) {
    return BlurredPicture(
      backgroundImage: item?.roomLogo,
      child: Stack(
        children: [
          Positioned(
              top: 30.px,
              right: 30.px,
              child: SwImage(
                'assets/live/main/close.png',
                width: 24.px,
                height: 24.px,
                color: const Color(0xffF24848),
                onTap: () async {
                  RouteUtil.pop();
                },
              )),
          Center(
            child: Text(
              '回放生成中，请稍后观看',
              style: TextStyle(
                fontSize: 24.px,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
