import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';

class LoadingTextView extends StatelessWidget {
  final String? text;

  const LoadingTextView([this.text]);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text ?? '正在加载…',
        style: TextStyle(color: const Color(0xff646A73), fontSize: 14.px),
      ),
    );
  }
}
