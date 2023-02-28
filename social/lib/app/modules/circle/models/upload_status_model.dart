import 'package:get/get.dart';

class UploadStatus {
  int progress = 0; // 进度
  bool isUploadFail = false; // 上传失败
  UploadStatus({
    this.progress,
    this.isUploadFail = false,
  });
}

class UploadStatusController extends GetxController {
  Map<String, UploadStatus> cache = {};

  static UploadStatusController get to {
    UploadStatusController c;
    if (!Get.isRegistered<UploadStatusController>()) {
      c = Get.put(UploadStatusController());
    } else {
      c = Get.find<UploadStatusController>();
    }
    return c;
  }

  bool isSending(String channelId) {
    if (cache[channelId] == null) return false;
    return !cache[channelId].isUploadFail;
  }

  void updateProgress(String channelId, {int progress = 0}) {
    // 避免sdk 或 上传进度返回计算后出错导致显示严重不符
    if (progress < 0 || progress > 100) return;
    if (cache[channelId] == null) {
      cache[channelId] = UploadStatus(progress: progress);
    } else {
      cache[channelId].progress = progress;
      cache[channelId].isUploadFail = false;
    }
    if (progress == 100) {
      cache[channelId] = null;
    }
    update();
  }

  void delete(String channelId) {
    if (cache[channelId] == null) return;
    cache[channelId] = null;
    update();
  }

  void uploadFail(String channelId) {
    if (cache[channelId] == null) {
      cache[channelId] = UploadStatus();
    }
    cache[channelId].isUploadFail = true;

    update();
  }
}
