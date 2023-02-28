import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:im/pages/video/model/video_room_controller.dart';
import 'package:im/themes/const.dart';

class VideoShareView extends StatefulWidget {
  const VideoShareView({Key key}) : super(key: key);

  @override
  State<VideoShareView> createState() => _VideoShareViewState();
}

class _VideoShareViewState extends State<VideoShareView> {
  final VideoRoomController _videoRoomController =
      Get.find<VideoRoomController>(tag: VideoRoomController.sRoomId);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff202020),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/share_default_new.png',
                  height: 56,
                  width: 56,
                ),
                sizeHeight12,
                Text(
                  "你正在共享屏幕".tr,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: const TextStyle(
                      fontSize: 18, height: 1.4, color: Colors.white),
                ),
                sizeHeight2,
                Text(
                  "你可以切换至其他应用与你的好友们共享".tr,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: const TextStyle(
                      fontSize: 15, height: 1.4, color: Color(0xbbffffff)),
                ),
                const SizedBox(height: 36),
                ElevatedButton(
                  style: ButtonStyle(
                      padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(
                              horizontal: 64, vertical: 9)),
                      textStyle: MaterialStateProperty.all(
                          const TextStyle(fontSize: 14)),
                      backgroundColor:
                          MaterialStateProperty.all(const Color(0xffF2494A))),
                  child: Text('停止共享'.tr),
                  onPressed: () {
                    _videoRoomController.closeScreenShare();
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
