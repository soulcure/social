/*
直播界面打赏动画
 */
import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../bloc_model/gift_move_bloc_model.dart';
import '../../../utils/ui/frame_size.dart';

class GiftsGiveView extends StatefulWidget {
  final GiveGiftModel? giveGiftModel;
  final Function(GiveGiftModel?)? animationComplete;
  final int? count;
  final Function(Function(GiveGiftModel))? refreshListener;

  const GiftsGiveView({
    this.giveGiftModel,
    this.count,
    this.animationComplete,
    this.refreshListener,
  });

  @override
  // ignore: no_logic_in_create_state
  _GiftsGiveViewState createState() => _GiftsGiveViewState(
        giveGiftModel: giveGiftModel,
      );
}

class _GiftsGiveViewState extends State<GiftsGiveView>
    with TickerProviderStateMixin {
  Animation<double>? animationGiftNum_1, animationGiftNum_2, animationGiftNum_3;
  AnimationController? controller;
  bool aniContinue = true;
  int preCount = -1;
  int showCount = 0;
  GiveGiftModel? giveGiftModel;

  _GiftsGiveViewState({
    this.giveGiftModel,
  });

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    if (widget.refreshListener != null) {
      widget.refreshListener!((refreshModel) {
        setState(() {
          giveGiftModel = refreshModel;
        });
      });
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    /// 【2022 01.04】
    /// 横屏隐藏动画/来了
    if (FrameSize.isHorizontal()) {
      return Container();
    }

    if (widget.count == null || widget.count! <= 0) {
      aniContinue = false;
      showCount = preCount;
      preCount = 0;
      if (controller != null && controller!.isCompleted) {
        controller!.reverse();
      }
    } else {
      final int giftQt = widget.giveGiftModel!.giftInfo!["giftQt"];
      if (preCount < 1) {
        preCount = 0;
      }
      if (preCount < giftQt) {
        aniContinue = true;
        setState(() {
          preCount++;
          if (preCount >= giftQt) {
            aniContinue = false;
            showCount = giftQt;
            preCount = 0;
          } else {
            showCount = preCount;
          }
          if (!aniContinue && controller != null && controller!.isCompleted) {
            controller!.reverse();
          }
        });
      } else {
        if (preCount == giftQt) {
          aniContinue = false;
        } else {
          aniContinue = true;
        }
        showCount = giftQt;
        if (!aniContinue && controller != null && controller!.isCompleted) {
          controller!.reverse();
        }
      }
    }

    if (controller == null) {
      controller = AnimationController(
          duration: const Duration(milliseconds: 2000), vsync: this);

      // 横幅从屏幕外滑入
      final double? an3Begin = kIsWeb ? -FrameSize.px(250) : -FrameSize.px(230);
      animationGiftNum_3 = Tween<double>(
        begin: an3Begin,
        end: 0,
      ).animate(CurvedAnimation(
        parent: controller!,
        curve: const Interval(0.6, 0.65, curve: Curves.easeIn),
      ));

      // 礼物数量变大
      animationGiftNum_1 = Tween<double>(
        begin: 1,
        end: 1.2,
      ).animate(CurvedAnimation(
        parent: controller!,
        curve: const Interval(0.75, 0.85, curve: Curves.easeOut),
      ));

      // 礼物数量变小
      animationGiftNum_2 = Tween<double>(
        begin: 1.2,
        end: 1,
      ).animate(CurvedAnimation(
        parent: controller!,
        curve: const Interval(0.85, 1, curve: Curves.easeIn),
      ));
      controller!.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (!aniContinue) {
            controller!.reverse();
          } else {
            setState(() {
              controller!.forward(from: 0.84);
            });
          }
        } else if (status == AnimationStatus.dismissed) {
          widget.animationComplete?.call(widget.giveGiftModel);
        }
      });
    }
    controller!.forward();

    return AnimatedBuilder(
        animation: controller!,
        builder: (context, child) {
          return Transform.translate(
              offset: Offset(animationGiftNum_3?.value ?? 0, 0),
              child: Row(children: [
                Container(
                    width: FrameSize.px(165),
                    height: FrameSize.px(42),
                    decoration: BoxDecoration(
                      color: const Color(0x8C000000).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(FrameSize.px(20)),
                    ),
                    child: Row(children: [
                      SizedBox(width: FrameSize.px(3)),
                      _userImage(widget.giveGiftModel!.sendUserInfo!.avatar),
                      SizedBox(width: FrameSize.px(5)),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            SizedBox(height: FrameSize.px(4)),
                            _usernameText(
                                widget.giveGiftModel!.sendUserInfo!.name!),
                            _giftTypeText(
                                widget.giveGiftModel!.giftInfo!["giftName"]),
                          ])),
                      SizedBox(width: FrameSize.px(5)),
                      _giftImage(widget.giveGiftModel!.giftInfo!["giftImgUrl"]),
                    ])),
                SizedBox(width: FrameSize.px(5)),
                Transform.scale(
                  scale: animationGiftNum_1!.value >= 1.2
                      ? animationGiftNum_2!.value
                      : animationGiftNum_1!.value,
                  child: _giftNumText(showCount),
                )
              ]));
        });
  }

  Widget _userImage(String? userHeadImageUrl) {
    return Container(
      height: FrameSize.px(36),
      width: FrameSize.px(36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FrameSize.px(18)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Image(
          image: (!strNoEmpty(userHeadImageUrl)
              ? fbApi.getFanbookIcon()
              : NetworkImage(userHeadImageUrl!)) as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _usernameText(String userName) {
    return SizedBox(
        height: FrameSize.px(18),
        child: Text(userName,
            style: TextStyle(
              fontSize: FrameSize.px(13),
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis));
  }

  Widget _giftTypeText(String? giftName) {
    return SizedBox(
        height: FrameSize.px(14),
        child: Text(
          "送  $giftName",
          style: TextStyle(
              fontSize: FrameSize.px(10), color: const Color(0xFFDDDDDD)),
          maxLines: 1,
          textAlign: TextAlign.left,
          overflow: TextOverflow.ellipsis,
        ));
  }

  Widget _giftImage(String imageUrl) {
    return Image(
      image: NetworkImage(
        imageUrl,
      ),
      width: FrameSize.px(40),
      height: FrameSize.px(35),
      fit: BoxFit.fitHeight,
    );
  }

  Widget _giftNumText(int count) {
    return RichText(
        text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: <InlineSpan>[
          TextSpan(
              text: 'X ',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: FrameSize.px(12),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w300)),
          TextSpan(
              text: "$count",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: FrameSize.px(26),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold)),
        ]));
  }
}
