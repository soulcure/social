import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

///
/// 极光认证兼容web的文件。这个文件全为空实现
///
class Jverify {
  factory Jverify() => _instance;
  static final _instance = Jverify.private();
  static String notSupport = "JVerify not support web platform";

  Jverify.private();

  void dismissLoginAuthView() => throw MissingPluginException(notSupport);

  void showNativeToast(String content) =>
      throw MissingPluginException(notSupport);

  void addClikWidgetEventListener(
          String eventId, JVClickWidgetEventListener callback) =>
      throw MissingPluginException(notSupport);

  void setCustomAuthorizationView(bool isAutorotate, JVUIConfig portraitConfig,
          {JVUIConfig landscapeConfig, List<JVCustomWidget> widgets}) =>
      throw MissingPluginException(notSupport);

  Future<Map<dynamic, dynamic>> preLogin({int timeOut = 10000}) async =>
      throw MissingPluginException(notSupport);

  Future<Map<dynamic, dynamic>> checkVerifyEnable() async =>
      throw MissingPluginException(notSupport);

  // ignore: type_annotate_public_apis, always_declare_return_types
  addAuthPageEventListener(JVAuthPageEventListener callback) =>
      throw MissingPluginException(notSupport);

  // ignore: type_annotate_public_apis, always_declare_return_types
  addLoginAuthCallBackListener(JVLoginAuthCallBackListener callback) =>
      throw MissingPluginException(notSupport);

  // ignore: type_annotate_public_apis, always_declare_return_types
  addSDKSetupCallBackListener(JVSDKSetupCallBackListener callback) =>
      throw MissingPluginException(notSupport);

  void loginAuthSyncApi({@required bool autoDismiss, int timeout = 10000}) =>
      throw MissingPluginException(notSupport);

  void setDebugMode(bool debug) => throw MissingPluginException(notSupport);

  void setup(
          {@required String appKey,
          String channel,
          bool useIDFA,
          int timeout = 10000,
          bool setControlWifiSwitch = true}) =>
      throw MissingPluginException(notSupport);
}

enum JVCustomWidgetType { textView, button }
enum JVTextAlignmentType { left, right, center }
enum JVIOSLayoutItem {
  ItemNone,
  ItemLogo,
  ItemNumber,
  ItemSlogan,
  ItemLogin,
  ItemCheck,
  ItemPrivacy,
  ItemSuper
}
enum JVIOSUIModalTransitionStyle {
  CoverVertical,
  FlipHorizontal,
  CrossDissolve,
  PartialCurl
}
enum JVIOSBarStyle {
  StatusBarStyleDefault, // Automatically chooses light or dark content based on the user interface style
  StatusBarStyleLightContent, // Light content, for use on dark backgrounds iOS 7 以上
  StatusBarStyleDarkContent // Dark content, for use on light backgrounds  iOS 13 以上
}

class JVCustomWidget {
  String widgetId;
  JVCustomWidgetType type;

  JVCustomWidget(this.widgetId, this.type);

  int left = 0; // 屏幕左边缘开始计算
  int top = 0; // 导航栏底部开始计算
  int width = 0;
  int height = 0;
  String title = "";
  double titleFont = 0;
  int titleColor = 0;
  int backgroundColor;
  String btnNormalImageName;
  String btnPressedImageName;
  JVTextAlignmentType textAlignment;
  int lines = 1;
  bool isSingleLine = true;
  bool isShowUnderline = false;
  bool isClickEnable;

  Map toJsonMap() => {};
}

typedef JVLoginAuthCallBackListener = void Function(JVListenerEvent event);
typedef JVClickWidgetEventListener = void Function(String widgetId);
typedef JVAuthPageEventListener = void Function(JVAuthPageEvent event);
typedef JVSDKSetupCallBackListener = void Function(JVSDKSetupEvent event);

class JVUIConfig {
  /// 授权页背景图片
  String authBackgroundImage;
  String authBGGifPath; // 授权界面gif图片 only android

  /// 导航栏
  int navColor;
  String navText;
  int navTextColor;
  String navReturnImgPath;
  bool navHidden = false;
  bool navReturnBtnHidden = false;
  bool navTransparent = false;

  /// logo
  int logoWidth;
  int logoHeight;
  int logoOffsetX;
  int logoOffsetY;
  JVIOSLayoutItem logoVerticalLayoutItem;
  bool logoHidden;
  String logoImgPath;

  /// 号码
  int numberColor;
  int numberSize;
  int numFieldOffsetX;
  int numFieldOffsetY;
  int numberFieldWidth;
  int numberFieldHeight;
  JVIOSLayoutItem numberVerticalLayoutItem;

  /// slogan
  int sloganOffsetX;
  int sloganOffsetY;
  JVIOSLayoutItem sloganVerticalLayoutItem;
  int sloganTextColor;
  int sloganTextSize;
  int sloganWidth;
  int sloganHeight;

  bool sloganHidden = false;

  /// 登录按钮
  int logBtnOffsetX;
  int logBtnOffsetY;
  int logBtnWidth;
  int logBtnHeight;
  JVIOSLayoutItem logBtnVerticalLayoutItem;
  String logBtnText;
  int logBtnTextSize;
  int logBtnTextColor;
  String logBtnBackgroundPath;
  String loginBtnNormalImage; // only ios
  String loginBtnPressedImage; // only ios
  String loginBtnUnableImage; // only ios

