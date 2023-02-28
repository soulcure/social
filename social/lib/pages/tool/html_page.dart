import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/mini_program_page/override_url_loading_handler/override_url_loading_handler.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/config.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/global.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/tool/url_handler/link_handler_preset.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:im/utils/web_view_utils.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/button/custom_icon_button.dart';
import 'package:im/widgets/default_tip_widget.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:url_launcher/url_launcher.dart';

class HtmlPage extends StatefulWidget {
  final Uri initialUri;
  final String title;
  final bool isNormalURL;

  HtmlPage(
      {Uri initialUri, String initialUrl, this.title, this.isNormalURL = true})
      : initialUri = initialUri ?? Uri.tryParse(initialUrl);

  @override
  _HtmlPageState createState() => _HtmlPageState();
}

class _HtmlPageState extends State<HtmlPage>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  final _progress = ValueNotifier<double>(0);
  final _title = ValueNotifier<String>('页面加载...'.tr);
  final _showCloseButton = ValueNotifier<bool>(false);

  LoadingType _loadingType = LoadingType.loading;

  InAppWebViewController webView;

  ///用于记录WebView微信h5支付前的url，解决微信h5支付传入Referer的问题
  String referer;

  ///超时处理
  RestartableTimer _timer;
  final _timeOutSecond = 20;

  @override
  void initState() {
    _controller = AnimationController(
      value: 0,
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _controller.forward();
    _timer = RestartableTimer(Duration(seconds: _timeOutSecond), () {
      if (_loadingType == LoadingType.loading && _progress.value <= 0.1)
        changeType(LoadingType.error);
    });

    referer = widget.initialUri?.toString();

    WebViewUtils.instance().setWebViewToken();

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _progress.dispose();
    _title.dispose();
    _showCloseButton.dispose();
    if (_timer.isActive) _timer.cancel();
    _timer = null;
    super.dispose();
  }

  Uri getUri() {
    var uri = widget.initialUri;
    if (uri == null) return null;

    if (widget.isNormalURL == false && Config.token.hasValue) {
      //将apptoken追加进去
      uri = widget.initialUri.resolveUri(Uri(queryParameters: {
        'apptoken': Config.token,
        ...widget.initialUri.queryParameters
      }));
    }

    return uri;
  }

  Widget _loadingWidget() {
    return ValueListenableBuilder(
        valueListenable: _progress,
        builder: (context, progress, _) {
          if (progress == 1) return const SizedBox();

          return LinearProgressIndicator(
            value: progress == 0 ? null : progress,
            minHeight: 2,
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final _webContentWidget = Column(
      children: [
        PreferredSize(
          preferredSize: const Size(double.infinity, 44),
          child: CustomAppbar(
            leadWidth: 80,
            backgroundColor: Colors.white,
            leadingBuilder: (icon) {
              return Row(children: [
                sizeWidth12,
                CustomIconButton(
                  iconData: IconFont.buffNavBarBackItem,
                  iconColor: Theme.of(context).textTheme.bodyText2.color,
                  onPressed: () async {
                    try {
                      if (await webView.canGoBack()) {
                        unawaited(webView.goBack());
                      } else {
                        Get.back();
                      }
                    } catch (e) {
                      Get.back();
                    }
                  },
                ),
                sizeWidth12,
                ValueListenableBuilder(
                    valueListenable: _showCloseButton,
                    builder: (context, showCloseButton, _) {
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: showCloseButton ? 1 : 0,
                        child: CustomIconButton(
                          iconData: IconFont.buffNavBarCloseItem,
                          iconColor: Colors.black,
                          onPressed: Navigator.of(context).pop,
                        ),
                      );
                    })
              ]);
            },
            titleBuilder: (style) {
              return ValueListenableBuilder(
                valueListenable: _title,
                builder: (context, title, _) {
                  return Text(
                    widget.title ?? title,
                    style: style,
                  );
                },
              );
            },
            actions: [
              AppbarIconButton(
                icon: IconFont.buffMoreHorizontal,
                onTap: showMore,
              ),
            ],
          ),
        ),
        Expanded(child: buildBody()),
      ],
    );
    return WillPopScope(
      onWillPop: !_showCloseButton.value
          ? null
          : () async {
              try {
                if (await webView.canGoBack()) {
                  unawaited(webView.goBack());
                  return false;
                } else {
                  return true;
                }
              } catch (e) {
                Get.back();
                return true;
              }
            },

      /// 注意：这里不能用 Scaffold，参见 https://idreamsky.feishu.cn/wiki/wikcnsYBfDLUJurPGMrKkYJMXxb Scaffold 和 InAppWebView 导致无法输入第一个字符
      /// 经测试，MIX3不存在上述问题，
      ///  1.android使用Scaffold，解决web输入框无法被键盘顶起的问题
      ///  2.ios继续使用Material（使用scaffold会抖动一下)
      child: UniversalPlatform.isIOS
          ? Material(color: Colors.white, child: _webContentWidget)
          : Scaffold(backgroundColor: Colors.white, body: _webContentWidget),
    );
  }

  Widget buildBody() {
    final uri = getUri();
    if (uri == null || !uri.hasScheme) {
      _loadingType = LoadingType.empty;
    }

    Widget result;
    switch (_loadingType) {
      case LoadingType.complete:
      case LoadingType.loading:
        result = buildWebView();
        break;
      case LoadingType.error:
        result = buildError(context);
        break;
      case LoadingType.empty:
        result = buildEmpty(context);
        break;
    }
    return result;
  }

  Widget buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DefaultTipWidget(
            icon: IconFont.buffCommonWifi,
            text: '网络异常，请重试'.tr,
          ),
          sizeHeight32,
          buildReloadButton(context)
        ],
      ),
    );
  }

  Widget buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DefaultTipWidget(
            icon: IconFont.buffLink,
            text: '抱歉，您访问的页面不存在'.tr,
          ),
          sizeHeight32,
          buildReloadButton(context)
        ],
      ),
    );
  }

  Widget buildWebView() {
    return Stack(
      children: <Widget>[
        Visibility(
          visible: !(_loadingType == LoadingType.error),
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: getUri()),
            initialOptions: InAppWebViewGroupOptions(
                crossPlatform: InAppWebViewOptions(
                  useShouldOverrideUrlLoading: true,
                  useOnDownloadStart: true,
                  applicationNameForUserAgent:
                      '${UniversalPlatform.isMobileDevice ? "Mobile" : "PC"} fanbook/${Global.packageInfo.version}+${Global.packageInfo.buildNumber}',
                ),
                android: AndroidInAppWebViewOptions(
                    mixedContentMode:
                        AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,

                    ///这个属性用于避免部分Android手机使用webview时，输入密码会导致黑屏的问题
                    ///参见这个issue:https://github.com/pichillilorenzo/flutter_inappwebview/issues/536
                    useHybridComposition: true),
                ios: IOSInAppWebViewOptions(
                  allowsInlineMediaPlayback: true,
                )),
            shouldOverrideUrlLoading: (c, u) {
              final res = overrideUrlLoadingHandler(
                  c, u, referer, LinkHandlerPreset.webView);
              referer = u.request.url.toString();
              return res;
            },
            onCreateWindow: (c, createWindowRequest) async {
              await c.loadUrl(urlRequest: createWindowRequest.request);
              return false;
            },
            onTitleChanged: (_, title) => _title.value = title,
            onDownloadStart: (controller, url) {
              logger.finest("WebView recognizes a downloadable file $url");
              showConfirmDialog(
                      content: "网页请求下载文件 %s，是否允许？".trArgs([url.toString()]),
                      confirmText: "允许".tr,
                      cancelText: "拒绝".tr)
                  .then((confirm) {
                if (confirm == true) launch(url.toString());
              });
            },
            onWebViewCreated: (controller) {
              webView = controller;
            },
            onLoadError: (_, u, code, message) async {
              _progress.value = 1;
              _title.value = '';
              switch (code) {
                case 101:
                  changeType(LoadingType.empty);
                  break;
                case -999:

                  ///部分链接会出现该错误，如淘宝链接——IOS
                  if (Platform.isAndroid) changeType(LoadingType.error);
                  break;
                case 102:

                  ///帧框加载已中断，链接为下载链接时候出现了此错误——IOS
                  if (_loadingType == LoadingType.complete ||
                      Platform.isAndroid) changeType(LoadingType.error);
                  break;
                case -1:
                case -10: // net::ERR_UNKNOWN_URL_SCHEME

                  ///部分Android手机在点击下载链接的时候会报这个错误
                  break;
                default:
                  changeType(LoadingType.error);
                  break;
              }
            },
            onProgressChanged: (controller, progress) async {
              if (mounted) _progress.value = progress / 100;
            },
            onLoadStart: (c, url) {
              _loadingType = LoadingType.loading;
            },
            onLoadStop: (c, url) async {
              _showCloseButton.value = await webView.canGoBack();
              if (url.toString() == 'about:blank')
                changeType(LoadingType.empty);
              else if (_loadingType != LoadingType.error) {
                changeType(LoadingType.complete);
                await c.injectJavascriptFileFromAsset(
                    assetFilePath: 'assets/html-page/core.js');
              }
            },
            // 忽略 SSL 证书验证错误，否则有些网站可能打不开，例如 https://api.battleofballs.com/authorized
            onReceivedServerTrustAuthRequest: (_, challenge) => Future.value(
                ServerTrustAuthResponse(
                    action: ServerTrustAuthResponseAction.PROCEED)),
          ),
        ),
        _loadingWidget(),
      ],
    );
  }

  Widget buildReloadButton(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        backgroundColor: CustomColor(context).globalBackgroundColor3,
        shape: const StadiumBorder(),
      ),
      onPressed: () async {
        _controller.reset();
        changeType(LoadingType.loading);
        _timer.reset();
        unawaited(_controller.forward());
      },
      child: Text(
        '重新加载'.tr,
        style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColor),
      ),
    );
  }

  void changeType(LoadingType type) {
    if (_loadingType == type || type == null) return;
    _loadingType = type;
    refresh();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  Future<dynamic> showMore() async {
    // 隐藏键盘
    if (UniversalPlatform.isIOS)
      unawaited(webView.clearFocus());
    else if (UniversalPlatform.isAndroid)
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
    return showBottomModal(
      Get.context,
      backgroundColor: Theme.of(Get.context).backgroundColor,
      resizeToAvoidBottomInset: false,
      showTopCache: false,
      builder: (c, s) => Container(
        color: Theme.of(Get.context).scaffoldBackgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _menuItem(
                  icon: IconFont.buffWebviewRefresh,
                  desc: '刷新'.tr,
                  onPressed: _reload,
                ),
                _menuItem(
                  icon: IconFont.buffWebviewLink,
                  desc: '复制链接'.tr,
                  onPressed: _onCopyLink,
                ),
                _menuItem(
                  icon: IconFont.buffWebviewBrowser,
                  desc: '浏览器打开'.tr,
                  onPressed: _openInBrowser,
                ),
              ],
            ),
            const SizedBox(height: 28),
            _cancelButton(),
          ],
        ),
      ),
    );
  }

  Widget _cancelButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: Get.back,
      child: ColoredBox(
        color: Theme.of(Get.context).backgroundColor,
        child: Column(
          children: [
            Container(
              height: 60,
              alignment: Alignment.center,
              child: Text(
                '取消'.tr,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyText2.color,
                ),
              ),
            ),
            SizedBox(
              height: getBottomViewInset(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
      {@required IconData icon,
      @required String desc,
      @required VoidCallback onPressed}) {
    final backgroundColor = Theme.of(Get.context).backgroundColor;
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          SizedBox(
            child: FadeBackgroundButton(
              onTap: onPressed,
              width: 55,
              height: 55,
              borderRadius: 12,
              backgroundColor: backgroundColor,
              tapDownBackgroundColor: backgroundColor.withOpacity(0.5),
              child: Icon(
                icon,
                size: 24,
                color: Theme.of(Get.context).textTheme.bodyText2.color,
              ),
            ),
          ),
          sizeHeight8,
          Text(
            desc ?? '',
            style: const TextStyle(fontSize: 10, color: Color(0xFF646A73)),
          ),
        ],
      ),
    );
  }

  Future<void> _reload() async {
    Get.back();
    _loadingType = LoadingType.loading;
    refresh();
    await webView.reload();
  }

  Future<void> _onCopyLink() async {
    String url;
    try {
      url = (await webView.getUrl()).toString();
    } catch (e) {
      url = widget.initialUri.toString();
    }
    await Clipboard.setData(ClipboardData(text: url));
    Get.back();
    showToastWidget(
      Container(
        width: 120,
        height: 110,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: Colors.black87, borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check,
              size: 40,
              color: Colors.white,
            ),
            sizeHeight6,
            Text(
              '已复制'.tr,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
      position: ToastPosition.center,
    );
  }

  Future<void> _openInBrowser() async {
    Get.back();
    String url;
    try {
      url = (await webView.getUrl()).toString();
    } catch (e) {
      url = getUri().toString();
    }
    if (await canLaunch(url))
      await launch(
        url,
        forceSafariVC: false,
        forceWebView: false,
      );
  }
}

enum LoadingType { loading, error, empty, complete }
