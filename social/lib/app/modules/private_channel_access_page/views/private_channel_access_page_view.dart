import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/private_channel_access_page/views/portrait_private_channel_access_page.dart';
import 'package:im/utils/orientation_util.dart';

import '../controllers/private_channel_access_page_controller.dart';
import 'landscape_private_channel_access_page.dart';

class PrivateChannelAccessPageView
    extends GetView<PrivateChannelAccessPageController> {
  @override
  Widget build(BuildContext context) {
    return OrientationUtil.portrait
        ? const PortraitPrivateChannelAccessPage()
        : const LandscapePrivateChannelAccessPage();
  }
}
