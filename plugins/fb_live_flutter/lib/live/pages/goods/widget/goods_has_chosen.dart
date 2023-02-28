import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/material.dart';

import 'goods_button.dart';

class GoodsHasChosen extends Positioned {
  final List? selectData;
  final bool enable;
  final VoidCallback? onPressed;
  final bool isConfirm;

  GoodsHasChosen({
    this.selectData,
    this.enable = true,
    this.isConfirm = false,
    this.onPressed,
  }) : super(
          bottom: 0,
          child: enable
              ? Container()
              : GoodsHasChosenState(
                  selectData: selectData,
                  enable: enable,
                  onPressed: () async {
                    if (onPressed != null) {
                      onPressed();
                    }
                  },
                  isConfirm: isConfirm,
                ),
        );
}

class GoodsHasChosenState extends StatelessWidget {
  final List? selectData;
  final bool enable;
  final ClickEventCallback? onPressed;
  final bool isConfirm;

  const GoodsHasChosenState({
    this.selectData,
    this.onPressed,
    this.enable = true,
    this.isConfirm = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.px),
      width: FrameSize.winWidth(),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              listNoEmpty(selectData) ? '已选择: ${selectData!.length}个' : "",
              style: TextStyle(color: const Color(0xFF198CFE), fontSize: 14.px),
            ),
            GoodsButton(
              enable: listNoEmpty(selectData),
              text: isConfirm ? "确定" : "移除",
              isConfirm: isConfirm,
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }
}
