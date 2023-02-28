import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/mini_program_page/controllers/mini_program_page_controller.dart';
import 'package:im/app/modules/mini_program_page/entity/mini_program_config.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/config.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/view/check_permission.dart';
import 'package:im/routes.dart';
import 'package:im/utils/cos_file_upload.dart';
import 'package:im/utils/disk_util.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/track_route.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:image_save/image_save.dart';
import 'package:oktoast/oktoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pedantic/pedantic.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../global.dart';
import 'class.dart';

enum JavaScriptEnv {
  // 小程序
  mp,
  // web
  web,
  // 腾讯文档
  tc_doc,
}

class JavaScriptRegister {
  final MiniProgramPageController controller;
  final String guildId;
  final String fileId;
  final JavaScriptEnv env;

  JavaScriptRegister({
    @required this.controller,
    @required this.env,
    this.guildId,
    this.fileId,
  }) {
    list.forEach((element) {
      if (element.envs.contains(env))
        controller.webViewController.addJavaScriptHandler(
            handlerName: element.key,
            callback: (params) => element.func?.call(params, controller));
    });
  }

  static List<JavaScriptHandler> list = [
    JavaScriptHandler.getCurrentGuild,
    JavaScriptHandler.getCurrentChannel,
    JavaScriptHandler.getSystemInfo,
    JavaScriptHandler.getUserToken,
    JavaScriptHandler.setClipboardData,
    JavaScriptHandler.getClipboardData,
    JavaScriptHandler.getUserInfo,
    JavaScriptHandler.uploadFile,
    JavaScriptHandler.oAuth,
    JavaScriptHandler.nativeAuth,
    JavaScriptHandler.closeWindow,
    JavaScriptHandler.getAppVersion,
    JavaScriptHandler.showShareDialog,
    JavaScriptHandler.isFromDmChannel,
    JavaScriptHandler.getDmChannel,
    JavaScriptHandler.sendMessage,
    JavaScriptHandler.saveImage,
    JavaScriptHandler.showInput,
    JavaScriptHandler.hideInput,
    JavaScriptHandler.setOrientation,
  ];
}

class JavaScriptHandler {
  final String key;
  Function func;
  final List<JavaScriptEnv> envs;

  JavaScriptHandler._(
    this.key,
    this.func,
    this.envs,
  );

  static JavaScriptHandler getCurrentGuild = JavaScriptHandler._(
      'getCurrentGuild', getCurrentGuildFunc, [JavaScriptEnv.mp]);

  static JavaScriptHandler getCurrentChannel = JavaScriptHandler._(
      'getCurrentChannel', getCurrentChannelFunc, [JavaScriptEnv.mp]);

  static JavaScriptHandler getSystemInfo = JavaScriptHandler._(
      'getSystemInfo', getSystemInfoFunc, [JavaScriptEnv.mp]);

  static JavaScriptHandler getUserToken =
      JavaScriptHandler._('getUserToken', getUserTokenFunc, [JavaScriptEnv.mp]);

  static JavaScriptHandler setClipboardData = JavaScriptHandler._(
      'setClipboardData', setClipboardDataFunc, [JavaScriptEnv.mp]);

  static JavaScriptHandler getClipboardData = JavaScriptHandler._(
      'getClipboardData', getClipboardDataFunc, [JavaScriptEnv.mp]);

  static JavaScriptHandler getUserInfo =
      JavaScriptHandler._('getUserInfo', getUserInfoFunc, [JavaScriptEnv.mp]);

  static JavaScriptHandler uploadFile =
      JavaScriptHandler._('uploadFile', uploadFileFunc, [JavaScriptEnv.mp]);

  static JavaScriptHandler oAuth =
      JavaScriptHandler._('oAuth', oAuthFunc, [JavaScriptEnv.mp]);

  static JavaScriptHandler nativeAuth =
      JavaScriptHandler._('nativeAuth', oAuthFunc, [JavaScriptEnv.mp]);

