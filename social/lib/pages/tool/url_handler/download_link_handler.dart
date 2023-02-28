import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:url_launcher/url_launcher.dart';

import 'link_handler.dart';

// TODO 下载会被 webview 拦截，这个拦截器理论上没用
class DownloadLinkHandler extends LinkHandler {
  @override
  bool match(String url) {
    // 拦截下载
    if (UniversalPlatform.isIOS) {
      if (url.startsWith("itms-appss://apps.apple.com") ||
          url.startsWith("https://itunes.apple.com")) {
        return true;
      }
    } else if (UniversalPlatform.isAndroid) {
      if (url.startsWith("http") && url.endsWith('.apk')) {
        return true;
      }
    }
    return false;
  }

  @override
  Future handle(String url, {RefererChannelSource refererChannelSource}) {
    return launch(url, forceSafariVC: false);
  }
}
