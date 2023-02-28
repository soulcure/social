import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/tool/url_handler/link_handler.dart';
import 'package:im/utils/tc_doc_utils.dart';

class TcDocLinkInnerHandler extends LinkHandler {
  @override
  Future handle(String url,
      {RefererChannelSource refererChannelSource}) async {}

  @override
  bool match(String url) {
    /// 首次进入文档时会重定向，发生多次跳转，会出现以下几种url，需要直接跳转，不做处理
    // https://fanbook.mobi/doc/*****
    // https://docs.qq.com/openapi/drive/v2/files/embed/temporary?timestamp=1652522975&id=0ad771e67d9d4e8da7ac3c0e69ba7cb9&clientID=fcbd12e670db451faf79ba72a0c70f5e
    // https://docs.qq.com/doc/DRUp5dFpzV0F6WnRU?
    // about:blank

    /// 点击文档内链接跳转时，会先跳到
    /// https://docs.qq.com/scenario/link.html?url=http%3A%2F%2Fwww.baidu.com&pid=300000000$EJytZsWAzZtT&cid=144115352750017092
    /// 再做重定向
    try {
      final _ = Uri.parse(url);
      final matched = TcDocUtils.docUrlReg.hasMatch(url) ||
          url.startsWith("https://docs.qq.com/openapi") ||
          url.startsWith("https://tdocs.processon.com/") ||
          url == 'about:blank' ||
          TcDocUtils.tcDocUrlReg.hasMatch(url);
      return matched;
    } catch (e) {
      return false;
    }
  }
}
