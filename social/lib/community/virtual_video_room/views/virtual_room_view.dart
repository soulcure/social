import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/community/virtual_video_room/controllers/virtual_room_controller.dart';
import 'package:im/community/virtual_video_room/views/widget/bottom_menu.dart';
import 'package:im/community/virtual_video_room/views/widget/video_item_view.dart';
import 'package:im/themes/const.dart';

class VirtualRoomView extends StatefulWidget {
  final VirtualRoomParams roomParams;

  const VirtualRoomView({Key key, this.roomParams}) : super(key: key);

  @override
  _VirtualRoomViewState createState() => _VirtualRoomViewState();
}

class _VirtualRoomViewState extends State<VirtualRoomView> {
  VirtualRoomController controller;
  double horizontalPadding =
      (Get.width - (SMALL_VIDEO_ITEM_WIDTH * 4) - (4 * 3)) / 2;

  @override
  void initState() {
    super.initState();
    print('_VirtualRoomViewState ------------ initState');
    controller = VirtualRoomController.to();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GetBuilder<VirtualRoomController>(
          id: VirtualRoomController.userListObject,
          builder: (c) {
            return Visibility(
              visible: !(c.hideAll?.value ?? false),
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ObxValue<Rx<VideoListSwitchState>>((videoState) {
                      final int length = controller.userLength;
                      debugPrint(
                          'getChat -- build: ${videoState.value}, length：$length');
                      if (videoState.value ==
                          VideoListSwitchState.smallOneRow) {
                        return _buildSmallOneRow();
                      } else if (videoState.value ==
                          VideoListSwitchState.smallThreeRow) {
                        return _buildSmallThreeRow(length);
                      } else if (videoState.value ==
                          VideoListSwitchState.bigTwoMember) {
                        return _buildTwoMember();
                      } else {
                        return _buildBigThreeMoreUser();
                      }
                    }, controller.videoListSwitchState),
                    sizeHeight10,
                    Obx(
                      () => BottomMenu(
                        isHideAll: controller.hideAll.value,
                        isVideoOn: controller.isVideoOn.value,
                        leftState: controller.leftState.value,
                        rightState: controller.rightState.value,
                        fullState: controller.fullState.value,
                        onHideAllClick: controller.onBottomHideAllClick,
                        onVideoClick: controller.onBottomVideoClick,
                        onLeftClick: controller.onBottomLeftClick,
                        onRightClick: controller.onBottomRightClick,
                        onFullClick: controller.onBottomFullClick,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }

  Widget _buildSmallThreeRow(int length) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              (length > 4 && length <= 8) ? 168 : 254, //(82 * 3) + (4 * 2)
        ),
        child: PageView.builder(
          controller: controller.threeRowPageController,
          itemBuilder: (_, i) => _buildSmallGridItem(
              i * 12, length > 12 * (i + 1) ? 12 * (i + 1) : length - 12 * i),
          itemCount: ((length - 1) ~/ 12) + 1,
        ),
      );

  Widget _buildSmallGridItem(int startIndex, int length) =>
      GetBuilder<VirtualRoomController>(
          id: VirtualRoomController.userListObject,
          builder: (c) {
            return GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: length,
                //SliverGridDelegateWithFixedCrossAxisCount 构建一个横轴固定数量Widget
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    //横轴元素个数
                    crossAxisCount: 4,
                    //纵轴间距
                    mainAxisSpacing: 4,
                    //横轴间距
                    crossAxisSpacing: 4),
                itemBuilder: (_, i) {
                  return VideoItemView(
                      isSmallVideo: true,
                      index: startIndex + i,
                      videoUser: controller.users[startIndex + i],
                      onVideoItemClick: controller.onVideoItemClick);
                });
          });

  Widget _buildSmallOneRow() => FractionallySizedBox(
        child: Container(
          alignment: Alignment.center,
          height: SMALL_VIDEO_ITEM_WIDTH,
          child: ListView.separated(
            padding: EdgeInsets.only(
                left: (controller.users?.length ?? 0) > 4
                    ? horizontalPadding
                    : 0),
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            controller: controller.listScrollController,
            itemBuilder: (_, i) {
              return VideoItemView(
                isSmallVideo: true,
                index: i,
                videoUser: controller.users[i],
                onVideoItemClick: controller.onVideoItemClick,
              );
            },
            itemCount: controller.users?.length ?? 0,
            separatorBuilder: (_, __) => const SizedBox(width: 4),
          ),
        ),
      );

  Widget _buildTwoMember() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          VideoItemView(
              isSmallVideo: false,
              index: 0,
              videoUser: controller.users[0],
              onVideoItemClick: controller.onVideoItemClick),
          sizeWidth4,
          if (controller.users.length == 2)
            VideoItemView(
                isSmallVideo: false,
                index: 1,
                videoUser: controller.users[1],
                onVideoItemClick: controller.onVideoItemClick),
        ],
      );

  Widget _buildBigThreeMoreUser() {
    final length = controller.users.length;
    final page = ((length - 1 - 1) ~/ 4) + 1;
    return Column(
      children: [
        VideoItemView(
            isSmallVideo: false,
            index: 0,
            videoUser: controller.users[0],
            onVideoItemClick: controller.onVideoItemClick),
        sizeHeight4,
        SizedBox(
          height: SMALL_VIDEO_ITEM_WIDTH,
          child: PageView.builder(
            itemBuilder: (_, i) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ..._buildPageItems(i * 4 + 1,
                      length > 4 * (i + 1) + 1 ? 4 * (i + 1) + 1 : length),
                ],
              );
            },
            itemCount: page,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPageItems(int startIndex, int endIndex) {
    final List<Widget> allWidget = [];
    print('-------------------startIndex = $startIndex, length = $endIndex');

    for (int i = startIndex; i < endIndex; i++) {
      allWidget.add(VideoItemView(
        isSmallVideo: true,
        index: i,
        videoUser: controller.users[i],
        onVideoItemClick: controller.onVideoItemClick,
      ));
      if (i != endIndex - 1) allWidget.add(sizeWidth4);
    }

    return allWidget;
  }

  @override
  void dispose() {
    super.dispose();
    print('virtualRoomView dispose--------------------------');
  }
}
