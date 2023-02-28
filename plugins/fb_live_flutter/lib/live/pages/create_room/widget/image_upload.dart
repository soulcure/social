import 'image_picker_web.dart' if (dart.library.io) 'image_upload_natiave.dart';

class ImageUpload {
  static Future<Map?> uploadImage() {
    return WebImagePicker().pickImage();
  }
}