  static JavaScriptHandler closeWindow =
      JavaScriptHandler._('closeWindow', closeWindowFunc, [JavaScriptEnv.mp]);

  static JavaScriptHandler getAppVersion = JavaScriptHandler._(
      'getAppVersion', getAppVersionFunc, [JavaScriptEnv.mp]);

  /// TODO 在 1.6.60 之后，请使用 sendMessage 替代
  static JavaScriptHandler showShareDialog = JavaScriptHandler._(
      'showShareDialog', showShareDialogFunc, [JavaScriptEnv.mp]);

  static JavaScriptHandler isFromDmChannel = JavaScriptHandler._(
      'isFromDmChannel', isFromDmChannelFunc, [JavaScriptEnv.mp]);

  static JavaScriptHandler getDmChannel =
      JavaScriptHandler._('getDmChannel', getDmChannelFunc, [JavaScriptEnv.mp]);

  static JavaScriptHandler sendMessage =
      JavaScriptHandler._('sendMessage', sendMessageFunc, [JavaScriptEnv.mp]);

  static JavaScriptHandler saveImage =
      JavaScriptHandler._('saveImage', saveImageFunc, [JavaScriptEnv.mp]);

  static JavaScriptHandler showInput =
      JavaScriptHandler._('showInput', showInputFunc, [JavaScriptEnv.mp]);

  static JavaScriptHandler hideInput =
      JavaScriptHandler._('hideInput', hideInputFunc, [JavaScriptEnv.mp]);

  static JavaScriptHandler setOrientation = JavaScriptHandler._(
      'setOrientation', setOrientationFunc, [JavaScriptEnv.mp]);

  static Future<Map> getSystemInfoFunc(
      _, MiniProgramPageController controller) async {
    final info = WidgetsBinding.instance.window;
    return <String, dynamic>{
      "textScaleFactor": info.textScaleFactor,
      "devicePixelRatio": info.devicePixelRatio,
      "locale": {
        "countryCode": info.locale.countryCode,
        "languageCode": info.locale.languageCode,
      },
      "physicalSize": {
        "width": info.physicalSize.width,
        "height": info.physicalSize.height,
      },
      "platformBrightness":
          info.platformBrightness == Brightness.dark ? "dart" : "light",
      "viewPadding": {
        "left": info.viewPadding.left / info.devicePixelRatio,
        "right": info.viewPadding.right / info.devicePixelRatio,
        "top": info.viewPadding.top / info.devicePixelRatio,
        "bottom": info.viewPadding.bottom / info.devicePixelRatio,
      },
    };
  }

  static Map<String, dynamic> getUserTokenFunc(
      _, MiniProgramPageController controller) {
    return <String, dynamic>{
      "token": Config.token,
    };
  }

  static void setClipboardDataFunc(
      List args, MiniProgramPageController controller) {
    if (args.isEmpty) return;
    showToast("复制成功".tr);
    unawaited(Clipboard.setData(ClipboardData(text: args.first.toString())));
  }

  static Future<String> getClipboardDataFunc(
      _, MiniProgramPageController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data.text;
  }

  static Future<Map> getUserInfoFunc(
      _, MiniProgramPageController controller) async {
    final user = Global.user;
    return {
      "userId": user?.id ?? "",
      "nickname": user?.nickname ?? "",
      "avatar": user?.avatar ?? "",
      "gender": user?.gender ?? "",
      "shortId": user?.username ?? "",
    };
  }

