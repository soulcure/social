import 'dart:convert';

import 'package:dynamic_view/widgets/models/widgets.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/scan_qr_code/controllers/scan_qr_code_controller.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/pages/home/json/message_card_entity.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:oktoast/oktoast.dart';

class DynamicViewPreviewController extends GetxController {
  WidgetData widgetData;
  String error;

  void preview(String code) {
    try {
      widgetData = WidgetData.fromJson(jsonDecode(code));
      error = null;
    } catch (e, s) {
      error = "$e\n$s";
    }
    update();
  }

  @override
  void onInit() {
    Clipboard.getData(Clipboard.kTextPlain).then((value) {
      if (value != null) preview(value.text);
    });

    super.onInit();
  }

  Future<void> scanQrCode() async {
    final code = await Get.toNamed(Routes.SCAN_QR_CODE,
        arguments: ScanQrCodeArgs(autoProcess: false));
    if (code != null) {
      preview(code);
    }
  }

  void sendToCurrentChannel() {
    if (error != null) {
      showToast("请输入正确的数据");
      return;
    }
    final channel = GlobalState.selectedChannel.value;

    if (channel == null) {
      showToast("请选择一个频道");
      return;
    }
    // 尝试解码出动态组件，这是一个调试功能，为了方便地发出动态视图
    TextChannelController.to(channelId: channel.id).sendContent(
      MessageCardEntity(data: jsonEncode(widgetData)),
    );
    showToast("已发送至当前频道");
  }
}
