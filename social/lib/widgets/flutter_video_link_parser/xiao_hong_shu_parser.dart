import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:im/loggers.dart';
import 'package:universal_html/html.dart';
import 'flutter_video_link_parser.dart';
import 'dart:io';
import 'parser_utils.dart';

class _CookieException implements Exception {}

IOClient _xhsClient;
Map<String, String> _reqHeader;

Future<MeidaInfo> parseXiaoHongShu(Uri uri) async {
  _xhsClient ??= IOClient(HttpClient());
  return _XHSParseImp(uri).parseXiaoHongShu();
}

///小红书链接解析实现
class _XHSParseImp {
  /// 解析链接
  final Uri parseUrl;

  /// cookie到期失败，重新获取cookie并重试
  int _retryCount = 1;
  _XHSParseImp(this.parseUrl);

  /// 通过短链获取小红书的重定向url
  Future<String> _getFactLocation(Uri uri) async {
    final request = Request('GET', uri)
      ..followRedirects = false
      ..headers['Host'] = uri.host;
    final stream = await _xhsClient.send(request);
    String reUrl;
    if (stream.statusCode == HttpStatus.temporaryRedirect) {
      reUrl = stream.headers['location'];
    }
    return reUrl;
  }

  /// 获取小红书解析必要的cookie
  Future<Map<String, String>> _getReqCookie() async {
    final request = Request(
        'POST',
        Uri.parse(
            'https://www.xiaohongshu.com/fe_api/burdock/v2/shield/registerCanvas?p=cc'))
      ..bodyFields = {
        "id": "8210e9657929a66462ca1a7f01e3439f",
        "sign":
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.80 Safari/537.36~~~false~~~zh~~~30~~~8~~~8~~~-480~~~Asia/Shanghai~~~1~~~1~~~1~~~1~~~unknown~~~MacIntel~~~PDF Viewer::Portable Document Format::application/pdf~pdf,text/pdf~pdf,Chrome PDF Viewer::Portable Document Format::application/pdf~pdf,text/pdf~pdf,Chromium PDF Viewer::Portable Document Format::application/pdf~pdf,text/pdf~pdf,Microsoft Edge PDF Viewer::Portable Document Format::application/pdf~pdf,text/pdf~pdf,WebKit built-in PDF::Portable Document Format::application/pdf~pdf,text/pdf~pdf~~~canvas winding:yes~canvas fp:dd4e84967d6c8998e78dadec914d4294~~~false~~~false~~~false~~~false~~~false~~~0;false;false~~~2;3;6;7;8~~~124.04344968475198"
      };
    final rigisterCanvas = await _xhsClient.send(request);
    final cookieString = rigisterCanvas.headers["set-cookie"];
    if (cookieString == null || cookieString.isEmpty) return null;
    final cookie = Cookie.fromSetCookieValue(cookieString);
    //todo: cookie.expires 目前不确定这个过期时间是否准确
    return {'cookie': "timestamp2=${cookie.value}"};
  }

  /// 解析小红书里的图片和视频
  Future<MeidaInfo> _obtainNoteInfo(
      String url, Map<String, String> headers) async {
    final header = {'accept-language': "zh-CN,zh;q=0.9,en;q=0.8", ...headers};
    final webpage = await _xhsClient.get(Uri.parse(url), headers: header);
    final body = webpage.body.replaceAll(" ", "");
    const startStr = '"NoteView":';
    const endStr = "}</script>";
    final start = body.indexOf(startStr);
    if (start == -1) {
      _reqHeader = null;
      throw _CookieException();
    }
    final end = body.indexOf(endStr, start);
    final sub = body.substring(start + startStr.length, end);
    final dic = await parseJson(sub);
    final title = getRecursionKeyFromMap("noteInfo.title", dic);
    //final desc = getRecursionKeyFromMap("noteInfo.desc", dic);
    String coverUrl = getRecursionKeyFromMap("noteInfo.cover.url", dic);
    if (coverUrl.startsWith("//")) coverUrl = "http:$coverUrl";
    final type = getRecursionKeyFromMap("noteInfo.type", dic);
    if (type == "video") {
      final videoUrl = getRecursionKeyFromMap("noteInfo.video.url", dic);
      final videoDur = getRecursionKeyFromMap("noteInfo.video.duration", dic);
      final videoW = getRecursionKeyFromMap("noteInfo.video.width", dic) ?? 16;
      final videoH = getRecursionKeyFromMap("noteInfo.video.height", dic) ?? 9;
      return MeidaInfo(
        title: title,
        url: videoUrl,
        aspectRatio: videoW / videoH,
        thumb: coverUrl,
        duration: videoDur,
        siteIcon: "https://www.xiaohongshu.com/favicon.ico",
        siteName: "小红书",
      );
    }
    if (type == "normal") {
      return MeidaInfo(
        title: title,
        artist: "",
        albumName: "",
        url: "",
        aspectRatio: 1,
        thumb: coverUrl,
        duration: 0,
        canPlay: false,
        mediaType: 'audio',
        siteIcon: "https://www.xiaohongshu.com/favicon.ico",
        siteName: "小红书",
      );
    }
    return null;
  }

  /// 解析小红书短链
  Future<MeidaInfo> _parseXiaoHongShuShortlink(Uri uri) async {
    final reUrl = await _getFactLocation(uri);
    if (reUrl == null) return null;
    _reqHeader ??= await _getReqCookie();
    if (_reqHeader == null) return null;
    return _obtainNoteInfo(reUrl, _reqHeader);
  }

  /// 解析小红书重定向后链接
  Future<MeidaInfo> _parseXiaoHongShuLonglink(Uri uri) async {
    final reUrl = uri.toString();
    _reqHeader ??= await _getReqCookie();
    if (_reqHeader == null) return null;
    return _obtainNoteInfo(reUrl, _reqHeader);
  }

  Future<MeidaInfo> parseXiaoHongShu() async {
    try {
      if (RegExp("xhslink.com").hasMatch(parseUrl.host)) {
        return await _parseXiaoHongShuShortlink(parseUrl);
      } else if (RegExp("xiaohongshu.com").hasMatch(parseUrl.host)) {
        return await _parseXiaoHongShuLonglink(parseUrl);
      }
    } catch (e) {
      logger.info("parse xiaohongshu error: $e");
      if (e is _CookieException && _retryCount > 0) {
        _retryCount--;
        return parseXiaoHongShu();
      } else {
        return null;
      }
    }
    return null;
  }
}
