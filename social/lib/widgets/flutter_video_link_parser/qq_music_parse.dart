import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_link_preview/flutter_link_preview.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart' as parser;

import '../../loggers.dart';
import 'flutter_video_link_parser.dart';
import 'http_get.dart';

Future<MeidaInfo> parseQQMusic(Uri uri) async {
  final info = await WebAnalyzer.getInfo(uri.toString());
  if (info == null) return null;
  return _parseQQMusic(info, Uri.parse((info as WebInfo).redirectUrl));
}

Future<MeidaInfo> _parseQQMusic(WebInfo info, Uri uri) async {
  String res;
  try {
    res = await httpGetHtml(uri);
  } catch (e) {
    logger.severe(e);
  }
  if (res == null) return null;
  final document = parser.parse(res);
  String songUrl = "";
  int duration = 0;
  String thumb = "";
  String title = "";
  String artist = "";
  String albumName = "";
  final scriptTags = document.body.getElementsByTagName('script');
  for (final scriptTag in scriptTags) {
    final text = scriptTag.text ?? "";
    if (!text.contains('.m4a')) continue;
    final List<String> contentList = text.split('"');
    for (final String content in contentList) {
      if (content.contains(".m4a") && songUrl.isEmpty) {
        if (content.startsWith("http")) {
          songUrl = content;
          songUrl = content.replaceAll(r"\u002F", '/');
          break;
        }
      }
    }
    if (text.contains("{") && text.contains("}")) {
      try {
        final int start = text.indexOf('{');
        final int end = text.lastIndexOf('}');
        final String jsonStr = text.substring(start, end + 1);
        final Map json = jsonDecode(jsonStr) ?? {};
        for (final mapKey in json.keys) {
          if (mapKey == "songList" && json[mapKey] is List) {
            final List songList = json[mapKey] ?? [];
            final Map songMap = songList.first;
            title = songMap["title"];
            duration = songMap["interval"];
            final List singerList = songMap["singer"];
            final Map firstSinger = singerList.first;
            artist = firstSinger["name"];
            final Map album = songMap["album"];
            albumName = album["name"];
          }
          if (mapKey == "metaData" && json[mapKey] is Map) {
            final Map metaData = json[mapKey];
            thumb = metaData["image"];
          }
        }
      } catch (e) {
        debugPrint("qq音乐解析出错了:$e");
      }
    }
  }
  return MeidaInfo(
    title: title,
    artist: artist,
    albumName: albumName,
    url: songUrl,
    aspectRatio: 1,
    thumb: thumb,
    duration: duration,
    mediaType: 'audio',
    siteIcon: "https://c.y.qq.com/favicon.ico",
    siteName: "QQ音乐".tr,
  );
}
