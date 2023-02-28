import 'package:flutter/material.dart';
import 'package:im/app/modules/direct_message/views/landscape_direct_message_view.dart';
import 'package:im/app/modules/direct_message/views/portrait_direct_message_view.dart';
import 'package:im/utils/orientation_util.dart';

class DirectMessageView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OrientationUtil.portrait
        ? const PortraitDirectMessageView()
        : const LandscapeDirectMessageView();
  }
}
