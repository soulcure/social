import 'dart:convert';

import 'package:flutter_link_preview/flutter_link_preview.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart' as parser;

import '../../loggers.dart';
import 'flutter_video_link_parser.dart';
import 'http_get.dart';

Future<MeidaInfo> parseNetEasyMusic(Uri uri) async {
  final info = await WebAnalyzer.getInfo(uri.toString());
  if (info == null) return null;
  return _parseNetEasyMusic(info, Uri.parse((info as WebInfo).redirectUrl));
}

Future<MeidaInfo> _parseNetEasyMusic(WebInfo info, Uri uri) async {
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
  bool canPlay = false;
  final scriptTags = document.body.getElementsByTagName('script');
  for (final scriptTag in scriptTags) {
    final text = scriptTag.text?.replaceAll(";", "") ?? "";
    if (!(text.contains('Song') && text.contains('window.REDUX_STATE')))
      continue;
    final matches = RegExp(r"(?<=\=).*").allMatches(text);
    for (final match in matches) {
      try {
        final jsonStr = match.group(0).trim();
        if (!jsonStr.contains('Song')) continue;
        final json = jsonDecode(jsonStr);
        if (json is Map) {
          final object = json['Song'];
          if ((object is Map) && object.containsKey('name')) {
            songUrl =
                "http://music.163.com/song/media/outer/url?id=${object['id']}";
            canPlay = await isDownloadUrl(songUrl);
            thumb = object['al']['picUrl'];
            albumName = object['al']['name'];
            title = object['name'];
            artist = object['ar'].first['name'];
            duration = (int.tryParse(object['dt'].toString()) ?? 0) ~/ 1000;
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
    artist: artist,
    albumName: albumName,
    url: songUrl,
    aspectRatio: 1,
    thumb: thumb,
    duration: duration,
    canPlay: canPlay,
    mediaType: 'audio',
    siteIcon: "https://y.music.163.com/favicon.ico",
    siteName: "网易云音乐".tr,
  );
}
