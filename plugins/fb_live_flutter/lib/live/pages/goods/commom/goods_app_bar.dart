import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/bloc/goods/goods_dialog_bloc.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';

typedef GoodCall = Function(GoodsDialogItemModel? value);

class GoodsAppBar extends StatefulWidget {
  final GoodCall? goodCall;
  final String? title;
  final List<GoodsDialogItemModel>? items;
  final Widget? rWidget;
  final bool isShowCartRedPoint;
  final Key? cartKey;

  const GoodsAppBar({
    this.goodCall,
    this.title,
    this.items,
    this.rWidget,
    this.isShowCartRedPoint = false,
    this.cartKey,
  });

  @override
  State<GoodsAppBar> createState() => _GoodsAppBarState();
}

class _GoodsAppBarState extends State<GoodsAppBar>
    with SingleTickerProviderStateMixin {
  bool isShowCartRedPoint = false;

  //动画控制器
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    buildInitState();
  }

  void buildInitState() {
    //AnimationController是一个特殊的Animation对象，在屏幕刷新的每一帧，就会生成一个新的值，
    // 默认情况下，AnimationController在给定的时间段内会线性的生成从0.0到1.0的数字
    //用来控制动画的开始与结束以及设置动画的监听
    //vsync参数，存在vsync时会防止屏幕外动画（动画的UI不在当前屏幕时）消耗不必要的资源
    //duration 动画的时长，这里设置的 seconds: 2 为2秒，当然也可以设置毫秒 milliseconds：2000.
    controller = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isShowCartRedPoint && !isShowCartRedPoint) {
      isShowCartRedPoint = true;

      /// 修复添加购物车动画状态错误【代码层面，无法验证】
      if (mounted) controller.forward();
    } else if (!widget.isShowCartRedPoint && isShowCartRedPoint) {
      /// 修复添加购物车动画状态错误【代码层面，无法验证】
      if (mounted) controller.reverse();
      isShowCartRedPoint = false;
    }
    return Stack(
      children: [
        Container(
          width: FrameSize.winWidth(),
          constraints: BoxConstraints(minHeight: 44.px),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Space(width: 76.px + 16.px),
              const Spacer(),
              ...widget.items?.map<Widget>((e) {
                    return InkWell(
                      onTap: () {
                        if (widget.goodCall != null) {
                          widget.goodCall!(e);
                        }
                      },
                      child: Stack(
                        alignment: const Alignment(0.8, -0.5),
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 10.5.px, horizontal: 8.px),
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SwImage(
                                      e.image,
                                      width: 20.px,
                                      height: 20.px,
                                    ),

                                    /// 用于定位中心点
                                    if (e.value ==
                                        GoodsDialogItemType.shoppingCart)
                                      SizedBox(
                                        height: 1,
                                        width: 1,
                                        key: widget.cartKey,
                                      ),
                                  ],
                                ),
                                Text(
                                  e.text,
                                  style: TextStyle(
                                    color: const Color(0xff646A73),
                                    fontSize: 10.px,
                                  ),
                                )
                              ],
                            ),
                          ),
                          if (e.value == GoodsDialogItemType.shoppingCart)

                            /// [2021 11.21] 购物车小红点的位置还是不对啊
                            Positioned(
                              right: 9.5.px,
                              top: 8.px,
                              child: ScaleTransition(
                                scale: controller,
                                child: CircleAvatar(
                                  radius: (6 / 2).px,
                                  backgroundColor: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList() ??
                  []

                /// 【2021 11.25】[ ] 订单和购物车的位置不对
                /// 因为按钮本身有8px的内边距，所以这个应该是16的一半，也是8
                ..add(Space(width: 8.px)),
            ],
          ),
        ),
        Positioned(
          top: 11.5.px,
          left: 0,
          right: 0,
          child: Container(
            height: 21.px,
            alignment: Alignment.center,
            child: Text(
              widget.title!,
              style: TextStyle(
                  color: const Color(0xff1F2125),
                  fontSize: 17.px,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Positioned(
            top: 11.5.px, right: 16.px, child: widget.rWidget ?? Container()),
      ],
    );
  }
}
