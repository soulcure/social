import 'image_picker_for_web.dart'
    if (dart.library.io) './image_picker_for_window.dart';

class ImagePicker {
  static Future<List> pickFileList(
      {String accept = 'image/*,video/3gpp,video/x-m4v,video/mp4,video/*',
      bool multiple = false}) {
    return ImagePickerPlugin().pickFileList(accept: accept, multiple: multiple);
  }
}
