import 'package:flutter/services.dart';

class MoneyNumberTextInputFormatter extends TextInputFormatter {
  static const defaultDouble = 0.001;

  ///允许的小数位数，-1代表不限制位数
  int digit;
  double maxInput;

  MoneyNumberTextInputFormatter({this.digit = -1, this.maxInput = 200000});

  ///处理非法的double格式输入 如: 5..2
  static double strToFloat(String str, [double defaultValue = defaultDouble]) {
    try {
      return double.parse(str);
    } catch (e) {
      return defaultValue;
    }
  }

  ///获取目前的小数位数
  static int getValueDigit(String value) {
    if (value.contains(".")) {
      return value.split(".")[1].length;
    } else {
      return -1;
    }
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String value = newValue.text;
    int selectionIndex = newValue.selection.end;

    // if (value == "") {
    //   if (oldValue.text.length >= 2) {
    //     return oldValue;
    //   }
    //
    //   // if (oldValue.selection.end == 0) {
    //   //   return oldValue;
    //   // }
    // }

    if (oldValue.text == '0' && value == '00') {
      value = "0";
      selectionIndex--;
    } else if (value.startsWith('0') &&
        value.length > 1 &&
        !value.startsWith('0.')) {
      value = value.substring(1);
      selectionIndex--;
    } else if (value == ".") {
      value = "0.";
      selectionIndex++;
    } else if (value != "" &&
            value != defaultDouble.toString() &&
            strToFloat(value) == defaultDouble ||
        getValueDigit(value) > digit) {
      //判断输入有几个小数位，金额为2位小数点,和非法的double格式输入 如: 5..2
      value = oldValue.text;
      selectionIndex = oldValue.selection.end;
    } else if ((double.tryParse(value) ?? 0) > maxInput) {
      //超出金额最大值
      value = oldValue.text;
      selectionIndex = oldValue.selection.end;
    }

    return TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
