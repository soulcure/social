import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/bloc_model/tips_login_bloc_model.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 蓝色的XXX来了：渐缓出现，减缓消失（现在是没有任何动效
/// 动效脚本：300ms淡现，停留1秒，500ms淡出
class TipsLoginView extends StatefulWidget {
  final FBUserInfo? userInfo;
  final VoidCallback? animationCompete;

  const TipsLoginView({
    Key? key,
    this.userInfo,
    this.animationCompete,
  }) : super(key: key);

  @override
  _TipsLoginViewState createState() => _TipsLoginViewState();
}

class _TipsLoginViewState extends State<TipsLoginView>
    with TickerProviderStateMixin {
  Animation<double>? animationLogin;
  AnimationController? controller;

  @override
  void dispose() {
    controller?.dispose();
    controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userInfo == null) {
      controller?.dispose();
      controller = null;
      return Container(
        height: FrameSize.px(24),
      );
    }
    if (controller != null) {
      controller?.dispose();
      controller = null;
    }
    controller = AnimationController(
      /// 动画进入事件
      duration: const Duration(milliseconds: 300),

      /// 动画回放事件
      reverseDuration: const Duration(milliseconds: 500),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && controller != null) {
          /// 停留1秒再回放动画
          Future.delayed(const Duration(seconds: 1)).then((value) {
            controller?.reverse().then((value) {
              controller?.stop();
              widget.animationCompete?.call();
            });
          });
        }
      });

    animationLogin = Tween<double>(begin: 0, end: 1).animate(controller!);
    controller!.forward();

    return BlocBuilder<TipsLoginBlocModel, bool?>(
      builder: (context, isShow) {
        /// 【2022 01.04】
        /// 横屏隐藏动画/来了
        if (FrameSize.isHorizontal()) {
          return Container();
        }
        if (!(isShow ?? true)) {
          return Container();
        }
        return FadeTransition(
          opacity: controller!,
          child: Container(
            width: FrameSize.winWidth(),
            alignment: Alignment.centerLeft,

            /// 来了消息，要固定在聊天面板之上
            /// [2021 11.15]
            child: UnconstrainedBox(
              child: Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(
                      left: FrameSize.px(10), right: FrameSize.px(10)),
                  height: FrameSize.px(24),
                  decoration: BoxDecoration(
                      color: const Color(0xff6179F2),
                      borderRadius: BorderRadius.circular(FrameSize.px(12))),
                  child: RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <InlineSpan>[
                            TextSpan(
                                text: widget.userInfo?.name ?? '',
                                style: TextStyle(
                                    color: const Color(0xFFA8E4F8),
                                    fontSize: FrameSize.px(14),
                                    fontWeight: FontWeight.w500)),
                            const TextSpan(
                                text: " 来了",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500))
                          ]))),
            ),
          ),
        );
      },
    );
  }
}
