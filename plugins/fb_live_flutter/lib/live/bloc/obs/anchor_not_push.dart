import 'package:fb_live_flutter/live/utils/live/base_bloc.dart';
import 'package:oktoast/oktoast.dart';

///【2021 11.26】
///
///【今天】OBS提示问题：主播正在连线中…，主播使用OBS推流直播，
/// 主播在手机端点击开始后，并没有在OBS软件上点击开始推流，
/// 所以导致拉流端看到了“正创建直播间……”的提示，
/// 提示有问题，应该改为，在检测到没有流回调的信息5秒后，提示“主播正在连线中…”的toast提示。
/// 📈 梦幻家族|fanbook意见反馈/Bug及跟进 - 飞书云文档 (feishu.cn)
///
///
/// obs直播连线中需求：记录5秒内是否拉到流，如果没有拉到的话提示出“主播连线中”，
/// 中途出现任何问题已解决【如网络断开后络恢复】再次判断记录的标识且重新检测；
mixin AnchorNotPush on BaseAppCubit<int>, BaseAppCubitState {
  String inAttachmentTip = "主播正在连线中…";

  /// 是否推送过，默认没推送过
  bool isPushed = false;

  /// 是否显示了loading
  bool isShowAttachmentTip = false;

  /// 是否倒计时完了
  bool isCountdownOver = false;

  /// 开始连线倒计时
  void startAttachment(bool isCanShow, bool isMount) {
    Future.delayed(const Duration(seconds: 5)).then((value) {
      isCountdownOver = true;
      checkAttachmentTip(isCanShow, isMount);
    });
  }

  /// 异常恢复检测
  void restoreCheckAttachment(bool isCanShow, bool isMount) {
    /// 只有5秒倒计时完了才开始再次检测
    if (!isCountdownOver) {
      return;
    }
    checkAttachmentTip(isCanShow, isMount);
  }

  /// 检测是否推流过
  void checkAttachmentTip(bool isCanShow, bool isMount) {
    if (isPushed) {
      return;
    }
    if (isClosed || !isCanShow || !isMount) {
      return;
    }

    /// 【2022 03.13】去除直播连线中，因为没有推流会弹出直播失败
    // myLoadingToast(tips: inAttachmentTip, duration: const Duration(days: 1));
    // isShowAttachmentTip = true;
  }

  /// 设置已推送过
  void setPushed() {
    isPushed = true;
    if (isShowAttachmentTip) {
      dismissAllToast();
      isShowAttachmentTip = false;
    }
  }
}
