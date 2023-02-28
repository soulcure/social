import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im/core/back_to_desktop.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/home_page.dart';
import 'package:im/routes.dart';
import 'package:im/services/sp_service.dart';

// import 'package:im/utils/track_route.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/dialog/update_dialog.dart';
import 'package:pedantic/pedantic.dart';
import 'package:uni_links/uni_links.dart';

import 'deep_link/external_share_processor.dart';
import 'deep_link/oauth_processor.dart';

typedef FinishCallback = void Function(int code);

/// 处理app内所有的deep link
class DeepLinkProcessor {
  DeepLinkProcessor._();

  /// 是否已处理过冷启动的deep link
  var _hasProcessColdStart = false;

  /// 是否是移动设备，deep link在非移动设备上不可用
  bool isMobileDevice = UniversalPlatform.isAndroid || UniversalPlatform.isIOS;

  static final DeepLinkProcessor instance = DeepLinkProcessor._();

  /// 要处理的deep link列表
  final List<DeepLinkMatcher> _matchers = [
    // 处理oauth的deep link
    OAuthDeepLinkMatcher(),
    ExternalShareDeepLinkMatcher(),
  ];

  /// 待处理的deep link任务，例如需要先登录再跳转的deep link, 在登录后需要重新处理该任务
  Set<DeepLinkTask> _waitingTasks;

  /// app处于后台时，监听是否有deep link请求
  StreamSubscription _sub;

  /// 在组件的initState中调用
  void registerDeepLinkProcessor() {
    /// 非移动端设备不支持deep link库
    if (!isMobileDevice) return;

    _sub = uriLinkStream.listen(_redirect);
  }

  /// 先处理冷启动的任务，如果处理失败则处理等待中的任务
  Future<bool> process() async {
    return await _processColdStart() || await _processWaitingTasks();
  }

  /// 处理冷启动时的deep link，如果有匹配的deep link则返回true，否则返回false
  Future<bool> _processColdStart() async {
    /// 非移动端设备不支持deep link库
    if (!isMobileDevice) return false;

    if (_hasProcessColdStart) {
      // 已处理过冷启动传入的deep link
      return false;
    }
    _hasProcessColdStart = true;

    Uri deepLink;
    try {
      /// 冷启动时获取deep link，如果为空，则表示app是用户正常打开，而不是通过deep link启动
      deepLink = await getInitialUri();

      /// 返回是否能够处理冷启动传入的deep link
      return _redirect(deepLink);
    } on PlatformException {
      print(
          "Failed to get deep link: $deepLink on ${Platform.operatingSystem}");
    } on FormatException {
      print("Invalid deep link: $deepLink");
    }
    return false;
  }

  /// 处理等待中的任务
  Future<bool> _processWaitingTasks() async {
    /// 非移动端设备不支持deep link库
    if (!isMobileDevice) return false;

    /// 没有待处理的任务
    if (_waitingTasks == null || _waitingTasks.isEmpty) return false;

    /// 记录等待队列中是否有成功执行的任务
    bool hasExecute = false;
    _waitingTasks.removeWhere((task) {
      if (task.isNeedToWaite()) {
        // 任务需要等待，不能执行
        return false;
      }
      // 任务可以执行
      hasExecute = true;
      task.run();
      // 从等待队列中移除该任务
      return true;
    });
    return hasExecute;
  }

  /// 处理deepLink的页面跳转
  /// @param deepLink:
  /// @return: 是否成功跳转
  Future<bool> _redirect(Uri deepLink) async {
    if (deepLink == null) return false;

    DeepLinkTask task;
    // 扫描配置的deep link列表，找到能处理deepLink的DeepLinkMatcher
    for (final matcher in _matchers) {
      if (!matcher.isMatch(deepLink)) {
        // 没有匹配，继续查找
        continue;
      }
      // 匹配成功，不继续匹配
      task = matcher.createTask(deepLink);
      if (task.isNeedToWaite()) {
        // 将任务加入等待队列中等待后续处理
        _waitingTasks ??= HashSet();
        // 已有任务没机会执行的,直接删除

        final exists = _waitingTasks
            .where((element) =>
                element.deepLink.scheme == task.deepLink.scheme &&
                element.deepLink.host == task.deepLink.host)
            .toList();
        exists.forEach((e) {
          _waitingTasks.remove(e);
        });

        _waitingTasks.add(task);
        return false;
      }
      // 跳转到deep link对应的页面
      unawaited(task.run());
      return true;
    }
    return false;
  }

