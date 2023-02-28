import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

Color toastBgColor = const Color(0xff000000).withOpacity(0.8);

/// dismissAllToast方法需要注意直播间初始化的loading，如果loading后出现了其他提示那么loading就没了
///

/// 专门给一些只有一部分圆的提示使用
void myToastLong(String tips,
    {Duration duration = const Duration(milliseconds: 2000)}) {
  if (!strNoEmpty(tips)) {
    return;
  }

  /// 修复多重提示
  dismissAllToast();

  showToast(
    tips,
    textPadding:
        EdgeInsets.symmetric(horizontal: FrameSize.px(24), vertical: 15.px),
    textStyle: TextStyle(color: const Color(0xffFFFFFF), fontSize: 14.px),
    radius: 8.px,
    backgroundColor: toastBgColor,
    duration: duration,
  );
}

///
/// 需要考虑：
/// "您已被管理员踢出服务器。如果有疑问，请联系管理员"，
/// "主播暂时离开了，Ta有可能是去上厕所了，等等吧"，
/// 的样式问题。
///
void myToast(String? tips,
    {Duration duration = const Duration(milliseconds: 2000)}) {
  if (!strNoEmpty(tips)) {
    return;
  }

  /// 修复多重提示
  dismissAllToast();

  showToast(
    tips!,
    textPadding:

        /// 【2021 11.20】新版样式
        EdgeInsets.symmetric(horizontal: FrameSize.px(20), vertical: 10.px),
    textStyle: TextStyle(color: const Color(0xffFFFFFF), fontSize: 14.px),

    /// 【2021 11.20】新版样式
    radius: 8.px,

    /// 解决一些提示圆角不是全圆的
    backgroundColor: toastBgColor,
    duration: duration,
  );
}

void myFailToast(String? tips,
    {Duration duration = const Duration(milliseconds: 2000)}) {
  if (!strNoEmpty(tips)) {
    return;
  }
  final Widget body = IconToastView(
    tips,
    Image.asset('assets/live/main/tip_close.png', width: 20.px, height: 20.px),
  );

  /// 修复多重提示
  dismissAllToast();

  showToastWidget(UnconstrainedBox(child: body), duration: duration);
}

/*
* 加载中对话框
* */
void myLoadingToast({
  String? tips,

  /// 重提示还是不用去掉吧，先把轻提示的时间延长到30秒吧，反正连接成功就会消失嘛
  Duration duration = const Duration(milliseconds: 30000),

  /// 当提示[duration]结束了而被关闭时执行
  VoidCallback? onComplete,
  double? marginTop,
}) {
  /// 2021 11.20 新版
  final Widget body = IconToastView(
    tips ?? "加载中",
    fbApi.circularProgressIcon(20.px),
  );

  /// 修复多重提示
  dismissAllToast();

  final ToastFuture toastFuture = showToastWidget(
      Container(
        margin: EdgeInsets.only(top: marginTop ?? 0),
        child: UnconstrainedBox(child: body),
      ),
      duration: duration);
  Future.delayed(duration - const Duration(milliseconds: 10)).then((value) {
    /// 为true则表示已销毁，否则表示还显示了
    final bool isDismiss =
        toastFuture.timer == null || !toastFuture.timer!.isActive;
    if (isDismiss) {
      return;
    }
    if (onComplete != null) {
      onComplete();
    }
  });
}

void mySuccessToast(String tips,
    {Duration duration = const Duration(milliseconds: 2000)}) {
  if (!strNoEmpty(tips)) {
    return;
  }
  final Widget body = IconToastView(
    tips,
    Image.asset('assets/live/main/tip_ok.png', width: 20.px, height: 20.px),
  );

  /// 修复多重提示
  dismissAllToast();

  showToastWidget(UnconstrainedBox(child: body), duration: duration);
}

class IconToastView extends StatelessWidget {
  final String? tips;
  final Widget icon;
  final EdgeInsetsGeometry? padding;

  const IconToastView(this.tips, this.icon, {this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(50),
      decoration: BoxDecoration(
        color: toastBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: padding ??
          EdgeInsets.symmetric(horizontal: FrameSize.px(20), vertical: 10.px),
      child: ClipRect(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            Space(width: 8.px),
            Text(
              tips!,
              style: TextStyle(color: const Color(0xffFFFFFF), fontSize: 14.px),
            )
          ],
        ),
      ),
    );
  }
}
