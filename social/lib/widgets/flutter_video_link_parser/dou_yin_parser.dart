import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_link_preview/flutter_link_preview.dart';
import 'package:im/api/web_api.dart';

import 'flutter_video_link_parser.dart';
import 'http_get.dart';

final Map<Uri, String> _redirectUrlMap = {};

Future<MeidaInfo> parseDouYin(Uri uri) async {
  if (kIsWeb) {
    String url = _redirectUrlMap[uri];
    url ??= await WebApi.relocationUrl(uri.toString(), format: 'link');
    return _parseWebDouYin(Uri.parse(url));
  }
  final info = await WebAnalyzer.getInfo(uri.toString());
  if (info == null) return null;
  return _parseDouYin(Uri.parse((info as WebInfo).redirectUrl));
}

Future<MeidaInfo> _parseWebDouYin(Uri uri) async {
  if (!uri.path.startsWith("/share/video")) return MeidaInfo();

  final videoId = uri.pathSegments[2];
  final reqURL = Uri.https(
      "www.iesdouyin.com", "/web/api/v2/aweme/iteminfo", {"item_ids": videoId});
  final resJson = await WebApi.relocationUrl(reqURL.toString());
  if (resJson["status_code"] != 0) return MeidaInfo();

  final item = resJson["item_list"][0];
  return MeidaInfo(
    title: item["desc"],
    url: item["video"]["play_addr"]["url_list"][0],
    aspectRatio: item["video"]["width"] / item["video"]["height"],
    thumb: item["video"]["cover"]["url_list"].first,
    duration: item["duration"] ~/ 1000,
    siteIcon:
        "https://sf1-dycdn-tos.pstatp.com/obj/eden-cn/kpchkeh7upepld/fe_app_new/favicon_v2.ico",
    siteName: "抖音".tr,
  );
}

Future<MeidaInfo> _parseDouYin(Uri uri) async {
  if (!uri.path.startsWith("/share/video")) return MeidaInfo();

  final videoId = uri.pathSegments[2];
  final reqURL = Uri.https(
      "www.iesdouyin.com", "/web/api/v2/aweme/iteminfo", {"item_ids": videoId});
  final resJson = await httpGet(reqURL);
  if (resJson["status_code"] != 0) return MeidaInfo();

  try {
    final item = resJson["item_list"][0];
    return MeidaInfo(
      title: item["desc"],
      url: item["video"]["play_addr"]["url_list"][0],
      aspectRatio: item["video"]["width"] / item["video"]["height"],
      thumb: item["video"]["cover"]["url_list"].first,
      duration: item["duration"] ~/ 1000,
      siteIcon: "https://www.douyin.com/favicon.ico",
      siteName: "抖音".tr,
    );
  } catch (e) {
    return MeidaInfo();
  }
}
