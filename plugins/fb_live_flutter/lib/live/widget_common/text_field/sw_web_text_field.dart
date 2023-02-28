import 'package:fb_live_flutter/live/pages/create_room/widget_web/create_field_widget.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:flutter/material.dart';

import '../../utils/ui/frame_size.dart';

class SwWebTextField extends StatefulWidget {
  final bool? enabled;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool isMaxLine; //输入框是否为多行
  final String? hintText;
  final bool isFocusBorderColor;
  final bool isMaxLength;
  final int? maxLength;
  final EdgeInsetsGeometry? maxLengthUiPadding;
  final ValueChanged<String>? onChanged;

  const SwWebTextField(
      {this.enabled,
      this.controller,
      this.focusNode,
      this.isMaxLine = false,
      this.hintText,
      this.isFocusBorderColor = false,
      this.isMaxLength = false,
      this.maxLength,
      this.maxLengthUiPadding,
      this.onChanged});

  @override
  _SwWebTextFieldState createState() => _SwWebTextFieldState();
}

class _SwWebTextFieldState extends State<SwWebTextField> {
  final InputBorder border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(4),
    borderSide: const BorderSide(color: Color(0xffDEE0E3)),
  );

  final InputBorder focusBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(4),
    borderSide: const BorderSide(color: Color(0xff6179F2)),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: FrameSize.winWidth(),
      height: widget.isMaxLine ? 130.px : 40.px,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          TextField(
            controller: widget.controller,
            onChanged: widget.onChanged ?? (v) => setState(() {}),
            decoration: InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.px, vertical: 13.px),
              border: border,
              enabledBorder: border,
              disabledBorder: border,
              focusedBorder: widget.isFocusBorderColor ? focusBorder : border,
              hintText: strNoEmpty(widget.hintText) ? widget.hintText : null,
              hintStyle: TextStyle(
                fontSize: 14.px,
                color: const Color(0xff8F959E),
              ),
            ),
            enabled: widget.enabled ?? true,
            focusNode: widget.focusNode,
            maxLines: widget.isMaxLine ? 7 : 1,
            style: TextStyle(
              fontSize: 14.px,
              color: const Color(0xff1F2125),
            ),
          ),
          if (widget.isMaxLength)
            Expanded(
                child: MaxLengthUi(
              widget.controller,
              widget.maxLength ?? 300,
              padding: widget.maxLengthUiPadding,
            )),
        ],
      ),
    );
  }
}
