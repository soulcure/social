import 'dart:convert';

import 'package:get/get.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/tool/url_handler/link_handler.dart';
import 'package:pedantic/pedantic.dart';

class MiniProgramLinkHandler extends LinkHandler {
  MiniProgramLinkHandler();

  @override
  bool match(String url) {
    final uri = Uri.parse(url);
    return matchQueryRule(uri) || matchPathRule(uri);
  }

  bool matchQueryRule(Uri url) {
    final pRedirect = url.queryParameters["fb_redirect"];
    final pOpenType = url.queryParameters["open_type"] ?? '';
    return pRedirect != null && pOpenType.toLowerCase() == 'mp';
  }

  bool matchPathRule(Uri url) {
    final checkHost =
        url.host == "fanbook.mobi" || url.host == "open.fanbook.mobi";
    return checkHost &&
        url.pathSegments.length > 1 &&
        url.pathSegments[0] == "mp";
  }

  String getUrl(Uri uri) {
    if (matchPathRule(uri)) {
      if (uri.host != "open.fanbook.mobi") {
        try {
          return const Utf8Decoder()
              .convert(base64Decode(Uri.decodeComponent(uri.pathSegments[1])));
        } catch (e) {
          /// ignore
        }
      }
    }
    return uri.toString();
  }

  @override
  Future handle(String url, {RefererChannelSource refererChannelSource}) async {
    final uri = Uri.parse(url);
    unawaited(Get.toNamed(Routes.MINI_PROGRAM_PAGE,
        parameters: {'appId': getUrl(uri), 'previousRoute': Get.currentRoute}));
  }
}