  /// base64FileString 文件数据的base64编码字符串
  /// fileName 文件名
  /// fileType 文件类型
  static Future<String> uploadFileFunc(
      List args, MiniProgramPageController controller) async {
    if (args.length != 3) {
      return "";
    }
    try {
      final String base64FileString = args[0];
      final String fileName = args[1];
      final String fileType = args[2];
      final bytes = base64Decode(base64FileString);
      if (bytes == null || bytes.isEmpty) return "";
      String url = "";
      try {
        var fType = CosUploadFileType.unKnow;
        if (fileType.trim() == "image") fType = CosUploadFileType.image;
        if (fileType.trim() == "video") fType = CosUploadFileType.video;
        if (fileType.trim() == "doc") fType = CosUploadFileType.doc;
        if (fileType.trim() == "audio") fType = CosUploadFileType.audio;
        if (fileType.trim() == "live") fType = CosUploadFileType.live;
        // url = await uploadFileIfNotExist(
        //     bytes: bytes, filename: fileName, fileType: fileType);
        url = await CosFileUploadQueue.instance
            .onceForBytes(bytes, fType, fileName: fileName);
      } catch (e) {
        url = "";
      }
      return url;
    } catch (e) {
      rethrow;
    }
  }

  static Map getCurrentGuildFunc(_, MiniProgramPageController controller) {
    final ct = ChatTargetsModel.instance.selectedChatTarget;
    return {
      "id": ct.id,
      'name': ct.name,
      'ownerId': (ct is GuildTarget) ? ct.ownerId : null,
    };
  }

  static Map getCurrentChannelFunc(_, MiniProgramPageController controller) {
    final channel = GlobalState.selectedChannel?.value;
    return {
      "id": channel?.id,
      'name': channel?.name,
    };
  }

  static Future<Map<String, dynamic>> oAuthFunc(
      List args, MiniProgramPageController controller) async {
    try {
      if (args.isEmpty || args.first is! Map) return null;
      final redirectUrl = args.first['oAuthUrl'];
      final redirectRes = await Http.dio.get(redirectUrl);
      if (!redirectRes.isRedirect || redirectRes.redirects.isEmpty)
        return MpAuthRes(errMsg: '授权失败'.tr).toJson();
      final clientId =
          redirectRes.redirects.first.location.queryParameters['client_id'];
      // const clientId = '227051388427964416';
      final res = await Routes.pushFanbookAuthPage(clientId: clientId);
      if (res == null) {
        return MpAuthRes(errMsg: '授权失败'.tr).toJson();
      }
      return MpAuthRes(errMsg: '', data: {'code': Uri.encodeComponent(res)})
          .toJson();
    } catch (e) {
      return MpAuthRes(errMsg: '授权失败'.tr).toJson();
    }
  }

  static Future<void> closeWindowFunc(
      _, MiniProgramPageController controller) async {
    // 先判断当前路由栈是否有小程序，防止多次调用closeWindow api
    if (!PageRouterObserver.instance
        .hasPage(app_pages.Routes.MINI_PROGRAM_PAGE)) {
      return;
    }

    Get.until((route) => (route.settings.name ?? '')
        .startsWith(app_pages.Routes.MINI_PROGRAM_PAGE));
    // 关掉小程序
    Get.back();
    // try {
    //   final previousRoute = Get.find<MiniProgramPageController>().previousRoute;
    //   if (previousRoute.noValue) {
    //     Get.back();
    //   } else {
    //     Get.until((route) =>
    //         [previousRoute, '/$previousRoute'].contains(route.settings.name));
    //   }
    // } catch (e) {
    //   Get.back();
    // }
  }

  static Future<String> getAppVersionFunc(
      _, MiniProgramPageController controller) async {
    String appVersion;
    try {
      appVersion = (await PackageInfo.fromPlatform()).version;
    } catch (e) {
      appVersion = '1.0.0';
    }
    return appVersion;
  }

  static Future<bool> showShareDialogFunc(
      List args, MiniProgramPageController controller) async {
    if (args == null || args.isEmpty || args[0] is! Map) return false;
    final shareType = args[0]['type'];
    final shareInfo = args[0]['data'];

    /// 当前只有商品
    if (shareType != 'goods') return false;
    final goods = GoodsShareEntity.fromJson(shareInfo as Map<String, dynamic>);
    if (!goods.isValid()) return false;
    await Get.toNamed(app_pages.Routes.COMMON_SHARE_PAGE, arguments: goods);
    return true;
  }

