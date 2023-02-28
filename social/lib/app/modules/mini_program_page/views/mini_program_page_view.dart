import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:im/global.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/button/custom_icon_button.dart';
import 'package:im/widgets/default_tip_widget.dart';

import '../../../../icon_font.dart';
import '../../../../utils/universal_platform.dart';
import '../controllers/mini_program_page_controller.dart';

const double _horizontalPadding = 8;
const double navigationBarHeight = 44;
const Color _navButtonLightColor = Colors.white;
const Color _navButtonLightTapColor = Colors.black45;
Color _navButtonDarkColor = Colors.black.withOpacity(0.2);
const Color _navButtonDarkTapColor = Colors.black38;

class MiniProgramPageView<T extends MiniProgramPageController>
    extends GetView<T> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<T>(
      builder: (c) {
        final firstChild = _buildLoadingWidget(context);
        final secondChild = _buildPageContent(c);
        final _webContentWidget = WillPopScope(
          onWillPop: Platform.isIOS ? null : c.onAndroidWillPop,
          // OrientationBuilder 是为了横竖屏切换时更新 UI
          child: OrientationBuilder(builder: (context, orientation) {
            return Stack(
              fit: StackFit.expand,
              children: [
                secondChild,
                Visibility(visible: !c.shouldShowWebview, child: firstChild),
                GetBuilder<T>(
                    id: MiniProgramPageController.updateIdSnackBar,
                    builder: (_) {
                      return AnimatedSlide(
                        offset: controller.snackBarOffset,
                        duration: 300.milliseconds,
                        curve: Curves.easeInOutCirc,
                        child: AnimatedOpacity(
                          duration: 300.milliseconds,
                          opacity: controller.snackBarOpacity,
                          curve: Curves.easeInOutCirc,
                          child: buildSnackBar(),
                        ),
                      );
                    }),
                GetBuilder<T>(builder: (c) {
                  if (!c.inputVisible) return sizedBox;
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: EdgeInsets.only(
                          left: 12,
                          bottom: MediaQuery.of(context).viewInsets.bottom),
                      color: c.inputColor,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                isDense: true,
                                fillColor: Colors.white,
                                filled: true,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 8),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              controller: controller.inputController,
                              focusNode: controller.inputFocus,
                              onSubmitted: controller.onSend,
                            ),
                          ),
                          TextButton(
                              onPressed: () => controller
                                  .onSend(controller.inputController.text),
                              child: const Text(
                                '发送',
                                style: TextStyle(color: Colors.white),
                              ))
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        );
        return UniversalPlatform.isIOS
            ? Material(color: Colors.white, child: _webContentWidget)
            : Scaffold(
                backgroundColor: Colors.white,
                body: _webContentWidget,
                resizeToAvoidBottomInset: controller.resizeToAvoidBottomInset,
              );
      },
    );
  }

  Widget buildWebView(T c) {
    return FutureBuilder<String>(
        future: c.coreJsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError || !snapshot.hasData) return const SizedBox();
          if (controller.isNetworkError || controller.isOtherError)
            return const SizedBox();
          return AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: c.showNavigationBar
                ? Get.mediaQuery.viewPadding.top + navigationBarHeight
                : 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: InAppWebView(
              key: ValueKey(controller.webViewKey),
              initialUrlRequest: URLRequest(
                url: c.getRequestUri(),
                headers: c.requestHeaders,
              ),
              initialOptions: InAppWebViewGroupOptions(
                crossPlatform: InAppWebViewOptions(
                  useShouldOverrideUrlLoading: true,
                  applicationNameForUserAgent:
                      '${UniversalPlatform.isMobileDevice ? "Mobile" : "PC"} FBMP/${Global.packageInfo.version}+${Global.packageInfo.buildNumber}',
                  useOnDownloadStart: true,
                ),
                android: AndroidInAppWebViewOptions(
                  mixedContentMode:
                      AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,

                  ///这个属性用于避免部分Android手机使用webview时，输入密码会导致黑屏的问题
                  ///参见这个issue:https://github.com/pichillilorenzo/flutter_inappwebview/issues/536
                  useHybridComposition: true,
                ),
                ios: IOSInAppWebViewOptions(
                    allowsInlineMediaPlayback: true,
                    useOnNavigationResponse: true),
              ),
              initialUserScripts: UnmodifiableListView<UserScript>([
                UserScript(
                    source: snapshot.data,
                    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START),
              ]),
              shouldOverrideUrlLoading: controller.shouldOverrideUrlLoading,
              onUpdateVisitedHistory: Get.find<T>().onUpdateVisitedHistory,
              onWebViewCreated: controller.onWebViewCreated,
              onTitleChanged: controller.onTitleChanged,
              onLoadStart: controller.onLoadStart,
              onLoadError: controller.onLoadError,
              iosOnNavigationResponse: controller.iosOnNavigationResponse,
              onLoadStop: (wc, url) => controller.onLoadStop(url),
              // 忽略 SSL 证书验证错误，否则有些网站可能打不开，例如 https://api.battleofballs.com/authorized
              onReceivedServerTrustAuthRequest: (_, challenge) => Future.value(
                  ServerTrustAuthResponse(
                      action: ServerTrustAuthResponseAction.PROCEED)),
              onConsoleMessage: (c, consoleMessage) {
                debugPrint(
                    'miniprogram onConsoleMessage ${consoleMessage.message}');
              },
            ),
          );
        });
  }

  Widget _buildLoadingWidget(BuildContext context) {
    Widget child;
    if (controller.loading) {
      child = _buildProgressIndicator();
    } else if (controller.isNetworkError || controller.isOtherError) {
      child = buildError(context);
    } else {
      child = const SizedBox();
    }
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: Stack(
        children: [
          Positioned(
            top: Get.mediaQuery.viewPadding.top,
            right: _horizontalPadding,
            child: buildNavButtons(),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildPageContent(T c) {
    return Stack(
      children: [
        buildWebView(c),
        buildNavigationBar(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Center(
      child: Stack(
        children: [
          const SizedBox(
            width: 65,
            height: 65,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Image.asset(
                "assets/app-icon/icon_round.png",
                width: 50,
                height: 50,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildNavigationBar() {
    Widget child;
    final appBarHeight = navigationBarHeight + Get.mediaQuery.viewPadding.top;
    final shouldShowBackButton = controller.showNavigationBar &&
        !controller.hasError &&
        !controller.loading;
    if (shouldShowBackButton) {
      child = SizedBox(
        height: appBarHeight,
        child: CustomAppbar(
          leadWidth: 30,
          backgroundColor: controller.appBarBackgroundColor,
          leadingBuilder: (icon) {
            return Padding(
              padding: const EdgeInsets.only(left: 12),
              child: CustomIconButton(
                size: 22,
                padding: const EdgeInsets.only(right: 8),
                iconData: IconFont.buffNavBarBackItem,
                iconColor: controller.navigationBarTextColor,
                onPressed: controller.onAndroidWillPop,
              ),
            );
          },
          titleBuilder: (style) {
            return Text(
              controller.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.normal,
                color: controller.navigationBarTextColor,
              ),
            );
          },
          actions: [
            AppbarCustomButton(
                child: Padding(
              padding: const EdgeInsets.only(right: _horizontalPadding),
              child: buildNavButtons(),
            )),
          ],
        ),
      );
    } else {
      child = Positioned(
        top: Get.mediaQuery.viewPadding.top,
        right: _horizontalPadding,
        child: buildNavButtons(),
      );
    }
    return child;
  }

  Widget buildNavButtons() {
    final backgroundColor =
        controller.isLightMode ? _navButtonLightColor : _navButtonDarkColor;
    final border = Border.all(
        width: 0.5,
        color: CustomColor(Get.context).disableColor.withOpacity(0.2));
    return SizedBox(
      height: navigationBarHeight,
      child: UnconstrainedBox(
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            border: border,
          ),
          child: Row(
            children: [
              _navButtonItem(
                icon: IconFont.buffMoreHorizontal,
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                ),
                onPressed: controller.showMore,
              ),
              SizedBox(
                width: 1,
                height: 12,
                child: VerticalDivider(
                  color: CustomColor(Get.context).disableColor.withOpacity(0.3),
                ),
              ),
              _navButtonItem(
                icon: IconFont.buffNavBarCloseItem,
                iconSize: 20,
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                ),
                onPressed: controller.popRoute,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navButtonItem({
    @required IconData icon,
    @required MaterialStateProperty<RoundedRectangleBorder> shape,
    @required GestureTapCallback onPressed,
    double iconSize = 22,
  }) {
    final tapColor = controller.isLightMode
        ? _navButtonLightTapColor
        : _navButtonDarkTapColor;

    final iconColor = controller.isLightMode
        ? Theme.of(Get.context).textTheme.bodyText2.color
        : Colors.white;

    return SizedBox(
      width: 40,
      height: 30,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
              const EdgeInsets.all(0)),
          shape: shape,
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.pressed)) return tapColor;
            return Colors.transparent;
          }),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );
  }

  Widget buildError(BuildContext context) {
    final isNetworkError = Get.find<T>().isNetworkError;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DefaultTipWidget(
            icon: IconFont.buffCommonWifi,
            text: isNetworkError ? '网络异常，请重试'.tr : '加载失败，请重试'.tr,
          ),
          sizeHeight32,
          buildReloadButton(context)
        ],
      ),
    );
  }

  Widget buildReloadButton(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        backgroundColor: CustomColor(context).globalBackgroundColor3,
        shape: const StadiumBorder(),
      ),
      onPressed: Get.find<T>().reload,
      child: Text(
        '重新加载'.tr,
        style: TextStyle(fontSize: 14, color: Theme.of(context).primaryColor),
      ),
    );
  }

  Widget buildSnackBar() {
    return const SizedBox();
  }
}