  /// 隐私协议栏
  String uncheckedImgPath;
  String checkedImgPath;
  int privacyCheckboxSize;
  bool privacyHintToast = true; //设置隐私条款不选中时点击登录按钮默认弹出toast。
  bool privacyState = false; //设置隐私条款默认选中状态，默认不选中
  bool privacyCheckboxHidden = false; //设置隐私条款checkbox是否隐藏
  bool privacyCheckboxInCenter = false; //设置隐私条款checkbox是否相对协议文字纵向居中

  int privacyOffsetY; // 隐私条款相对于授权页面底部下边缘 y 偏移
  int privacyOffsetX; // 隐私条款相对于屏幕左边 x 轴偏移
  JVIOSLayoutItem privacyVerticalLayoutItem = JVIOSLayoutItem.ItemSuper;
  String clauseName; // 协议1 名字
  String clauseUrl; // 协议1 URL
  String clauseNameTwo; // 协议2 名字
  String clauseUrlTwo; // 协议2 URL
  int clauseBaseColor;
  int clauseColor;
  List<String> privacyText;
  int privacyTextSize;
  List<JVPrivacy> privacyItem;
  bool privacyWithBookTitleMark = true; //设置隐私条款运营商协议名是否加书名号
  bool privacyTextCenterGravity = false; //隐私条款文字是否居中对齐（默认左对齐）

  /// 隐私协议 web 页 UI 配置
  int privacyNavColor; // 导航栏颜色
  int privacyNavTitleTextColor; // 标题颜色
  int privacyNavTitleTextSize; // 标题大小
  String privacyNavTitleTitle; //协议0 web页面导航栏标题 only ios
  String privacyNavTitleTitle1; // 协议1 web页面导航栏标题
  String privacyNavTitleTitle2; // 协议2 web页面导航栏标题
  String privacyNavReturnBtnImage;
  JVIOSBarStyle privacyStatusBarStyle; //隐私协议web页 状态栏样式设置 only iOS

  ///隐私页
  bool privacyStatusBarColorWithNav = false; //隐私页web状态栏是否与导航栏同色 only android
  bool privacyStatusBarDarkMode = false; //隐私页web状态栏是否暗色 only android
  bool privacyStatusBarTransparent = false; //隐私页web页状态栏是否透明 only android
  bool privacyStatusBarHidden = false; //隐私页web页状态栏是否隐藏 only android
  bool privacyVirtualButtonTransparent = false; //隐私页web页虚拟按键背景是否透明 only android

  ///授权页
  bool statusBarColorWithNav = false; //授权页状态栏是否跟导航栏同色 only android
  bool statusBarDarkMode = false; //授权页状态栏是否为暗色 only android
  bool statusBarTransparent = false; //授权页栏状态栏是否透明 only android
  bool statusBarHidden = false; //授权页状态栏是否隐藏 only android
  bool virtualButtonTransparent = false; //授权页虚拟按键背景是否透明 only android

  JVIOSBarStyle authStatusBarStyle =
      JVIOSBarStyle.StatusBarStyleDefault; //授权页状态栏样式设置 only iOS

  ///是否需要动画
  bool needStartAnim = false; //设置拉起授权页时是否需要显示默认动画
  bool needCloseAnim = false; //设置关闭授权页时是否需要显示默认动画
  String enterAnim; // 拉起授权页时进入动画 only android
  String exitAnim; // 退出授权页时动画 only android

  /// 授权页弹窗模式 配置，选填
  JVPopViewConfig popViewConfig;

  JVIOSUIModalTransitionStyle modelTransitionStyle = //弹出方式 only ios
      JVIOSUIModalTransitionStyle.CoverVertical;

  Map toJsonMap() => {};
}

class JVPopViewConfig {
  int width;
  int height;
  int offsetCenterX = 0; // 窗口相对屏幕中心的x轴偏移量
  int offsetCenterY = 0; // 窗口相对屏幕中心的y轴偏移量
  bool isBottom = false; // only Android，窗口是否居屏幕底部。设置后 offsetCenterY 将失效，
  double popViewCornerRadius = 0;
  double backgroundAlpha = 0;
  bool isPopViewTheme; // 是否支持弹窗模式
  Map toJsonMap() => {};
}

class JVListenerEvent {
  int code;
  String message;
  String operator;
}

class JVAuthPageEvent extends JVListenerEvent {
  Map toMap() => {};
}

class JVSDKSetupEvent extends JVAuthPageEvent {}

class JVPrivacy {
  String name;
  String url;
  String beforeName;
  String afterName;
  String separator; //ios分隔符专属

  JVPrivacy(this.name, this.url,
      {this.beforeName, this.afterName, this.separator});

  Map toMap() {
    return {
      'name': name,
      'url': url,
      'beforeName': beforeName,
      'afterName': afterName,
      'separator': separator
    };
  }

  Map toJson() {
    final map = {};
    map["name"] = name;
    map["url"] = url;
    map["beforeName"] = beforeName;
    map["afterName"] = afterName;
    map["separator"] = separator;
    return map..removeWhere((key, value) => value == null);
  }
}
