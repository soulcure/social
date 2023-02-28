library flutter_video_link_parser;

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:im/widgets/flutter_video_link_parser/kuaishou_parser.dart';
import 'package:im/widgets/flutter_video_link_parser/neteasy_music_parse.dart';
import 'package:im/widgets/flutter_video_link_parser/qq_music_parse.dart';
import 'package:im/widgets/flutter_video_link_parser/sina_weibo_parser.dart';
import 'package:im/widgets/flutter_video_link_parser/taptap_parser.dart';
import 'package:im/widgets/flutter_video_link_parser/wx_article_parser.dart';
import 'package:im/widgets/flutter_video_link_parser/xiao_hong_shu_parser.dart';
import 'package:im/widgets/flutter_video_link_parser/zhi_tong_caijing.dart';

import 'bilibili_parser.dart';
import 'dou_yin_parser.dart';
import 'feishu_doc_parser.dart';

class MeidaInfo {
  MeidaInfo({
    this.url,
    this.title,
    this.artist,
    this.albumName,
    this.aspectRatio,
    this.thumb,
    this.duration,
    this.siteIcon,
    this.siteName,
    this.mediaType = 'video',
    this.canPlay = true,
  });

  final String url;
  final String title;
  final String artist;
  final String albumName;
  final double aspectRatio;
  final String mediaType;
  final String thumb;
  final int duration;
  final String siteIcon;
  final String siteName;
  final bool canPlay;

  factory MeidaInfo.fromRawJson(String str) =>
      MeidaInfo.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory MeidaInfo.fromJson(Map json) => MeidaInfo(
        url: json["url"],
        title: json["title"],
        aspectRatio: json["aspectRatio"],
        thumb: json["thumb"],
        artist: json['artist'],
        albumName: json['albumName'],
        duration: json["duration"],
        siteIcon: json["siteIcon"],
        siteName: json["siteName"],
        canPlay: json['canPlay'],
        mediaType: json["mediaType"],
      );

  Map<String, dynamic> toJson() => {
        "url": url,
        "title": title,
        "aspectRatio": aspectRatio,
        "thumb": thumb,
        "artist": artist,
        "albumName": albumName,
        "duration": duration,
        "siteIcon": siteIcon,
        "siteName": siteName,
        "canPlay": canPlay,
        "mediaType": mediaType,
      };
}

enum SupportedVideoLink {
  unsupoorted,
  taptap,
  bilibili,
  douyin,
  qqmusic,
  neteasymusic,
  kuaishou,
  sinaweibo,
  xiaohongshu,
  wechatarticle,
  feishudoc,
  zhitongcaijing,
}

class MeidaLinkParser {
  static SupportedVideoLink linkType(String uri) {
    if (RegExp("^https?://www.taptap.com/video/").hasMatch(uri))
      return SupportedVideoLink.taptap;

    if (RegExp("^https?://v.douyin.com/").hasMatch(uri))
      return SupportedVideoLink.douyin;

    if (RegExp("^https?://b23.tv/").hasMatch(uri) ||
        RegExp("^https?://(www|m).bilibili.com/video/").hasMatch(uri))
      return SupportedVideoLink.bilibili;

    if (RegExp("^https?://c.y.qq.com/").hasMatch(uri) ||
        RegExp("^https?://y.qq.com/").hasMatch(uri))
      return SupportedVideoLink.qqmusic;

    if (RegExp("^https?://m.weibo.cn/").hasMatch(uri) ||
        RegExp("^https?://weibo.cn/").hasMatch(uri) ||
        RegExp("^https?://weibo.com/").hasMatch(uri))
      return SupportedVideoLink.sinaweibo;

    if (RegExp("^https?://music.163.com/").hasMatch(uri) ||
        RegExp("^https?://y.music.163.com/").hasMatch(uri))
      return SupportedVideoLink.neteasymusic;

    if (RegExp("^https?://v.kuaishou.com/").hasMatch(uri))
      return SupportedVideoLink.kuaishou;

    if (RegExp("^https?://xiaohongshu.com/").hasMatch(uri) ||
        RegExp("^https?://www.xiaohongshu.com/").hasMatch(uri) ||
        RegExp("^https?://xhslink.com/").hasMatch(uri))
      return SupportedVideoLink.xiaohongshu;

    if (RegExp("^https?://mp.weixin.qq.com/").hasMatch(uri))
      return SupportedVideoLink.wechatarticle;

    if (RegExp(r"^https?://\w+.feishu.cn/docs/").hasMatch(uri))
      return SupportedVideoLink.feishudoc;

    if (RegExp("^https?://m.zhitongcaijing.com/").hasMatch(uri) ||
        RegExp("^https?://www.zhitongcaijing.com/").hasMatch(uri))
      return SupportedVideoLink.zhitongcaijing;

    return SupportedVideoLink.unsupoorted;
  }

  static Future<MeidaInfo> parseByType(
      SupportedVideoLink type, String uri) async {
    final uri2 = Uri.parse(uri);
    switch (type) {
      case SupportedVideoLink.taptap:
        return parseTapTap(uri2);
      case SupportedVideoLink.douyin:
        return parseDouYin(uri2);
      case SupportedVideoLink.bilibili:
        return parseBiliBiliShortURL(uri2);
      case SupportedVideoLink.qqmusic:
        return parseQQMusic(uri2);
      case SupportedVideoLink.neteasymusic:
        return parseNetEasyMusic(uri2);
      case SupportedVideoLink.kuaishou:
        return parseKuaishou(uri2);
      case SupportedVideoLink.sinaweibo:
        return parseSinaWeibo(uri2);
      case SupportedVideoLink.xiaohongshu:
        return parseXiaoHongShu(uri2);
      case SupportedVideoLink.feishudoc:
        return parseFeiShuDoc(uri2);
      case SupportedVideoLink.wechatarticle:
        return parseWeChatArticle(uri2);
      case SupportedVideoLink.zhitongcaijing:
        return parseZhiTongCaiJing(uri2);
      default:
        return null;
    }
  }

  final Widget child;

  MeidaLinkParser({this.child});
}
