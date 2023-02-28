import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';

class CreateTitleWidget extends StatelessWidget {
  final String? title;

  const CreateTitleWidget(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.px, top: 16.px),
      child: Text(
        title ?? '标题',
        style: TextStyle(color: const Color(0xff8F959E), fontSize: 14.px),
      ),
    );
  }
}
