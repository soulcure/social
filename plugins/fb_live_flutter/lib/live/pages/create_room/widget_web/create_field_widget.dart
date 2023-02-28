import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';

class CreateFieldWidget extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final Widget? rWidget;
  final bool? isArrow;
  final bool enable;
  final GestureTapCallback? onTap;
  final int? maxLength;

  const CreateFieldWidget({
    this.controller,
    this.hintText,
    this.rWidget,
    this.enable = true,
    this.isArrow = false,
    this.onTap,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    Widget body = Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffDEE0E3)),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      padding: const EdgeInsets.only(left: 10),
      height: FrameSize.px(40),
      alignment: Alignment.center,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              enabled: enable,
              controller: controller ?? TextEditingController(),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(0),
                hintText: hintText ?? "",
                hintStyle:
                    TextStyle(color: const Color(0xff919499), fontSize: 14.px),
              ),
            ),
          ),
          if (rWidget != null) rWidget!,
          if (isArrow!)
            SwImage(
              "assets/live/main/arrow_down_web.webp",
              width: 14.px,
              margin: const EdgeInsets.only(right: 10),
            )
        ],
      ),
    );
    if (maxLength != null) {
      body = Stack(
        alignment: Alignment.centerRight,
        children: [body, MaxLengthUi(controller, maxLength)],
      );
    }
    if (onTap != null) {
      return InkWell(onTap: onTap, child: body);
    }

    return body;
  }
}

class MaxLengthUi extends StatefulWidget {
  final TextEditingController? controller;
  final int? maxLength;
  final EdgeInsetsGeometry? padding;

  const MaxLengthUi(this.controller, this.maxLength, {this.padding});

  @override
  _MaxLengthUiState createState() => _MaxLengthUiState();
}

class _MaxLengthUiState extends State<MaxLengthUi> {
  @override
  void initState() {
    super.initState();
    widget.controller!.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final length = widget.controller!.text.length;
    final isRed = length > widget.maxLength!;
    final color = isRed ? Colors.red : const Color(0xff8F959E);
    return Padding(
      padding: widget.padding ?? const EdgeInsets.only(right: 10),
      child: Text(
        '${widget.controller!.text.length}/${widget.maxLength}',
        style: TextStyle(color: color, fontSize: 12.px),
      ),
    );
  }
}
