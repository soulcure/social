import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';

class OptionButton extends StatelessWidget {
  final String? option;
  final bool isEnable;
  final GestureTapCallback? onTap;

  const OptionButton({this.option, this.isEnable = true, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isAdd = option == "+";
    final String hideStr = isEnable ? "" : "_hide";
    return Material(
      color: isEnable
          ? const Color(0xff8F959E).withOpacity(0.15)
          : const Color(0xff8F959E).withOpacity(0.075),
      borderRadius: const BorderRadius.all(Radius.circular(1)),
      child: InkWell(
        splashColor: Colors.transparent,
        onTap: () {
          if (onTap != null) {
            onTap!();
          }
        },
        child: Container(
          height: 21.px,
          width: 21.px,
          alignment: Alignment.center,
          child: Image.asset(
            /// [2021 11.22] 商品数量 加减号 使用 图标。
            /// 目前问题：禁用状态会叠加颜色，需要张x重新切图
            'assets/live/main/sku_${isAdd ? "add" : "sub"}$hideStr.png',
            width: 10.px,
            height: 10.px,
          ),
        ),
      ),
    );
  }
}
