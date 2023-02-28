import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'normal_inputbox_close.dart';

typedef TextFieldListener = void Function(String text);

const int inputLength = 30;

class NormalTextField extends StatefulWidget {
  final TextFieldListener textFieldListener;
  final String hintText;
  final String content;
  final int inputLength;
  final bool autofocus;

  const NormalTextField(this.textFieldListener,
      {this.hintText,
      this.content,
      this.inputLength = 20,
      this.autofocus = false,
      Key key})
      : super(key: key);

  @override
  _NormalTextFieldState createState() => _NormalTextFieldState();
}

class _NormalTextFieldState extends State<NormalTextField> {
  TextFieldListener get textFieldListener => widget.textFieldListener;

  String get hintText => widget.hintText;

  String get content => widget.content;

  int get inputLength => widget.inputLength;

  bool get autofocus => widget.autofocus;

  TextEditingController controller;
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: content);
    // 延时获取焦点，避免页面卡顿
    if (autofocus) {
      Future.delayed(const Duration(milliseconds: 350)).then((_) {
        if (mounted) focusNode.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F6FA),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: NormalInputCloseBox(
              focusNode: focusNode,
              //autofocus: autofocus,
              borderRadius: 6,
              fillColor: const Color(0xFFF5F5F8),
              controller: controller,
              hintText: hintText ?? '请输入原因(选填)'.tr,
              hintStyle:
                  const TextStyle(color: Color(0x968F959E), fontSize: 16),
              maxLength: inputLength,
              onChange: (text) {
                if (textFieldListener != null) textFieldListener.call(text);
              },
            ),
          ),
        ],
      ),
    );
  }
}
