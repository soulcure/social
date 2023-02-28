import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

typedef TextFieldListener = void Function(String text);

class GreetingInputField extends StatefulWidget {
  final TextFieldListener textFieldListener;
  final String hintText;
  final int maxLength;
  final TextInputType keyboardType;

  const GreetingInputField(this.textFieldListener,
      {this.hintText, this.maxLength, this.keyboardType, Key key})
      : super(key: key);

  @override
  _BlackListTextFieldState createState() => _BlackListTextFieldState();
}

class _BlackListTextFieldState extends State<GreetingInputField> {
  TextFieldListener get textFieldListener => widget.textFieldListener;

  String get hintText => widget.hintText;

  int get maxLength => widget.maxLength;

  TextInputType get keyboardType => widget.keyboardType;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      maxLengthEnforcement: MaxLengthEnforcement.truncateAfterCompositionEnds,
      maxLength: 20,
      decoration: InputDecoration(
        counterText: "",
        border: InputBorder.none,
        hintText: hintText ?? '恭喜发财，万事如意'.tr,
        hintStyle: const TextStyle(
          color: Color(0x968F959E),
          fontSize: 15,
        ),
      ),
      onChanged: (text) {
        //内容改变的回调
        if (textFieldListener != null) textFieldListener.call(text);
      },
    );
  }
}
