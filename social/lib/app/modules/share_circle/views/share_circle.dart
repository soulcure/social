import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/share_circle/controllers/share_circle_controller.dart';
import 'package:im/app/modules/share_circle/views/landscape_share_circle_state.dart';
import 'package:im/app/modules/share_circle/views/portrait_share_circle_state.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/web/widgets/slider_sheet/show_slider_sheet.dart';

class ShareCircle extends StatefulWidget {
  static Future showCircleShareDialog(ShareBean shareBean) =>
      OrientationUtil.portrait
          ? Get.bottomSheet(
              ShareCircle(
                shareBean: shareBean,
              ),
              backgroundColor: Get.theme.backgroundColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10)),
              ),
              isScrollControlled: true)
          : shareBean.isLandFromCircleDetail
              ? showSliderModal(
                  Get.context,
                  body: ShareCircle(shareBean: shareBean),
                  direction: SliderDirection.rightDown,
                )
              : Get.dialog(ShareCircle(shareBean: shareBean));

  final ShareBean shareBean;
  const ShareCircle({Key key, this.shareBean}) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() => OrientationUtil.portrait
      ? PortraitShareCircleState(shareBean)
      : LandScapeShareCircleState(shareBean);
}
