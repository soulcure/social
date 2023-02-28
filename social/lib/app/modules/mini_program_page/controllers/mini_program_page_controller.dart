import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:glob/glob.dart';
import 'package:im/app/modules/mini_program_page/entity/mini_program_config.dart';
import 'package:im/app/modules/mini_program_page/override_url_loading_handler/override_url_loading_handler.dart';
import 'package:im/app/routes/app_pages.dart' as get_routes;
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/mini-program/javascript_hander.dart';
import 'package:im/pages/tool/url_handler/link_handler_preset.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:im/utils/web_view_utils.dart';
import 'package:pedantic/pedantic.dart';

import '../../../../loggers.dart';
import '../../../../routes.dart';

const double navigationBarHeight = 44;

// webview内部实现
// anroid：WebViewClient，错误码：https://developer.android.com/reference/android/webkit/WebViewClient
// ios：UIWebView  错误码：https://cloud.tencent.com/developer/article/1332219

const int iosNetworkErrorCode = -1009;

// 页面未加载完退出页面会走onLoadError返回-999
const int iosNSURLErrorCancelledCode = -999;

const int androidNetworkErrorCode = -2;

class MiniProgramPageController extends GetxController {
  static const updateIdSnackBar = 'snackBar';

  bool closeButtonVisible = false;
  Future<String> coreJsFuture;

//  初始路径
  String appId;

  // 进入小程序之前的路由名称
  // String _previousRoute;

  String referer;

  // String get previousRoute => _previousRoute;
  InAppWebViewController webViewController;
  bool loading = true;

  // 当前页面路径，
  String currentUrl;

  ValueKey webViewKey = const ValueKey(0);
  bool isNetworkError = false;
  bool isOtherError = false;
  bool webViewVisible = true;

  String title = '';

  // 所有小程序的设置
  final Map<String, MiniProgramConfig> _miniProgramConfigMap =
      <String, MiniProgramConfig>{};

  MiniProgramConfig _miniProgramConfig(String appId) =>
      _miniProgramConfigMap[appId];

  // 未初始化完成默认为null
  MiniProgramPageConfig currentPageConfig;

  // 需在初始化完后调用
  bool get isLightMode =>
      showNavigationBar &&
      (currentPageConfig?.navigationBarBackgroundColor == Colors.white);

  bool get showNavigationBar => currentPageConfig?.showNavigationBar ?? true;

  String get displayTitle =>
      currentPageConfig?.navigationBarTitleText ?? title ?? '';

  Color get appBarBackgroundColor =>
      currentPageConfig?.navigationBarBackgroundColor ?? Colors.white;

  bool get shouldShowWebview => !(loading || isNetworkError || isOtherError);

  Color get navigationBarTextColor => currentPageConfig?.navigationBarTextColor;

  bool get hasError => isOtherError || isNetworkError;

  Offset snackBarOffset = const Offset(0, -1);

  bool get snackBarVisible => snackBarOffset.dy > 0;

  double snackBarOpacity = 0;

  bool inputVisible = false;

  bool resizeToAvoidBottomInset = true;

  TextEditingController inputController;

  Completer<String> inputComplete;

  FocusNode inputFocus;

  Color inputColor = const Color(0xFF8ABF6D);

  StreamSubscription keyboardSubscription;

  @mustCallSuper
  @override
  void onInit() {
    appId = Get.parameters['appId'];
    referer = appId;
    initCoreJsFuture();
    WebViewUtils.instance().setWebViewToken();
    inputController = TextEditingController();
    inputFocus = FocusNode()
      ..addListener(() {
        inputController.clear();
      });
    keyboardSubscription =
        KeyboardVisibilityController().onChange.listen(_onKeyboardChange);
    super.onInit();
  }

  void _onKeyboardChange(bool visible) {
    if (!visible) {
      inputFocus.unfocus();
      inputVisible = false;
      update();
    }
    // }
  }

  @override
  void onClose() {
    inputController.dispose();
    inputFocus.dispose();
    keyboardSubscription.cancel();
    super.onClose();
  }

