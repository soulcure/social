import 'package:flutter/foundation.dart';
import 'package:im/api/web_api.dart';

import 'flutter_video_link_parser.dart';
import 'http_get.dart';

Future<MeidaInfo> parseTapTap(Uri uri) {
  final path1 = uri.pathSegments[0];
  if (path1 == "video") {
    if (kIsWeb)
      return _parseTapTapVideoFromWeb(uri);
    else
      return _parseTapTapVideo(uri);
  }
  return Future.value();
}

Future<MeidaInfo> _parseTapTapVideoFromWeb(Uri uri) async {
  final videoId = uri.pathSegments[1];
  final resJson = await WebApi.relocationUrl(
      "https://www.taptap.com/webapiv2/video/v2/detail?id=$videoId&X-UA=V%3D1%26PN%3DWebApp%26LANG%3Den_US%26VN_CODE%3D1%26VN%3D0.1.0%26LOC%3DCN%26PLT%3DPC%26UID%3De6fd6c1e-6eb9-49ad-b03e-91a801873e27");
  if (resJson["success"] != true) return MeidaInfo();
  final video = resJson["data"]["video"];
  return MeidaInfo(
    title: video["title"],
    url: video["url"],
    aspectRatio: video["info"]["aspect_ratio"],
    thumb: video["video_resource"]["thumbnail"]["url"],
    duration: video["info"]["duration"],
    siteIcon: "https://www.taptap.com/favicon.ico",
    siteName: "TapTap",
  );
}

Future<MeidaInfo> _parseTapTapVideo(Uri uri) async {
  final videoId = uri.pathSegments[1];
  // https://www.taptap.com/webapiv2/video/v2/detail?id=1432919&X-UA=V=1&PN=WebApp&LANG=en_US&VN_CODE=1&VN=0.1.0&LOC=CN&PLT=PC&UID=e6fd6c1e-6eb9-49ad-b03e-91a801873e27
  final reqUri = Uri(
      scheme: "https",
      host: "www.taptap.com",
      path: "/webapiv2/video/v2/detail",
      query:
          "id=$videoId&X-UA=V%3D1%26PN%3DWebApp%26LANG%3Den_US%26VN_CODE%3D1%26VN%3D0.1.0%26LOC%3DCN%26PLT%3DPC%26UID%3De6fd6c1e-6eb9-49ad-b03e-91a801873e27");
  // final request = await HttpClient().getUrl(reqUri);
  // final response = await request.close();
  // final responseBody = await response.transform(const Utf8Decoder()).join();
  // final resJson = jsonDecode(responseBody);
  final resJson = await httpGet(reqUri, encodeUrl: "false");
  if (resJson["success"] != true) return MeidaInfo();

  final video = resJson["data"]["video"];
  return MeidaInfo(
    title: video["title"],
    url: video["url"],
    aspectRatio:
        double.tryParse((video["info"]["aspect_ratio"]).toString()) ?? 16 / 9,
    thumb: video["video_resource"]["thumbnail"]["url"],
    duration: video["info"]["duration"],
    siteIcon: "https://www.taptap.com/favicon.ico",
    siteName: "TapTap",
  );
}
