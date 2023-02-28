import 'package:im/web/utils/image_picker/image_picker_for_web.dart'
    if (dart.library.io) 'package:im/web/utils/image_picker/image_picker_for_window.dart';
import 'package:image_picker/image_picker.dart';

class FileInfo {
  final PickedFile pickedFile;
  final String fileName;
  final int size;
  final String path;
  const FileInfo({
    this.pickedFile,
    this.fileName,
    this.size,
    this.path,
  });
}

class ImagePicker {
  static Future<FileInfo> pickFile(
      {String accept = 'image/*,video/3gpp,video/x-m4v,video/mp4,video/*',
      bool multiple = false}) {
    // ignore: invalid_use_of_visible_for_testing_member
    return ImagePickerPlugin().pickFile(accept: accept, multiple: multiple);
  }

  static Future<List> pickFile2(
      {String accept = 'image/*,video/3gpp,video/x-m4v,video/mp4,video/*',
      bool multiple = false}) {
    return ImagePickerPlugin().pickFile2(accept: accept, multiple: multiple);
  }
}
