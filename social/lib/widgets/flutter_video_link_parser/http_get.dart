import 'dart:convert';
import 'dart:io';

import 'package:flutter_link_preview/link_fetch.dart';
import 'package:fast_gbk/fast_gbk.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';

import '../../loggers.dart';

Future<Map> httpGet(Uri url, {String encodeUrl = "true"}) async {
  String responseBody = "{}";
  if (Platform.isIOS) {
    final response =
        await LinkFetch.linkFetch(url: url.toString(), encodeUrl: encodeUrl);
    try {
      responseBody = const Utf8Decoder().convert(response['data']);
    } catch (e) {
      try {
        responseBody = gbk.decode(response['data']);
      } catch (e) {
        print("Web page resolution failure from:$url Error:$e");
      }
    }
  } else {
    final request = await HttpClient().getUrl(url);
    final response = await request.close();
    responseBody = await response.transform(const Utf8Decoder()).join();
  }
  final resJson = jsonDecode(responseBody);
  return resJson;
}

Future<String> httpGetHtml(Uri url) async {
  String responseBody;
  if (Platform.isIOS) {
    final response = await LinkFetch.linkFetch(url: url.toString());
    try {
      responseBody = const Utf8Decoder().convert(response['data']);
    } catch (e) {
      try {
        responseBody = gbk.decode(response['data']);
      } catch (e) {
        print("Web page resolution failure from:$url Error:$e");
      }
    }
  } else {
    Response response;
    try {
      response = await _requestUrl(url.toString());
    } catch (e, s) {
      logger.severe("httpGetHtml", e, s);
    }
    if (response?.statusCode?.toString() == HttpStatus.ok.toString()) {
      try {
        responseBody = const Utf8Decoder().convert(response.bodyBytes);
      } catch (e) {
        try {
          responseBody = gbk.decode(response.bodyBytes);
        } catch (e, s) {
          logger.severe("httpGetHtml", e, s);
        }
      }
    }
  }
  return responseBody;
}

bool _certificateCheck(X509Certificate cert, String host, int port) => true;

String _getCookies(String host) {
  if (host.contains("m.weibo.cn")) {
    return "YF-Page-G0=02467fca7cf40a590c28b8459d93fb95|1596707497|1596707497; SUB=_2AkMod12Af8NxqwJRmf8WxGjna49_ygnEieKeK6xbJRMxHRl-yT9kqlcftRB6A_dzb7xq29tqJiOUtDsy806R_ZoEGgwS; SUBP=0033WrSXqPxfM72-Ws9jqgMF55529P9D9W59fYdi4BXCzHNAH7GabuIJ";
  }
  if (host.contains("weibo.com")) {
    return "YF-Page-G0=02467fca7cf40a590c28b8459d93fb95|1596707497|1596707497; SUB=_2AkMod12Af8NxqwJRmf8WxGjna49_ygnEieKeK6xbJRMxHRl-yT9kqlcftRB6A_dzb7xq29tqJiOUtDsy806R_ZoEGgwS; SUBP=0033WrSXqPxfM72-Ws9jqgMF55529P9D9W59fYdi4BXCzHNAH7GabuIJ";
  }
  if (host.contains("feishu.cn")) {
    return "session=U7CK1RF-c09t7d68-96e8-48b1-b4fe-dd9bf5426931-NN5W4";
  }
  return null;
}

