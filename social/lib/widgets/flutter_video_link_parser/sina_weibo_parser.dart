import 'dart:convert';

import 'package:flutter_link_preview/flutter_link_preview.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart' as parser;

import '../../loggers.dart';
import 'flutter_video_link_parser.dart';
import 'http_get.dart';

Future<MeidaInfo> parseSinaWeibo(Uri uri) async {
  final info = await WebAnalyzer.getInfo(uri.toString());
  if (info == null) return null;
  return _parseSinaWeibo(info, Uri.parse((info as WebInfo).redirectUrl));
}

Future<MeidaInfo> _parseSinaWeibo(WebInfo info, Uri uri) async {
  String res;
  try {
    res = await httpGetHtml(uri);
  } catch (e) {
    logger.severe(e);
  }
  if (res == null) return null;
  final document = parser.parse(res);
  String url;
  String thumb = "";
  String title = "";
  double aspectRatio = 16 / 9;
  int duration = 0;
  final scriptTags = document.body.getElementsByTagName('script');
  for (final scriptTag in scriptTags) {
    String text = scriptTag.text ?? "";
    if (!(text.contains('render_data') && text.contains('user'))) continue;
    text = text.replaceAll("[0]", "");
    final startIndex = text.indexOf("[", text.indexOf("render_data"));
    final endIndex =
        text.lastIndexOf("]", text.indexOf("__wb_performance_data")) + 1;

    try {
      final jsonStr = text.substring(startIndex, endIndex);
      if (!jsonStr.contains('status')) continue;
      final json = jsonDecode(jsonStr);
      if (json is List) {
        final object = json.first;
        if ((object is Map) && object.containsKey('status')) {
          final status = object['status'];
          title = parseHtmlString(status['text'] ?? "");
          final pics = status["pics"];
          if (pics != null && pics.length > 0) {
            // 图片微博
            for (var i = 0; i < pics.length; i++) {
              if (pics.first?.containsKey('large') ?? false) {
                thumb = pics.first['large']['url'];
              } else {
                thumb = pics.first['url'];
              }
              if (thumb?.isNotEmpty ?? false) {
                break;
              }
            }
          } else {
            final pageInfo = status['page_info'] ?? {};
            final mediaInfo = pageInfo['media_info'];
            final urls = status['urls'];
            if (mediaInfo != null || urls != null) {
              // 视频微博
              if (mediaInfo != null) {
                url = mediaInfo['stream_url'] ?? mediaInfo['stream_url_hd'];
                duration =
                    (double.tryParse(mediaInfo['duration'].toString()) ?? 0)
                        .toInt();
              } else if (urls != null) {
                url = urls['mp4_hd_mp4'] ?? urls['mp4_ld_mp4'];
                duration = 0;
              }
              if (pageInfo.containsKey("page_pic")) {
                thumb = pageInfo['page_pic']['url'];
                final width =
                    double.tryParse(pageInfo['page_pic']['width'].toString()) ??
                        0;
                final height = double.tryParse(
                        pageInfo['page_pic']['height'].toString()) ??
                    1;
                aspectRatio = width / height;
              }
            } else {}
          }
          break;
        } else {
          continue;
        }
      }
    } catch (e) {
      print(e);
    }
  }
  if (url?.isEmpty ?? true) {
    return MeidaInfo(
      title: title,
      artist: "",
      albumName: "",
      url: "",
      aspectRatio: 1,
      thumb: thumb,
      duration: 0,
      canPlay: false,
      mediaType: 'audio',
      siteIcon: "https://m.weibo.cn/favicon.ico",
      siteName: "新浪微博".tr,
    );
  } else {
    return MeidaInfo(
      title: title,
      url: url,
      aspectRatio: aspectRatio,
      thumb: thumb,
      duration: duration,
      siteIcon: "https://m.weibo.cn/favicon.ico",
      siteName: "新浪微博".tr,
    );
  }
}

String parseHtmlString(String htmlString) {
  final document = parser.parse(htmlString);
  return document.body.text;
}
