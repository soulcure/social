import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/redpack/send_pack/views/money_input_formatter.dart';
import 'package:im/app/theme/app_colors.dart';
import 'package:im/app/theme/app_text_theme.dart';
import 'package:im/common/extension/string_extension.dart';

typedef TextFieldListener = void Function(String text);

class MoneyInputField extends StatefulWidget {
  final TextFieldListener textFieldListener;
  final String hintText;
  final int maxLength;
  final TextEditingController controller;
  final bool isError;
  final double maxInput;

  const MoneyInputField(this.textFieldListener, this.controller, this.maxInput,
      {this.hintText, this.maxLength, this.isError = false, Key key})
      : super(key: key);

  @override
  _BlackListTextFieldState createState() => _BlackListTextFieldState();
}

class _BlackListTextFieldState extends State<MoneyInputField> {
  TextFieldListener get textFieldListener => widget.textFieldListener;

  String get hintText => '${widget.hintText}${' $nullChar'}';

  int get maxLength => widget.maxLength;

  TextEditingController get controller => widget.controller;

  bool get isError => widget.isError;

  TextStyle get errorStyle => const TextStyle(fontSize: 15, color: errorColor);

  TextStyle get normalStyle =>
      const TextStyle(fontSize: 15, color: Colors.black);

  //红包金额的最大输入值，设计要求最多为最大值*10，20000*10
  double get maxInput => widget.maxInput;

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
      controller: controller,
      maxLength: maxLength,
      textAlign: TextAlign.end,
      //只允许输入小数
      inputFormatters: [
        FilteringTextInputFormatter(RegExp("[0-9.]"), allow: true),
        MoneyNumberTextInputFormatter(digit: 2, maxInput: maxInput),
      ],
      //键盘类型
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: isError ? errorStyle : normalStyle,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hintText ?? '输入金额'.tr,
        contentPadding: const EdgeInsets.only(right: 5),
        hintStyle: const TextStyle(
          color: hintColor,
        ),
      ),
      onChanged: (text) {
        //内容改变的回调
        if (textFieldListener != null) textFieldListener.call(controller.text);
      },
    );
  }
}
