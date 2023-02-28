import 'dart:async';

import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle_detail/views/circle_delete_page.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/menu_button/menu_button.dart';
import 'package:im/pages/guild_setting/circle/circle_share/circle_share_item.dart';
import 'package:im/widgets/toast.dart';
import 'package:oktoast/oktoast.dart';

/// * 删除动态的Controller
class CircleDeleteController extends GetxController {
  final CircleDeleteParam param;

  CircleDeleteController(this.param);

  List<CircleDeleteReason> reasonList;

  @override
  void onInit() {
    super.onInit();
    reasonList = [
      CircleDeleteReason(0, '重复或无意义的内容'.tr),
      CircleDeleteReason(1, '恶意引站或带节奏'.tr),
      CircleDeleteReason(2, '侵害他人权益'.tr),
      CircleDeleteReason(3, '广告或虚假信息'.tr),
      CircleDeleteReason(4, '违反法律法规'.tr),
      CircleDeleteReason(5, '其他'.tr, detail: ''),
    ];
  }

  CircleDeleteReason get selReason =>
      reasonList.firstWhere((e) => e.isSelected, orElse: () => null);

  /// * 选中某个删除理由
  void setSelected(CircleDeleteReason reason) {
    final selReason =
        reasonList.firstWhere((e) => e.isSelected, orElse: () => null);
    if (selReason != null && selReason.type == reason.type) return;
    selReason?.isSelected = false;
    reason.isSelected = true;
    update();
  }

  /// * 删除动态
  Future<void> deletePost(CircleDeleteReason selReason) async {
    try {
      if (selReason == null) return;
      String reason = selReason.desc;
      if (selReason.detail != null && selReason.detail.trim().isNotEmpty) {
        reason = selReason.detail.trim();
      }
      await CircleApi.circlePostDelete(
          param.postId, param.channelId, param.topicId,
          reason: reason, showToast: false);
      Toast.iconToast(icon: ToastIcon.success, label: "动态已删除".tr);
      final postInfo = postInfoMap[param.postId];
      postInfo?.setData(deleted: true);
      try {
        CircleController.to.removeItem(param.topicId, param.postId);
        unawaited(CircleController.to.refreshPinnedList());
      } catch (_) {}
      param.onSuccess?.call(MenuButtonType.del);
      Get.back();
    } catch (e) {
      if (e is RequestArgumentError) {
        param.onError?.call(e.code, MenuButtonType.del);
      } else {
        showToast('网络异常，请检查后重试'.tr);
      }
    }
  }
}

/// * 删除动态的理由
class CircleDeleteReason {
  final int type;
  final String desc;
  String detail;
  bool isSelected;

  CircleDeleteReason(this.type, this.desc,
      {this.detail, this.isSelected = false});
}
