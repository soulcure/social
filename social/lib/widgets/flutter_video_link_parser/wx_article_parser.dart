import 'dart:convert';
import 'dart:io';
import 'package:flutter_link_preview/flutter_link_preview.dart';
import 'package:get/get.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;

import '../../loggers.dart';
import 'flutter_video_link_parser.dart';
import 'http_get.dart';
import 'parser_utils.dart';
import 'package:http/http.dart' as http;

Future<MeidaInfo> parseWeChatArticle(Uri uri) async {
  final info = await WebAnalyzer.getInfo(uri.toString());
  if (info == null) return null;
  return _parseWeChatArticle(info, Uri.parse((info as WebInfo).redirectUrl));
}

/// 解析公众号视频
Future<MeidaInfo> _parseVideoIfExist(WebInfo info, Document document) async {
  String url;
  String thumb = "";
  final title = info.title ?? info.description ?? "";
  double aspectRatio = 16 / 9;
  int duration = 0;
  final iframe = document.getElementsByTagName('iframe');
  if (iframe.isNotEmpty) {
    final attributes = iframe[0].attributes;
    final vId = getRecursionKeyFromMap("data-mpvid", attributes);
    if (vId == null) return null;
    thumb = Uri.decodeComponent(
        getRecursionKeyFromMap("data-cover", attributes) ?? "");
    aspectRatio =
        double.parse(getRecursionKeyFromMap("data-ratio", attributes)) ??
            aspectRatio;
    final reqUrl =
        "https://mp.weixin.qq.com/mp/videoplayer?action=get_mp_video_play_url&vid=$vId&clientversion=&f=json";
    final response = await http.get(Uri.parse(reqUrl));
    final repJson = await parseJson(utf8.decode(response.bodyBytes));
    final videoUrlInfo = getRecursionKeyFromMap("url_info", repJson) ?? [];
    if (videoUrlInfo is List && videoUrlInfo.isNotEmpty) {
      url = videoUrlInfo[0]['url'];
      duration = (videoUrlInfo[0]['duration_ms'] ?? 0) ~/ 1000;
      final isMpVideoDelete =
          getRecursionKeyFromMap("is_mp_video_delete", repJson);
      final isMpVideoForbid =
          getRecursionKeyFromMap("is_mp_video_forbid", repJson);
      if (isMpVideoDelete != 0 || isMpVideoForbid != 0) return null;
      return MeidaInfo(
        title: title,
        url: url,
        aspectRatio: aspectRatio,
        thumb: thumb,
        duration: duration,
        siteIcon: "https://m.weibo.cn/favicon.ico",
        siteName: "微信".tr,
      );
    }
  }
  return null;
}

/// 解析公众号音频
Future<MeidaInfo> _parseAudioIfExist(WebInfo info, Document document) async {
  final title = info.title ?? info.description ?? "";
  final mpvoice = document.body.getElementsByTagName("mpvoice");
  if (mpvoice.isEmpty) return null;
  final voiceEncodeFileid = mpvoice[0].attributes['voice_encode_fileid'];
  final playLength = mpvoice[0].attributes['play_length'] ?? "0";
  final voiceInfoUrl =
      "https://res.wx.qq.com/voice/getvoice?mediaid=$voiceEncodeFileid";
  final voiceRep = await http.head(Uri.parse(voiceInfoUrl));
  if (voiceRep.statusCode == 200 &&
      voiceRep.headers[HttpHeaders.contentTypeHeader].contains("audio") &&
      (int.tryParse(voiceRep.headers[HttpHeaders.contentLengthHeader]) ?? 0) >
          0) {
    return MeidaInfo(
      title: title,
      artist: "",
      albumName: "",
      url: voiceInfoUrl,
      aspectRatio: 1,
      thumb: info.mediaUrl,
      duration: (int.tryParse(playLength) ?? 0) ~/ 1000,
      mediaType: 'audio',
      siteIcon: "https://m.weibo.cn/favicon.ico",
      siteName: "微信".tr,
    );
  }
  return null;
}

Future<MeidaInfo> _parseWeChatArticle(WebInfo info, Uri uri) async {
  try {
    final res = await httpGetHtml(uri);
    if (res == null) return null;
    final document = parser.parse(res);
    MeidaInfo meidaInfo;
    meidaInfo ??= await _parseVideoIfExist(info, document);
    meidaInfo ??= await _parseAudioIfExist(info, document);
    return meidaInfo;
  } catch (e) {
    logger.severe(e);
  }
  return null;
}
