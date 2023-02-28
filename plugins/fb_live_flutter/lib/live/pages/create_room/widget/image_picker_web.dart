import 'dart:async';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import '../../../image_picker/image_picker.dart';

class WebImagePicker {
  // web-端转成数据流
  Future<Uint8List> createUnit8ListFromFile(html.File file) {
    assert(file is html.File);
    final Completer<Uint8List> completer = Completer();
    final reader = html.FileReader();
    reader.onLoadEnd.listen((e) {
      completer.complete(reader.result as Uint8List);
    });
    reader.readAsArrayBuffer(file);
    return completer.future;
  }

  // web-端选择图片
  Future<Map?> pickImage() async {
    final Completer<Map> completer = Completer();
    await ImagePicker.pickFileList(accept: 'image/*').then((files) {
      final html.File file = files[0];
      createUnit8ListFromFile(file).then((stream) {
        final Map _file = {};
        _file['fileName'] = file.name;
        _file['fileStream'] = stream;
        completer.complete(_file);
      });
    });
    return completer.future;
  }
}
