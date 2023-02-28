import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/icon_font.dart';
import 'package:im/services/sp_service.dart';
import 'package:super_tooltip/super_tooltip.dart';

class LandscapeCreateMomentButton extends StatefulWidget {
  const LandscapeCreateMomentButton({Key key}) : super(key: key);

  @override
  _LandscapeCreateMomentButtonState createState() =>
      _LandscapeCreateMomentButtonState();
}

class _LandscapeCreateMomentButtonState
    extends State<LandscapeCreateMomentButton> {
  bool _isPublished = false;
  SuperTooltip _toolTip;

  @override
  void initState() {
    _isPublished = SpService.to.getBool(SP.publishMoment) ?? false;
    if (!_isPublished) {
      _toolTip = SuperTooltip(
          arrowTipDistance: 30,
          arrowBaseWidth: 10,
          arrowLength: 4,
          backgroundColor: Colors.black,
          content: Text(
            '发布你的第一条动态'.tr,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
          containsBackgroundOverlay: false,
          touchThroughAreaCornerRadius: 18,
          hasShadow: false,
          minimumOutSidePadding: 4,
          popupDirection: TooltipDirection.up);
    }
    super.initState();
  }

  Widget _toolTipWrapper({Widget child}) {
    if (_isPublished)
      return child;
    else
      return Builder(builder: (context) {
        return MouseRegion(
          onEnter: (_) {
            if (!_toolTip.isOpen) _toolTip.show(context);
          },
          onExit: (_) {
            if (_toolTip.isOpen) _toolTip.close();
          },
          child: child,
        );
      });
  }

  /// 发布完消息后需要处理一下
  void createdHandler() {
    SpService.to.setBool(SP.publishMoment, true);
    _isPublished = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_unnecessary_containers
    return Container(
        height: 70,
        constraints: const BoxConstraints(maxWidth: 52, maxHeight: 102),
        alignment: Alignment.topRight,
        child: _toolTipWrapper(
          child: FloatingActionButton(
            onPressed: () {
              if (_toolTip?.isOpen ?? false) _toolTip?.close();
              CircleController.to.createMoment();
              createdHandler();
            },
            child: const Icon(IconFont.buffCircleDynamicEdit,
                size: 25, color: Colors.white),
          ),
        ));
  }
}