  /// 在组件dispose时调用
  void dispose() {
    _sub?.cancel();
  }
}

/// 负责匹配要处理的deep link
abstract class DeepLinkMatcher {
  /// 匹配待处理的deep link，格式：scheme://host/path
  final String matchedLink;

  DeepLinkMatcher(this.matchedLink);

  /// 判断是否要处理改deep link
  bool isMatch(Uri deepLink) {
    final link = Uri.parse(matchedLink);
    return deepLink.scheme == link.scheme &&
        deepLink.host == link.host &&
        deepLink.path == link.path;
  }

  DeepLinkTask createTask(Uri deepLink);
}

/// 封装Deep link的处理流程
abstract class DeepLinkTask {
  /// 要处理的deep link
  final Uri deepLink;

  /// 开始执行任务时的页面，通常在deep link处理完后要回到此页面
  // String _startPage;

  DeepLinkTask(this.deepLink) {
    // _startPage = PageRouterObserver.instance.topPage;
  }

  /// 判断当前任务是否需要等待执行，由子类实现
  bool isNeedToWaite();

  /// 任务要执行的操作，返回错误码，由子类来实现
  Future run();

  /// 返回到唤起Fanbook的三方应用
  Future backToThirdPart(String url, {bool shouldBack = true}) async {
    try {
      // 跳转到处理授权结果页面，ios如果用canLaunchUrl来检测，则必须在工程中配置scheme白名单，
      // 因为这里要跳转的scheme是动态传入的，所以无法在工程中配置，因此isCheck传false来跳过检查
      await launchURL(url, isCheck: false);
      // 跳转到后台
      unawaited(backToDeskTop());
      // 回到任务开始执行的页面
      if (shouldBack) {
        back();
      }
    } catch (e, s) {
      print("DeepLinkTask cannot launch: $url, $e\n$s");
    }
  }

  /// 回到任务开始执行时的页面
  /// isSuccess 是否为成功分享之后的返回（此种情况需要跳转到相应的UI）
  void back({bool isSuccess = false, FinishCallback finishCallback}) {
    if (!Routes.hasHomePage) {
      /// 未加载过主页面，跳转到主页面
      Routes.popAndPushHomePage(Global.navigatorKey.currentContext);
      HomePage.ready.then((_) {
        if (finishCallback != null) {
          finishCallback(1);
        }
      });
      return;
    }

    Routes.backHome();

    // 分享成功情况下，需要跳转到相应的UI，此时直接回到首页
    // 失败情况下，回到调用起来的页面。
    // if (isSuccess) {
    //   Routes.backHome();
    // } else {
    //   if (_startPage == null ||
    //       !PageRouterObserver.instance.hasPage(_startPage)) {
    //     /// 任务开始执行时的页面被销毁，回退到主页面
    //     Routes.backHome();
    //   }
    //
    //   /// 回到任务开始执行时的页面
    //   Navigator.of(Global.navigatorKey.currentContext).popUntil(
    //     (route) => route.settings.name == _startPage,
    //   );
    // }

    if (finishCallback != null) {
      finishCallback(2);
    }
  }
}

/// 处理deep link中的路由跳转操作
abstract class DeepLinkCommand<T> {
  /// 用于获取页面内操作的结果
  final AsyncDeepLinkTaskNotifier<T> notifier = AsyncDeepLinkTaskNotifier();

  final commandName = "deeplinkCommandPage";

  /// 构建要跳转的页面
  /// params提供页面构造方法需要的参数
  // Widget build();

  /// NOTE: 2021/12/16
  /// replace == false: 已加载过主页，deep link唤起的页面在主页面之上
  /// replace == ture: 未加载主页面(通常情况下意味着冷启动期间执行)，回退栈里应该只有deep link唤起的页面
  bool get replace => !Routes.hasHomePage;

  /// 唤起deep link对应的页面，并返回用户操作结果
  @protected
  Future<DeepLinkCommandResult<T>> gotoPageForResult();

