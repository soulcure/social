
import 'dart:typed_data';

class TextDecoder {
  external TextDecoder([String encoding = "utf8"]);

  external String decode(Uint8List bytes);
}
