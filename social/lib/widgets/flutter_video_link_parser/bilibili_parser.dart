import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_link_preview/flutter_link_preview.dart';
import 'package:im/api/web_api.dart';

import 'flutter_video_link_parser.dart';
import 'http_get.dart';

final Map<Uri, String> _redirectUrlMap = {};

Future<MeidaInfo> parseBiliBiliShortURL(Uri uri) async {
  final info = await WebAnalyzer.getInfo(uri.toString());
  if (info == null) return null;
  if (kIsWeb) {
    String url = _redirectUrlMap[uri];
    url ??= await WebApi.relocationUrl(uri.toString(), format: 'link');
    return parseWebBiliBili(Uri.parse(url));
  } else
    return parseBiliBili(Uri.parse((info as WebInfo).redirectUrl));
}

Future<MeidaInfo> parseWebBiliBili(Uri url) async {
  if (url.pathSegments.first != "video") return null;

  final videoId = url.pathSegments[1];
  final viewUrl =
      Uri.https("api.bilibili.com", "/x/web-interface/view", {"bvid": videoId});
  final viewRes = await WebApi.relocationUrl(viewUrl.toString());
  if (viewRes["code"] != 0) return MeidaInfo();

  final view = viewRes["data"];
  final playUrl = Uri.https("api.bilibili.com", "/x/player/playurl", {
    "cid": "${view["cid"]}",
    "bvid": videoId,
    "qn": "16",
    "type": "mp4",
    "otype": "json",
    "platform": "html5",
  });
  final playUrlRes = await WebApi.relocationUrl(playUrl.toString());
  if (playUrlRes["code"] != 0) return null;

  return MeidaInfo(
      title: view["title"],
      url: playUrlRes["data"]["durl"][0]["url"],
      aspectRatio: view["dimension"]["width"] / view["dimension"]["height"],
      thumb: view["pic"],
      duration: view["duration"],
      siteIcon: "https://b23.tv/favicon.ico",
      siteName: "哔哩哔哩".tr);
}

Future<MeidaInfo> parseBiliBili(Uri url) async {
  if (kIsWeb) return parseWebBiliBili(url);
  if (url.pathSegments.first != "video") return null;

  final videoId = url.pathSegments[1];
  final viewRes = await httpGet(Uri.https(
      "api.bilibili.com", "/x/web-interface/view", {"bvid": videoId}));
  if (viewRes["code"] != 0) return MeidaInfo();

  final view = viewRes["data"];

  final playUrlRes =
      await httpGet(Uri.https("api.bilibili.com", "/x/player/playurl", {
    "cid": "${view["cid"]}",
    "bvid": videoId,
    "qn": "16",
    "type": "mp4",
    "otype": "json",
    "platform": "html5",
  }));

  if (playUrlRes["code"] != 0) return null;

  return MeidaInfo(
      title: view["title"],
      url: playUrlRes["data"]["durl"][0]["url"],
      aspectRatio: view["dimension"]["width"] / view["dimension"]["height"],
      thumb: view["pic"],
      duration: view["duration"],
      siteIcon: "https://b23.tv/favicon.ico",
      siteName: "哔哩哔哩".tr);
}
