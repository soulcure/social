import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:im/app/modules/mini_program_page/override_url_loading_handler/resolve_wx_pay_in_webview.dart';
import 'package:im/common/extension/future_extension.dart';
import 'package:im/pages/tool/url_handler/circle_link_handler.dart';
import 'package:im/pages/tool/url_handler/link_handler_preset.dart';
import 'package:url_launcher/url_launcher.dart';

// todo 让 interceptor 控制 NavigationActionPolicy
Future<NavigationActionPolicy> overrideUrlLoadingHandler(
    InAppWebViewController controller,
    NavigationAction shouldOverrideUrlLoadingRequest,
    [String referer,
    LinkHandlerPreset interceptors]) async {
  final url = shouldOverrideUrlLoadingRequest.request.url.toString();
  final action = url.split(':').first;
  if (!action.startsWith("http")) {
    launch(url).ignoreError.unawaited;
    return NavigationActionPolicy.CANCEL;
  }
  if (openAndroidWeChatH5Pay(
      controller, shouldOverrideUrlLoadingRequest.request, referer))
    return NavigationActionPolicy.CANCEL;

  if (interceptors != null) {
    final interceptor = await interceptors.handle(url);
    if (interceptor != null &&
        interceptor is CircleLinkHandler &&
        interceptor.lastHandlerState == CircleLinkHandlerState.handleJoined) {
      return NavigationActionPolicy.CANCEL;
    }
  }

  return NavigationActionPolicy.ALLOW;
}