Future<Response> _requestUrl(String url,
    {int count = 0, String cookie, useDesktopAgent = false}) async {
  try {
    if (url.contains("feishu.cn/doc")) useDesktopAgent = true;

    Response res;
    final uri = Uri.parse(url);
    final ioClient = HttpClient()..badCertificateCallback = _certificateCheck;
    final client = IOClient(ioClient);
    final request = Request('GET', uri)
      ..followRedirects = false
      // ..headers["User-Agent"] =
      //     "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_1 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Version/10.0 Mobile/14E304 Safari/602.1Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_1 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Version/10.0 Mobile/14E304 Safari/602.1"
      ..headers["User-Agent"] = useDesktopAgent
          ? "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.125 Safari/537.36"
          : "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1"
      ..headers["cache-control"] = "no-cache"
      ..headers["Cookie"] = cookie ?? _getCookies(uri.host) ?? ""
      ..headers["accept"] = "*/*"
      ..headers['Host'] = uri.host;
    final stream = await client.send(request);

    if (stream.statusCode == HttpStatus.movedTemporarily ||
        stream.statusCode == HttpStatus.movedPermanently) {
      if (stream.isRedirect && count < 16) {
        final String location = stream.headers['location'];
        if (location != null) {
          url = location;
          if (location.startsWith("/")) {
            url = uri.origin + location;
          }
        }
        if (stream.headers['set-cookie'] != null) {
          cookie = stream.headers['set-cookie'];
        }
        count++;
        client.close();
        return _requestUrl(url, count: count, cookie: cookie);
      }
    } else if (stream.statusCode == HttpStatus.ok) {
      /// 超过 100m 的网页不解析
      final contentLength = stream.headers["content-length"];
      if (contentLength != null && contentLength.isNotEmpty) {
        if (double.parse(contentLength) > 100 * 1000 * 1000) {
          client.close();
          return null;
        }
      }

      final contentType = stream.headers["content-type"];
      if (contentType.contains("image/") || contentType.contains("video/")) {
        client.close();
        return Response("body", stream.statusCode, headers: stream.headers);
      }

      if (contentType.contains("text/html") ||
          contentType.contains("text/asp")) {
        res = await Response.fromStream(stream);
        if (uri.host == "m.tb.cn") {
          final match = RegExp(r"var url = \'(.*)\'").firstMatch(res.body);
          if (match != null) {
            final newUrl = match.group(1);
            if (newUrl != null) {
              return _requestUrl(newUrl, count: count, cookie: cookie);
            }
          }
        }
      }
    }
    client.close();
    if (res == null) print("Get web info empty($url)");
    return res;
  } catch (e) {
    logger.info("_requestUrl error: $e");
    return null;
  }
}

Future<Map> _requestHeaderUrl(String url,
    {int count = 0, String cookie}) async {
  Map header;
  final uri = Uri.parse(url);
  final ioClient = HttpClient()..badCertificateCallback = _certificateCheck;
  final client = IOClient(ioClient);
  final request = Request('HEAD', uri)
    ..followRedirects = false
    ..headers["User-Agent"] =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_1 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Version/10.0 Mobile/14E304 Safari/602.1Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_1 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Version/10.0 Mobile/14E304 Safari/602.1"
    ..headers["cache-control"] = "no-cache"
    ..headers["Cookie"] = cookie ?? _getCookies(uri.host) ?? ""
    ..headers["accept"] = "*/*";
  final stream = await client.send(request);

  if (stream.statusCode == HttpStatus.movedTemporarily ||
      stream.statusCode == HttpStatus.movedPermanently) {
    if (stream.isRedirect && count < 16) {
      final String location = stream.headers['location'];
      if (location != null) {
        url = location;
        if (location.startsWith("/")) {
          url = uri.origin + location;
        }
      }
      if (stream.headers['set-cookie'] != null) {
        cookie = stream.headers['set-cookie'];
      }
      count++;
      client.close();
      return _requestHeaderUrl(url, count: count, cookie: cookie);
    }
  } else if (stream.statusCode == HttpStatus.ok) {
    /// 超过 100m 的网页不解析
    header = stream.headers;
  }
  client.close();
  return header;
}

Future<bool> isDownloadUrl(String url) async {
  final Map header = await _requestHeaderUrl(url);
  try {
    return !header['content-type'].contains('text');
  } catch (e) {
    logger.severe(e);
    return false;
  }
}
