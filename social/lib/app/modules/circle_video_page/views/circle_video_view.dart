import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle_video_page/components/circle_video_component.dart';
import 'package:im/app/modules/circle_video_page/views/circle_video_page_view.dart';

import '../controllers/circle_video_page_controller.dart';

class CircleVideoView extends StatelessWidget {
  const CircleVideoView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GetBuilder<CircleVideoPageController>(
          builder: (controller) {
            final videoCount = controller.circleVideoController.videoCount;
            if (controller.initComplete && videoCount > 0)
              return CircleVideoPageView(controller);
            else
              return loadingFakeWidget(context);
          },
        ),
      ),
    );
  }
}
