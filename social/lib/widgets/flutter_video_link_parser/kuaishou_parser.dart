import 'dart:convert';

import 'package:flutter_link_preview/flutter_link_preview.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart' as parser;

import '../../loggers.dart';
import 'flutter_video_link_parser.dart';
import 'http_get.dart';

Future<MeidaInfo> parseKuaishou(Uri uri) async {
  final info = await WebAnalyzer.getInfo(uri.toString());
  return _parseKuaishou(
      info, Uri.parse((info as WebInfo)?.redirectUrl ?? uri.toString()));
}

Future<MeidaInfo> _parseKuaishou(WebInfo info, Uri uri) async {
  String res;
  try {
    res = await httpGetHtml(uri);
  } catch (e) {
    logger.severe(e);
  }
  if (res == null) return null;
  final document = parser.parse(res);
  String videoUrl = "";
  String thumb = "";
  String title = "";
  double duration = -1;
  double height = 16;
  double width = 9;
  final scriptTags = document.body.getElementsByTagName('script');
  for (final scriptTag in scriptTags) {
    final text = scriptTag.text ?? "";
    if (!text.contains('window.pageData')) continue;
    final matches = RegExp(r"(?<=\=).*").allMatches(text);
    for (final match in matches) {
      try {
        final jsonStr = match.group(0).trim();
        if (!jsonStr.contains('video')) continue;
        final json = jsonDecode(jsonStr);
        if (json is Map) {
          final object = json['video'];
          if ((object is Map) && object.containsKey('src')) {
            videoUrl = object['src'];
            thumb = object['poster'];
            title = object['caption'];
            width = double.tryParse(object['width'].toString()).toDouble() ?? 9;
            height = double.tryParse(object['height'].toString()) ?? 16;
            duration = double.tryParse(
                        json['rawPhoto']['ext_params']['video'].toString()) /
                    1000 ??
                -1;
            break;
          } else {
            continue;
          }
        }
      } catch (e) {
        print(e);
      }
    }
  }

  return MeidaInfo(
    title: title,
    aspectRatio: width / height,
    url: videoUrl,
    thumb: thumb,
    duration: duration.toInt(),
    siteIcon: "https://v.kuaishou.com/favicon.ico",
    siteName: "快手".tr,
  );
}
