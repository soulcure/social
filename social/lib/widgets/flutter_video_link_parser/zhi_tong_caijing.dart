import 'package:flutter_link_preview/flutter_link_preview.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart' as parser;
import 'package:im/loggers.dart';

import 'flutter_video_link_parser.dart';
import 'http_get.dart';

Future<MeidaInfo> parseZhiTongCaiJing(Uri uri) async {
  String redirectUri = uri.toString();
  if (uri.path.contains("new-article") && uri.fragment.contains("?id=")) {
    final articleId =
        uri.fragment.substring(uri.fragment.indexOf("?id=")).substring(4);
    redirectUri = "${uri.origin}/content/detail/$articleId.html";
  }
  final info = await WebAnalyzer.getInfo(redirectUri);
  if (info == null) return null;
  return _parseZhiTongCaiJing(info, Uri.parse((info as WebInfo).redirectUrl));
}

Future<MeidaInfo> _parseZhiTongCaiJing(WebInfo info, Uri uri) async {
  String res;
  try {
    res = await httpGetHtml(uri);
  } catch (e) {
    logger.severe(e);
  }
  if (res == null) return null;
  final document = parser.parse(res);
  String url;
  final title =
      document.head.getElementsByTagName('title')?.first?.innerHtml ?? "智通财经网";
  const aspectRatio = 16 / 9;
  const duration = 0;
  final articleTags = document.body.getElementsByTagName('article');
  final imageArticTag = articleTags?.first;
  final imageTags = imageArticTag?.getElementsByTagName("img");
  String thumb = "";
  if ((imageTags?.length ?? 0) > 0) {
    final imagePath = imageTags?.first?.outerHtml
        ?.split(" ")
        ?.firstWhere((element) => element.startsWith("src="));
    thumb =
        imagePath?.removeAllWhitespace?.substring(5, imagePath.length - 1) ??
            "";
  }

  return MeidaInfo(
    title: title,
    url: url,
    aspectRatio: aspectRatio,
    thumb: thumb,
    canPlay: false,
    mediaType: "audio",
    duration: duration,
    siteIcon: "https://m.zhitongcaijing.com/favicon.ico",
    siteName: "智通财经".tr,
  );
}

String parseHtmlString(String htmlString) {
  final document = parser.parse(htmlString);
  return document.body.text;
}
