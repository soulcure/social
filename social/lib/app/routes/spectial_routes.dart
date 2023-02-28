import 'package:get/get.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/pages/home/view/check_permission.dart';
import 'package:im/utils/check_media_conflict_util.dart';
import 'package:permission_handler/permission_handler.dart';

/// 这里定义了无法直接使用命名路由的路由，例如需要一些前置检查
class SpectialRoutes {
  static Future openQrScanner() async {
    final purpose = "使用扫码功能".tr;

    /// 检测是否正在直播，并提示用户退出直播间
    final isExitLiveRoom = await checkAndExitLiveRoom(
      onlyStreamer: true,
      purpose: purpose,
    );
    if (!isExitLiveRoom) {
      /// 用户选择继续待在直播间
      return;
    }

    /// 检测是否正在视频频道，并提示用户退出
    final isExitVideoChannel = await checkAndExitAVChannel(
      onlyVideo: true,
      purpose: purpose,
    );
    if (!isExitVideoChannel) {
      /// 用户选择继续停留在视频频道
      return;
    }

    /// 检查摄像头权限
    final isAuth = await checkSystemPermissions(
      context: Get.context,
      permissions: [Permission.camera],
    );
    if (!isAuth) return;

    return Get.toNamed(Routes.SCAN_QR_CODE);
  }
}
