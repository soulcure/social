import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:im/pages/video/model/video_room_controller.dart';

import '../../../icon_font.dart';

class VideoTopBar extends StatefulWidget {
  final VideoRoomController _videoRoomController;

  @override
  State<VideoTopBar> createState() => _VideoTopBarState();

  const VideoTopBar(this._videoRoomController);
}

class _VideoTopBarState extends State<VideoTopBar> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const _textColor = Colors.white;
    final double _statusBarHeight = MediaQuery.of(context).padding.top;
    final double _screenWidth = MediaQuery.of(context).size.width;
    return GetBuilder<VideoRoomController>(
        init: widget._videoRoomController,
        builder: (c) {
          return SafeArea(
            child: Stack(
              children: <Widget>[
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  top: c.hideToolbar.value ? -(_statusBarHeight + 50) : 0,
                  curve: Curves.fastOutSlowIn,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xff000201),
                    ),
                    child: SizedBox(
                      width: _screenWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 11, bottom: 11),
                            child: Stack(
                              alignment: AlignmentDirectional.center,
                              children: <Widget>[
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 12),
                                    child: InkWell(
                                        onTap: () {
                                          Get.back();
                                        },
                                        child: const Icon(
                                          IconFont.buffVideoZoom,
                                          size: 22,
                                          color: _textColor,
                                        )),
                                  ),
                                ),
                                Align(
                                  child: Text(
                                    c.roomName,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: _textColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Obx(() {
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Visibility(
                                            visible: c.isHideScreenShareView(),
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                  right: 12),
                                              child: InkWell(
                                                onTap: () {
                                                  widget._videoRoomController
                                                      .hideShareScreen();
                                                },
                                                child: Image.asset(
                                                  'assets/images/video_share_close.png',
                                                  height: 22,
                                                  width: 22,
                                                ),
                                              ),
                                            )),
                                        Visibility(
                                            visible: c.enableVideo.value,
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                  right: 12),
                                              child: InkWell(
                                                  onTap: () {
                                                    widget._videoRoomController
                                                        .switchCamera();
                                                  },
                                                  child: const Icon(
                                                    IconFont
                                                        .buffVideoCameraReverse,
                                                    size: 22,
                                                    color: _textColor,
                                                  )),
                                            )),
                                      ],
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                          const Divider(
                            color: Color(0x335C6273),
                            height: 1,
                            thickness: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }
}
