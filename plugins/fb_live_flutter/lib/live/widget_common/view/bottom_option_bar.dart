import 'package:fb_live_flutter/live/bloc/goods/goods_dialog_bloc.dart';
import 'package:fb_live_flutter/live/pages/goods/commom/goods_app_bar.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/material.dart';

/// 商品列表调用
class BottomOptionBar extends Positioned {
  final GoodCall? goodCall;

  BottomOptionBar(this.goodCall)
      : super(
          bottom: 0,
          child: BottomOptionBarState(goodCall),
        );
}

/// 优惠券列表调用
class BottomOptionBarState extends StatefulWidget {
  final GoodCall? goodCall;

  const BottomOptionBarState(this.goodCall);

  @override
  _BottomOptionBarState createState() => _BottomOptionBarState();
}

class _BottomOptionBarState extends State<BottomOptionBarState> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          GoodsDialogItemModel('assets/live/main/bottom_option_manage.png',
              '管理', GoodsDialogItemType.manage),
          GoodsDialogItemModel('assets/live/main/bottom_option_add.png', '添加',
              GoodsDialogItemType.add),
        ].map((e) {
          return ClickEvent(
            onTap: () async {
              if (widget.goodCall != null) {
                widget.goodCall!(e);
              }
            },
            child: Container(
              width: (FrameSize.winWidth() - 1) / 2,
              height: 52.px,
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                        color: const Color(0xff8F959E).withOpacity(
                            e.value == GoodsDialogItemType.manage ? 0.2 : 0),
                        width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      e.image,
                      width: 20.px,
                      height: 20.px,
                    ),
                    Space(width: 12.px),
                    Text(
                      e.text,
                      style: TextStyle(
                        color: const Color(0xff1F2125),
                        fontSize: 16.px,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
