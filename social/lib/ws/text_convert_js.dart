@JS()
library text_converter;

import 'dart:typed_data';

import 'package:js/js.dart';

@JS('TextDecoder')
class TextDecoder {
  external TextDecoder([String encoding = "utf8"]);

  external String decode(Uint8List bytes);
}
