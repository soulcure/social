import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/tool/url_handler/bot_callback_link_handler.dart';
import 'package:im/pages/tool/url_handler/circle_channel_link_handler.dart';
import 'package:im/pages/tool/url_handler/link_handler.dart';
import 'package:im/pages/tool/url_handler/mini_program_link_handler.dart';
import 'package:im/pages/tool/url_handler/tc_doc_link_handler.dart';
import 'package:im/pages/tool/url_handler/web_link_handler.dart';

import 'app_store_link_handler.dart';
import 'circle_link_handler.dart';
import 'download_link_handler.dart';
import 'invite_link_handler.dart';
import 'live_link_handler.dart';

class LinkHandlerPreset {
  /// inApp 预设能始终停留在 Fanbook 内，不会因为是下载链接就打开外部应用
  static LinkHandlerPreset inApp = LinkHandlerPreset([
    const InviteLinkHandler(),
    LiveLinkHandler(),
    TcDocLinkHandler(),
    MiniProgramLinkHandler(),
    CircleLinkHandler(),
    CircleChannelLinkHandler(),
    // !!! IMPORTANT WebLinkHandler 必须放最后一个，因为它的 match 始终是 true
    WebLinkHandler(),
  ]);

  /// app 内常用的链接处理，除了包含所有 inApp 的规则，还能打开外部应用（目前只有 AppStore）
  static LinkHandlerPreset common = LinkHandlerPreset.inApp.appendAll([
    AppStoreLinkHandler(),
  ]);

  static LinkHandlerPreset bot = LinkHandlerPreset.common.appendAll([
    BotLinkHandler(),
  ]);

  /// WebView 内的链接处理
  /// 1. 检查邀请连接，自动打开邀请弹出
  /// 1. 检查下载地址，打开系统浏览器下载
  /// 2. 检查 AppStore 商品地址，打开 AppStore 展示
  /// 3. 打开圈子链接
  static LinkHandlerPreset webView = LinkHandlerPreset([
    const InviteLinkHandler(),
    DownloadLinkHandler(),
    AppStoreLinkHandler(),
    CircleLinkHandler(autoOpenHtml: false),
  ]);

  /// Fanbook 小程序内的链接处理
  /// 1. 检查邀请连接，自动打开邀请弹出
  static LinkHandlerPreset miniProgram = LinkHandlerPreset([
    const InviteLinkHandler(),
    CircleLinkHandler(autoOpenHtml: false),
  ]);

  final List<LinkHandler> interceptors;

  const LinkHandlerPreset(this.interceptors);

  Future<LinkHandler> handle(String url,
      {RefererChannelSource refererChannelSource =
          RefererChannelSource.None}) async {
    for (final i in interceptors) {
      try {
        if (i.match(url)) {
          await i.handle(url, refererChannelSource: refererChannelSource);
          return i;
        }
      } catch (_) {}
    }
    return null;
  }

  LinkHandlerPreset appendAll(List<LinkHandler> list) {
    // 必须保证 WebLinkHandler 在最后一个保底
    return LinkHandlerPreset(
        [...interceptors]..insertAll(interceptors.length - 1, list));
  }
}
