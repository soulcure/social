import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

bool openAndroidWeChatH5Pay(
    InAppWebViewController controller, URLRequest request, String referer) {
  if (!Platform.isAndroid) return false;
  final uri = request.url;
  const weChatPayHost = 'wx.tenpay';
  if (!uri.host.startsWith(weChatPayHost)) {
    return false;
  }

  final header = request.headers;
  if (header == null) request.headers = {};
  request.headers['Referer'] = referer;
  controller.loadUrl(urlRequest: request);
  return true;
}
