import 'dart:typed_data';
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

class WebUtil implements WebUtilBase {
  @override
  void callJsMethod(String methodName, List params) {}

  @override
  void downloadFile(String url) {}

  @override
  // ignore: missing_return
  String getHref() {}

  @override
  // ignore: missing_return
  String getQuery() {}

  @override
  void initNotification() {}

  @override
  void pushLocalNotification(
      String title, String body, Map<String, String> extra) {}

  @override
  void setBadge(int badge) {}

  @override
  // ignore: missing_return, type_annotate_public_apis
  Future<String> createBlobUrlFromFile(file) {}

  @override
  // ignore: type_annotate_public_apis, missing_return
  Future<Uint8List> createUnit8ListFromFile(file) {}

  @override
  // ignore: type_annotate_public_apis, missing_return
  Future<Asset> getAssetInfo(file) {}

  @override
  // ignore: type_annotate_public_apis, missing_return
  Future<Asset> getImageInfo(file) {}

  @override
  // ignore: type_annotate_public_apis, missing_return
  Future<Asset> getVideoInfo(file) {}

  @override
  // ignore: type_annotate_public_apis, missing_return
  Future<Uint8List> compressImageFromElement(blobPath,
      {double quality = 0.6}) {}

  @override
  void refreshHtml() {}

  @override
  void setCookie(
    String key,
    String value, {
    String domain,
    String path,
    bool secure,
    int expires,
  }) {}

  @override
  String getCookie(String key) => null;

  @override
  void wakeUpApp(String postId, String topicId) {}

  @override
  // ignore: missing_return
  String gzip(Uint8List bytes) {}
}
