import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/pages/home/components/bottom_right_button/bottom_right_button_controller.dart';
import 'package:im/pages/home/view/text_chat_view.dart';
import 'package:im/widgets/load_more.dart';

///消息公屏-底部进度条(菊花)
class BottomLoadingView extends StatelessWidget {
  final String channelId;

  const BottomLoadingView(this.channelId);

  @override
  Widget build(BuildContext context) {
    return GetX<BottomRightButtonController>(
        tag: channelId,
        builder: (c) {
          if (c.loadMoreState.value != LoadMoreStatus.noMore) {
            return const Padding(
              padding: EdgeInsets.all(8),
              child: CupertinoActivityIndicator.partiallyRevealed(),
            );
          } else {
            return const SizedBox(height: TextChatViewBottomPadding, width: 1);
          }
        });
  }
}
