import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/tool/url_handler/link_handler.dart';
import 'package:pedantic/pedantic.dart';

import '../../../global.dart';
import '../../../routes.dart';

class WebLinkHandler extends LinkHandler {
  @override
  Future handle(String url, {RefererChannelSource refererChannelSource}) async {
    unawaited(Routes.pushHtmlPage(Global.navigatorKey.currentContext, url));
  }

  @override
  bool match(String url) {
    try {
      final _ = Uri.parse(url);
      return url.startsWith("http") || url.startsWith("https");
    } catch (e) {
      return false;
    }
  }
}
