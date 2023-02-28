import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/models/upload_status_model.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/db/db.dart';
import 'package:im/icon_font.dart';
import 'package:just_throttle_it/just_throttle_it.dart';

class PortraitCreateMomentButton extends StatelessWidget {
  const PortraitCreateMomentButton({Key key}) : super(key: key);

  CircleController get circleController => Get.find<CircleController>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UploadStatusController>(
        init: UploadStatusController.to,
        builder: (controller) {
          final status = controller.cache[circleController.channelId];
          final canSend = status == null || status.isUploadFail;
          return Visibility(
            visible: canSend,
            child: Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: appThemeData.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: appThemeData.primaryColor.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Throttle.milliseconds(
                          2000, CircleController.to.createMoment);
                    },
                    icon: const Icon(
                      IconFont.buffTianjia,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                ValueListenableBuilder<Box>(
                  valueListenable: Db.circleDraftBox
                      .listenable(keys: [circleController.channelId]),
                  builder: (context, box, child) {
                    final hasDraft =
                        box.get(circleController.channelId) != null;
                    if (hasDraft)
                      return child;
                    else
                      return const SizedBox();
                  },
                  child: Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        height: 10,
                        width: 10,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.redAccent),
                      )),
                ),
              ],
            ),
          );
        });
  }
}
