import 'package:dynamic_view/widgets/views/widget_views.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/text_chat/items/components/message_card.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/realtime_user_info.dart';

import '../controllers/dynamic_view_preview_controller.dart';

class DynamicViewPreviewView extends GetView<DynamicViewPreviewController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.theme.backgroundColor,
      appBar: FbAppBar.custom("动态卡片预览", actions: [
        AppBarIconActionModel(IconFont.buffScanQr,
            actionBlock: controller.scanQrCode),
      ]),
      body: GetBuilder<DynamicViewPreviewController>(builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    OutlinedButton(
                        onPressed: controller.sendToCurrentChannel,
                        child: const Text("发送到当前频道")),
                    const SizedBox(width: 8),
                    if (GlobalState.selectedChannel.value != null)
                      Expanded(
                          child: RealtimeChannelName(
                              GlobalState.selectedChannel.value.id)),
                  ],
                ),
                const Divider(height: 32),
                Expanded(
                  child: Center(
                    child: controller.widgetData == null
                        ? Text(controller.error ?? "剪切板没有数据或者数据错误")
                        : MessageCard(
                            child: DynamicView.fromData(controller.widgetData)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
