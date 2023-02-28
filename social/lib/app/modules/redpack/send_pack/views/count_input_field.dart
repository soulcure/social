import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/redpack/send_pack/views/count_input_formatter.dart';
import 'package:im/app/theme/app_colors.dart';
import 'package:im/app/theme/app_text_theme.dart';
import 'package:im/common/extension/string_extension.dart';

typedef TextFieldListener = void Function(String text);

class CountInputField extends StatefulWidget {
  final TextFieldListener textFieldListener;
  final String hintText;
  final int maxLength;
  final TextEditingController controller;
  final bool isError;
  final int maxInput;

  const CountInputField(this.textFieldListener, this.controller, this.maxInput,
      {this.hintText, this.maxLength, this.isError = false, Key key})
      : super(key: key);

  @override
  _BlackListTextFieldState createState() => _BlackListTextFieldState();
}

class _BlackListTextFieldState extends State<CountInputField> {
  TextFieldListener get textFieldListener => widget.textFieldListener;

  String get hintText => '${widget.hintText}${' $nullChar'}';

  int get maxLength => widget.maxLength;

  TextEditingController get controller => widget.controller;

  bool get isError => widget.isError;

  TextStyle get errorStyle => const TextStyle(fontSize: 15, color: errorColor);

  TextStyle get normalStyle =>
      const TextStyle(fontSize: 15, color: Colors.black);

  //红包的最大个数，设计要求最多为最大值*10，2000*10
  int get maxInput => widget.maxInput;

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
      //只允许输入数字
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp("[0-9]")),
        CountNumberTextInputFormatter(maxInput: maxInput),
      ],
      //键盘类型
      keyboardType: TextInputType.number,
      style: isError ? errorStyle : normalStyle,
      //输入文本的样式
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hintText ?? '填写红包个数'.tr,
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
