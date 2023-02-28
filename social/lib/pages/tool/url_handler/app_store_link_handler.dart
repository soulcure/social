import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/tool/url_handler/link_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class AppStoreLinkHandler extends LinkHandler {
  final appStoreLinkReg = RegExp('https://apps.apple.com/.*/id([0-9]+)');

  @override
  bool match(String url) {
    return appStoreLinkReg.hasMatch(url);
  }

  @override
  Future handle(String url, {RefererChannelSource refererChannelSource}) {
    return launch(url, forceSafariVC: false);
  }
}
