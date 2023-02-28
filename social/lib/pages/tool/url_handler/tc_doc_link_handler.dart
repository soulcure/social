import 'package:get/get.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/tool/url_handler/link_handler.dart';
import 'package:pedantic/pedantic.dart';

class TcDocLinkHandler extends LinkHandler {
  TcDocLinkHandler();

  @override
  bool match(String url) {
    return url.contains('fanbook.mobi/doc/');
  }

  @override
  Future handle(String url, {RefererChannelSource refererChannelSource}) async {
    unawaited(Get.toNamed(Routes.TC_DOC_PAGE, parameters: {'appId': url}));
  }
}
