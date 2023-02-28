import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/widget_common/button/small_button.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/material.dart';

class GoodsButton extends StatelessWidget {
  final String? text;
  final bool? enable;
  final ClickEventCallback? onPressed;
  final bool isConfirm;

  const GoodsButton({
    this.text,
    this.enable,
    this.onPressed,
    this.isConfirm = false,
  });

  @override
  Widget build(BuildContext context) {
    return SmallButton(
      width: 76.px,
      height: 32.px,
      margin: EdgeInsets.symmetric(vertical: 6.px),
      padding: const EdgeInsets.all(0),
      color: !enable!
          ? const Color(0xff8F959E).withOpacity(0.15)
          : isConfirm
              ? Theme.of(context).primaryColor
              : const Color(0xffF24848),
      borderRadius: BorderRadius.all(Radius.circular(16.px)),
      onPressed: () async {
        if (!enable! || onPressed == null) {
          return;
        }
        await onPressed!();
      },
      child: Text(
        text ?? 'text', //移除
        style: TextStyle(
            color: !enable!
                ? const Color(0xff8F959E).withOpacity(0.65)
                : Colors.white,
            fontSize: 14.px,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}
