import 'package:flutter/services.dart';

class CountNumberTextInputFormatter extends TextInputFormatter {
  int maxInput;

  CountNumberTextInputFormatter({this.maxInput = 20000});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final String value = newValue.text;

    // if (value == "") {
    //   if (oldValue.text.length >= 2) {
    //     return oldValue;
    //   }
    //   // if (oldValue.selection.end == 0) {
    //   //   return oldValue;
    //   // }
    //
    // }

    if (value.startsWith('0')) {
      return oldValue;
    }

    if ((double.tryParse(value) ?? 0) > maxInput) {
      return oldValue;
    }

    // return TextEditingValue(
    //   text: value,
    //   selection: TextSelection.collapsed(offset: selectionIndex),
    // );

    return newValue;
  }
}
