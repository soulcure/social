import 'package:draggable_float_widget/draggable_float_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_unity/flutter_unity.dart';
import 'package:get/get.dart';
import 'package:im/community/interactive_entity/controllers/interactive_entity_controller.dart';
import 'package:im/community/unity_bridge_controller.dart';
import 'package:im/community/virtual_video_room/controllers/virtual_room_controller.dart';
import 'package:im/community/virtual_video_room/views/virtual_room_view.dart';
import 'package:im/svg_icons.dart';
import 'package:websafe_svg/websafe_svg.dart';

class UnityViewPage extends StatefulWidget {
  @override
  _UnityViewPageState createState() => _UnityViewPageState();
}

class _UnityViewPageState extends State<UnityViewPage>
    with WidgetsBindingObserver {
  UnityBridgeController _unityBridgeController;
  VirtualRoomController controller;

  @override
  void initState() {
    super.initState();
    controller = VirtualRoomController.to();
    //SystemChrome.setEnabledSystemUIOverlays([]);
    _unityBridgeController = UnityBridgeController(context);
  }

  @override
  void dispose() {
    //SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    _unityBridgeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _unityBridgeController?.sendToUnity("OnWillPop", "");
        return null;
      },
      child: Stack(
        children: [
          Listener(
            onPointerCancel: (e) {
              _unityBridgeController?.sendToUnity("OnTouchCanceled", "");
            },
            child: GestureDetector(
              onTap: () {}, //规避多点触控导致PlatformView卡死问题
              child: UnityView(
                onCreated: onUnityViewCreated,
                onReattached: onUnityViewReattached,
                onMessage: onUnityViewMessage,
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: _unityBridgeController.unityViewPageProgress,
            builder: (context, progress, child) => Visibility(
                visible: progress == UnityViewPageProgress.UNLOADING ||
                    (progress == UnityViewPageProgress.LOADING &&
                        (_unityBridgeController.isFirstStartup ||
                            _unityBridgeController.isCommunityRunning)),
                child: child),
            child: Container(
              width: Get.width,
              height: Get.height,
              decoration: const BoxDecoration(color: Color(0xff181d4d)),
            ),
          ),
          _buildInteractiveEntity(true),
          Column(
            children: [
              _buildVirtualRoomView(),
              _buildInteractiveEntity(false),
            ],
          ),

          //悬浮按钮
          _buildVirtualRoomDisplayAllBtn(),
        ],
      ),
    );
  }

  Widget _buildVirtualRoomView() {
    return Obx(() => Visibility(
        visible: controller.showVideoUi?.value,
        child: const VirtualRoomView()));
  }

  Widget _buildVirtualRoomDisplayAllBtn() {
    return Obx(
      () => Visibility(
        visible: controller.hideAll?.value ?? false,
        child: DraggableFloatWidget(
          config: const DraggableFloatWidgetBaseConfig(
            initPositionYMarginBorder: 200,
            borderTop: 20,
            borderBottom: 30,
          ),
          onTap: () => controller.onBottomDisplayAllClick(),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(
              Radius.circular(8),
            ),
            child: Container(
              color: Colors.black54,
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: WebsafeSvg.asset(SvgIcons.virtualDisplayAll,
                  width: 24, height: 24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveEntity(bool isFullScreen) {
    final entity = InteractiveEntityController.get().currentEntity;
    return Obx(() => Visibility(
        visible: entity.value?.isFullScreen == isFullScreen,
        child: entity.value == null
            ? const SizedBox()
            : entity.value.buildWidget(context)));
  }

  void onUnityViewCreated(UnityViewController controller) {
    print('onUnityViewCreated');
    _unityBridgeController.setUnityViewController(controller);
  }

  void onUnityViewReattached(UnityViewController controller) {
    print('onUnityViewReattached');
  }

  void onUnityViewMessage(UnityViewController controller, String message) {
    print('onUnityViewMessage:$message');
    _unityBridgeController?.onUnityMessage(message);
  }
}
