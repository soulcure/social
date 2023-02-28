import 'package:im/core/http_middleware/http.dart';

class UploadApi {
  static Future uploadToken() async {
    final res = await Http.request("/api/file/token");
    return res;
  }

  static Future sliceUploadToken() async {
    final res = await Http.request("/api/file/test");
    return res;
  }

  static Future cosTmpKey() async {
    final res = await Http.request("/api/file/cosTmpKey");
    return res;
  }

  /// -下发上传配置接囗/api/common/setting 例如每个文件大细，下载/上传并行客的数目。
  /// upload_number跟 download_number -1 ，是客户端自已计数算上传跟下载数
  static Future getFileUploadSetting() async {
    final res = await Http.request("/api/common/setting");
    return res;
  }
}