  void initCoreJsFuture() {
    coreJsFuture = () async {
      try {
        await loadConfigJson();
        final coreJs = await PlatformAssetBundle()
            .loadString('assets/mini-program/core.js');
        return coreJs;
      } catch (e, s) {
        loading = false;
        isNetworkError = e is DioError;
        isOtherError = !isNetworkError;
        update();
        logger.severe('mini_program', e, s);
      }
    }();
  }

  Future<MiniProgramConfig> loadConfigJson() async {
    final originUri = Uri.parse(appId);
    final jsonUrl = '${originUri.origin}/fbmp.json';
    try {
      final res = await Http.dio.get(jsonUrl).timeout(2.seconds);
      if (res.data is! Map) return null;
      final config = MiniProgramConfig.fromJson(res.data);
      _miniProgramConfigMap[appId] = config;
      return config;
    } catch (e) {
      logger.info('miniprogram：未找到小程序配置文件');
      return null;
    }
  }

  Uri getRequestUri() {
    final originUri = Uri.parse(appId);
    final params = Uri.splitQueryString(originUri.query)
      // querystring 加入时间戳参数防止页面缓存
      ..putIfAbsent(
          'fb_v', () => DateTime.now().microsecondsSinceEpoch.toString());
    final newUri = originUri.replace(queryParameters: params);
    return newUri;
  }

  Future<void> onUpdateVisitedHistory(
      InAppWebViewController c, Uri url, bool androidIsReload) async {
    currentUrl = url.toString();
    updateCurrentPageConfig();
    update();
  }

  void addJavaScriptHandler(Uri url) {
    JavaScriptRegister(controller: this, env: JavaScriptEnv.mp);
  }

  void onLoadError(
      InAppWebViewController controller, Uri url, int code, String message) {
    logger.severe('mini-program onLoadError：${url.toString()} $code $message');
    loading = false;
    if (code == iosNSURLErrorCancelledCode) {
      isNetworkError = isOtherError = false;
    } else {
      isNetworkError =
          [iosNetworkErrorCode, androidNetworkErrorCode].contains(code);
      isOtherError = !isNetworkError;
    }
    update();
  }

  void onLoadStart(InAppWebViewController c, Uri url) {
    c.addJavaScriptHandler(
        handlerName: 'onDOMContentLoaded',
        callback: (_) {
          onLoadStop(url);
        });
    currentUrl = url.toString();
    c.addJavaScriptHandler(
        handlerName: 'onDOMContentLoaded',
        callback: (_) {
          onLoadStop(url);
        });
  }

  Future<void> onLoadStop(Uri url) async {
    if (!loading) return;
    loading = false;
    if (isNetworkError || isOtherError) return;
    isNetworkError = isOtherError = false;
    updateCurrentPageConfig();
    addJavaScriptHandler(url);
    update();
  }

  // 更新当前路由配置
  void updateCurrentPageConfig() {
    final matchItems = <String>[];
    final pageConfig = _miniProgramConfig(appId)?.pages;
    if (pageConfig == null) return;
    for (final item in pageConfig.entries) {
      final gl = Glob(item.key, caseSensitive: true);
      if (gl.matches(Uri.parse(currentUrl ?? appId).path)) {
        matchItems.add(item.key);
      }
    }
    matchItems.sort((a, b) {
      return a.split('/').length.compareTo(b.split('/').length);
    });
    bool showNavigationBar;
    Color navigationBarBackgroundColor;
    Color navigationBarTextColor;
    String navigationBarTitleText;
    matchItems.forEach((element) {
      final matchConfig = pageConfig[element];
      showNavigationBar = matchConfig.showNavigationBar ?? showNavigationBar;
      navigationBarBackgroundColor = matchConfig.navigationBarBackgroundColor ??
          navigationBarBackgroundColor;
      navigationBarTextColor =
          matchConfig.navigationBarTextColor ?? navigationBarTextColor;
      navigationBarTitleText =
          matchConfig.navigationBarTitleText ?? navigationBarTitleText;
    });
    currentPageConfig = MiniProgramPageConfig(
      showNavigationBar: showNavigationBar,
      navigationBarBackgroundColor: navigationBarBackgroundColor,
      navigationBarTextColor: navigationBarTextColor,
      navigationBarTitleText: navigationBarTitleText,
    );
  }

//  重新加载
  Future<void> reload() async {
    loading = true;
    isNetworkError = isOtherError = false;
    update();
    webViewKey = ValueKey(webViewKey.value + 1);
    initCoreJsFuture();
    update();
  }

//  点击更多按钮
  Future<void> showMore() async {
    await clearFocus();
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
            sizeHeight8,
            SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _menuItem(
                    icon: IconFont.buffWebviewRefresh,
                    desc: '重新进入\n小程序',
                    onPressed: onRestart,
                  ),
                ],
              ),
            ),
            sizeHeight12,
            _cancelButton(),
          ],
        ),
      ),
    );
  }