  // {
  // final page = build();
  // // final pageRoute = MaterialPageRoute(
  // //   builder: (_) => page,
  // // );
  // if (Routes.hasHomePage) {
  //   /// 已加载过主页，deep link唤起的页面在主页面之上
  //   // Navigator.push(Global.navigatorKey.currentContext, pageRoute);
  //   Routes.push(
  //       Global.navigatorKey.currentContext, page, "deeplinkCommandPage");
  // } else {
  //   /// 未加载主页面(通常情况下意味着冷启动期间执行)，回退栈里应该只有deep link唤起的页面
  //   // Navigator.pushReplacement(Global.navigatorKey.currentContext, pageRoute);
  //   Routes.push(
  //       Global.navigatorKey.currentContext, page, "deeplinkCommandPage",
  //       replace: true);
  // }

  //   return notifier.result;
  // }

  /// 执行页面跳转并返回操作结果
  Future<DeepLinkCommandResult<T>> execute() {
    return gotoPageForResult();
  }
}

/// 当处理deep link的过程中需要在其他类中执行某些操作，通过DeepLinkTaskNotifier
/// 将结果传回给DeepLinkTask（通过观察者模式实现）
abstract class DeepLinkTaskNotifier<T> {
  const DeepLinkTaskNotifier();

  void onSuccess({T result});

  void onError(int errCode);
}

class DeepLinkCommandResult<T> {
  final int errCode;
  final T result;

  DeepLinkCommandResult(this.errCode, {this.result});

  bool get isSuccess => errCode == DeepLinkTaskErrCode.SUCCESS;
}

/// 通常传入给页面使用，将callback的方式转换成async的方式，方便使用
class AsyncDeepLinkTaskNotifier<T> extends DeepLinkTaskNotifier<T> {
  final _completer = Completer<DeepLinkCommandResult<T>>();

  @override
  void onSuccess({T result}) {
    if (!_completer.isCompleted) {
      _completer.complete(
        DeepLinkCommandResult(DeepLinkTaskErrCode.SUCCESS, result: result),
      );
    }
  }

  @override
  void onError(int errCode) {
    if (!_completer.isCompleted) {
      _completer.complete(DeepLinkCommandResult(errCode));
    }
  }

  /// 将回调通知的结果转换成Future
  Future<DeepLinkCommandResult<T>> get result => _completer.future;

  void notify(int errCode, T result) {
    _completer.complete(DeepLinkCommandResult(errCode, result: result));
  }
}

/// 判断当前是否处于登录状态
bool get isLogin =>
    SpService.to.getInt(SP.loginTime) != null &&
    Global.user.id != null &&
    DateTime.now().isBefore(
        DateTime.fromMillisecondsSinceEpoch(SpService.to.getInt(SP.loginTime))
            .add(const Duration(days: 30)));

/// 处理deep link涉及的错误码
class DeepLinkTaskErrCode {
  /// 任务执行成功
  static const int SUCCESS = 0;

  /// 普通错误，一般出现在代码发生未知异常
  static const int NORMAL = -1;

  /// 授权取消
  static const int AUTH_CANCEL = -2;

  /// 授权请求发送失败
  static const int AUTH_REQ_FAILED = -3;

  /// 授权失败，一般出现在传入非法的client id
  static const int AUTH_FAILED = -4;

  /// 无效的邀请码
  static const int INVALID_INVITE_CODE = -5;

  /// 邀请码过期
  static const int INVITE_CODE_EXPIRED = -6;

  /// 邀请取消
  static const int INVITE_CANCEL = -7;

  /// 已加入过服务器，邀请失败
  static const int INVITE_HAS_JOINED = -8;

  /// 分享取消
  static const int SHARE_CANCEL = 2;

  /// 分享失败
  static const int SHARE_FAILED = -9;

  /// 分享传入的邀请码对应的服务器与要分享到的服务器不一致
  static const int SHARE_WRONG_GUILD_ID = -10;

  /// 不支持的分享类型
  static const int SHARE_UNSUPPORTED_TYPE = -11;

  /// 退到后台时取消分享
  static const int SHARE_BACK = -12;
}