  static bool isFromDmChannelFunc(_, MiniProgramPageController controller) {
    return GlobalState.isDmChannel;
  }

  static Map getDmChannelFunc(_, MiniProgramPageController controller) {
    return {
      'id': TextChannelController.dmChannel?.id,
      'type': TextChannelController.dmChannel?.type?.index,
      'name': TextChannelController.dmChannel?.name,
    };
  }

  static void handleTcDocMessageFunc(
      List args, MiniProgramPageController controller) {
    try {
      final String str = args[0][1];
      final splits = str.split('\n');
      if (splits.length >= 2) {
        final res = jsonDecode(splits[1]);
        if (res['data'] == null || res['data']['changeset'] == null) return;
        final changesetStr = res['data']['changeset'];
        if (changesetStr is! String) return;
        final changeset = jsonDecode(changesetStr);
        if (changeset['commands'] == null) return;
        final command = (changeset['commands'] as List).firstWhere(
            (element) => element['type'] == 'DocInsertComment',
            orElse: () => null);
        if (command != null) {
          final mutations = (command['mutations'] as List)
              .where((element) => element['ty'] == 'is')
              .toList();
          final content = mutations.map((e) => e['s']).join('');
          print(content);
        }
      }
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> sendMessageFunc(
      List args, MiniProgramPageController controller) async {
    if (args == null || args.isEmpty || args[0] is! Map) return [];
    MessageContentEntity content;
    try {
      content = MessageEntity.contentFromJson(args[0]);
    } catch (e) {
      logger.severe("miniprogram sendMessageFunc", e);
      return [];
    }
    final res = await Get.toNamed(app_pages.Routes.COMMON_SHARE_PAGE,
        arguments: content);
    return res ?? [];
  }

  static Future saveImageFunc(
      List args, MiniProgramPageController controller) async {
    if (args == null || args.isEmpty || args[0] is! Map) return [];
    final headReg = RegExp(r'data:image/(\w+);base64,');
    final base64 =
        ((args[0]['base64'] ?? '') as String).replaceAll(headReg, '');
    String fileName = args[0]['fileName'];
    if (fileName.noValue) {
      final extension = headReg.firstMatch(base64)?.group(0);
      fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    }
    print(base64);
    if (!base64.hasValue) return;
    if (await DiskUtil.availableSpaceGreaterThan(200)) {
      final permission = await checkSystemPermissions(
        context: Get.context,
        permissions: [
          if (UniversalPlatform.isIOS) Permission.photos,
          if (UniversalPlatform.isAndroid) Permission.storage
        ],
      );
      if (permission != true) return;
      final uList = base64Decode(base64);
      await ImageSave.saveImage(
        uList,
        fileName,
      );
    } else {
      final isConfirm = await showConfirmDialog(
        title: '存储空间不足，清理缓存可释放存储空间'.tr,
      );
      if (isConfirm == true) {
        unawaited(Routes.pushCleanCachePage(Get.context));
      }
    }
  }

  // 提供小程序原生输入框（目前用到的小程序：你画我猜）
  static Future<String> showInputFunc(
      List args, MiniProgramPageController controller) async {
    Color color;
    if (args.isNotEmpty && args.first is Map) {
      color = MiniProgramPageConfig.parseBgColorStr(args.first['color']);
    }
    return controller.showInput(color: color);
  }

  // 关闭原生输入框
  static void hideInputFunc(List args, MiniProgramPageController controller) {
    controller.hideInput();
  }

  static void setOrientationFunc(
      List args, MiniProgramPageController controller) {
    switch (args[0]) {
      case "landscape":
        unawaited(SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]));
        break;
      case "portrait":
        unawaited(SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]));
        break;
      default:
        break;
    }
  }
}
