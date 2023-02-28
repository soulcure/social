import 'package:flutter_link_preview/flutter_link_preview.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart' as parser;

import '../../loggers.dart';
import 'flutter_video_link_parser.dart';
import 'http_get.dart';
import 'parser_utils.dart';

Future<MeidaInfo> parseFeiShuDoc(Uri uri) async {
  final info = await WebAnalyzer.getInfo(uri.toString());
  if (info == null) return null;
  return _parseFeiShuDoc(info, Uri.parse((info as WebInfo).redirectUrl));
}

/// 飞书文档目前只写获取到标题, 只飞书外部文档可以解析
/// 文档中的图片key: data.collab_client_vars.resources.images
/// 文档中视频\音频目前无法获取
Future<MeidaInfo> _parseFeiShuDoc(WebInfo info, Uri uri) async {
  try {
    String res = await httpGetHtml(uri);
    if (res == null) return null;
    res = res.replaceAll(" ", "");
    const startStr = "window.DATA={clientVars:Object(";
    const endStr = ")};</script>";
    final start = res.indexOf(startStr);
    final end = res.indexOf(endStr, start);
    final sub = res.substring(start + startStr.length, end);
    final dic = await parseJson(sub);

    String thumb = "";
    final title =
        getRecursionKeyFromMap("data.collab_client_vars.title", dic) ?? "";
    final imgs =
        getRecursionKeyFromMap("data.collab_client_vars.resources.images", dic);
    if (imgs != null && imgs is List && imgs.isNotEmpty) {
      thumb = Uri.decodeComponent(imgs[0]['src']).toString();
    }
    if (title is String && title.isEmpty && thumb.isEmpty) return null;
    return MeidaInfo(
      title: title,
      artist: "",
      albumName: "",
      url: "",
      aspectRatio: 1,
      thumb: thumb,
      duration: 0,
      canPlay: false,
      mediaType: '',
      siteIcon:
          "https://sf3-scmcdn2-cn.feishucdn.com/eesz/resource/bear/-favicon-v3.ico",
      siteName: "飞书".tr,
    );
  } catch (e) {
    logger.severe(e);
    return null;
  }
}

String parseHtmlString(String htmlString) {
  final document = parser.parse(htmlString);
  return document.body.text;
}
