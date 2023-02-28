import 'package:flutter/material.dart';
import 'package:flutter_text_field/flutter_text_field.dart';
import 'package:im/common/extension/rich_input_controller_extension.dart';
import 'package:im/core/config.dart';
import 'package:im/themes/default_theme.dart';
import 'package:rich_input/rich_input.dart';

class UniversalRichInputController {
  final RichInputController _flutterController;
  final RichTextFieldController _nativeController;

  final bool forceFlutter;

  bool get useNativeInput => Config.useNativeInput && !forceFlutter;

  RichInputController get rawFlutterController => _flutterController;

  RichTextFieldController get rawIosController => _nativeController;

  UniversalRichInputController({this.forceFlutter = false})
      : _flutterController = RichInputController(),
        _nativeController = RichTextFieldController(
            defaultRichTextStyle: TextStyle(color: primaryColor, fontSize: 16));

  String get data =>
      useNativeInput ? _nativeController.data : _flutterController.data;

  String get text =>
      useNativeInput ? _nativeController.text : _flutterController.text;

  set text(String value) {
    if (useNativeInput) {
      _nativeController.text = value;
    } else {
      _flutterController.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length));
    }
  }

  num get offset => useNativeInput
      ? _nativeController.value.selection.start
      : _flutterController.selection.baseOffset;

  set offset(num offset) {
    if (!useNativeInput) {
      _flutterController.value = TextEditingValue(
          text: _flutterController.value.text,
          selection: TextSelection.collapsed(offset: offset));
    }
  }

  TextSelection get selection {
    if (useNativeInput) {
      final s = _nativeController.value.selection;
      return TextSelection(baseOffset: s.start, extentOffset: s.end);
    } else {
      return _flutterController.selection;
    }
  }

  void clear() {
    if (useNativeInput) {
      _nativeController.clear();
    } else {
      _flutterController.clear();
    }
  }

  void addListener(VoidCallback callback) {
    if (useNativeInput) {
      _nativeController.addListener(callback);
    } else {
      _flutterController.addListener(callback);
    }
  }

  void removeListener(VoidCallback callback) {
    if (useNativeInput) {
      _nativeController.removeListener(callback);
    } else {
      _flutterController.removeListener(callback);
    }
  }

  void dispose() {
    if (useNativeInput) {
      _nativeController.dispose();
    } else {
      _flutterController.dispose();
    }
  }

  void insertAt(String name,
      {String data, TextStyle textStyle, int backSpaceLength = 0}) {
    if (useNativeInput) {
      _nativeController.insertAtName(name,
          data: data, textStyle: textStyle, backSpaceLength: backSpaceLength);
    } else {
      _flutterController.insertAtBlock(name, data);
    }
  }

  void insertChannelName(String name,
      {String data, TextStyle textStyle, int backSpaceLength = 0}) {
    if (useNativeInput) {
      _nativeController.insertChannelName(name,
          data: data, textStyle: textStyle, backSpaceLength: backSpaceLength);
    } else {
      _flutterController.insertChannelBlock(name, data);
    }
  }

  void insertText(String value, {int backSpaceLength = 0}) {
    if (useNativeInput) {
      _nativeController.insertText(value, backSpaceLength: backSpaceLength);
    } else {
      _flutterController.insertText(value);
    }
  }

  void replaceRange(String s, {int start, int end}) {
    if (useNativeInput) {
      _nativeController.replace('', TextRange(start: start, end: end));
    } else {
      _flutterController.value = TextEditingValue(
          text: _flutterController.text.replaceRange(start, end, ''),
          selection: TextSelection.collapsed(offset: start));
    }
  }

  void insertCusEmo(String emojiId, {TextStyle textStyle}) {
    if (useNativeInput) {
      _nativeController.insertBlock(emojiId,
          data: emojiId, textStyle: textStyle);
    } else {
      _flutterController.insertCusEmo(emojiId, textStyle);
    }
  }
}