//取消按钮
  Widget _cancelButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: popRoute,
      child: ColoredBox(
        color: Theme.of(Get.context).backgroundColor,
        child: Column(
          children: [
            Container(
              height: 60,
              alignment: Alignment.center,
              child: Text('取消'.tr,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(Get.context).textTheme.bodyText2.color,
                  )),
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
    return Row(
      children: [
        GestureDetector(
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
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Color(0xFF646A73)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  // 重启小程序
  Future<void> onRestart() async {
    Get.until((route) => (route.settings.name ?? '')
        .startsWith(get_routes.Routes.MINI_PROGRAM_PAGE));
    // 关掉小程序再重新push
    Get.back();
    Future.delayed(const Duration(milliseconds: 800), () {
      Routes.pushMiniProgram(appId);
    });
  }

  Future<void> goBack(bool canWebViewBack) async {
    if (canWebViewBack) {
      unawaited(webViewController.goBack());
    } else {
      unawaited(popRoute());
    }
  }

  Future<void> popRoute() async {
    if (OrientationUtil.landscape) {
      unawaited(SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]));
      await Future.delayed(kThemeAnimationDuration);
    }
    Get.back();
  }

  Future<bool> onAndroidWillPop() async {
    try {
      final canWebViewBack = await webViewController.canGoBack();
      await goBack(canWebViewBack);
      return Future.value(!canWebViewBack);
    } catch (e) {
      return Future.value(true);
    }
  }

  // ignore: use_setters_to_change_properties
  void onWebViewCreated(InAppWebViewController controller) {
    webViewController = controller;
  }

  void onTitleChanged(InAppWebViewController controller, String t) {
    title = t;
    update();
  }

  Future<NavigationActionPolicy> shouldOverrideUrlLoading(
      InAppWebViewController c, NavigationAction u) {
    final res =
        overrideUrlLoadingHandler(c, u, referer, LinkHandlerPreset.miniProgram);
    referer = u.request.url.toString();
    return res;
  }

  Map<String, String> get requestHeaders => null;

  // 隐藏键盘
  Future<void> clearFocus() async {
    if (UniversalPlatform.isIOS)
      await webViewController?.clearFocus();
    else if (UniversalPlatform.isAndroid)
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  Future<IOSNavigationResponseAction> iosOnNavigationResponse(
      InAppWebViewController controller,
      IOSWKNavigationResponse navigationResponse) async {
    return Future.value(IOSNavigationResponseAction.ALLOW);
  }

  void showSnackBar() {
    snackBarOffset = const Offset(0, 2.5);
    snackBarOpacity = 1;
    update([updateIdSnackBar]);
  }

  void hideSnackBar() {
    snackBarOffset = const Offset(0, -1);
    snackBarOpacity = 0;
    update([updateIdSnackBar]);
  }

  Future<String> showInput({Color color}) async {
    inputVisible = true;
    resizeToAvoidBottomInset = false;
    inputColor = color ?? inputColor;
    update();
    inputFocus.requestFocus();
    inputComplete = Completer<String>();
    return inputComplete.future;
  }

  void hideInput() {
    inputVisible = false;
    update();
    inputFocus.unfocus();
  }

  void onSend(String text) {
    inputFocus.unfocus();
    update();
    inputComplete.complete(text);
    inputController.clear();
    Future.delayed(const Duration(milliseconds: 300), () {
      inputVisible = false;
    });
  }
}
