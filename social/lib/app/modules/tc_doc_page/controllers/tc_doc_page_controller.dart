import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/document_online/document_api.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/create_doc_item.dart';
import 'package:im/app/modules/document_online/entity/doc_info_item.dart';
import 'package:im/app/modules/document_online/sub/document_option_menu_widget.dart';
import 'package:im/app/modules/document_online/sub/rename_sheet_widget.dart';
import 'package:im/app/modules/mini_program_page/controllers/mini_program_page_controller.dart';
import 'package:im/app/modules/mini_program_page/entity/mini_program_config.dart';
import 'package:im/app/modules/tc_doc_add_group_page/entities/tc_doc_group.dart';
import 'package:im/app/modules/tc_doc_page/open_api/open_api.dart';
import 'package:im/app/modules/tc_doc_page/views/share_action_popup.dart';
import 'package:im/app/modules/tc_doc_page/views/tc_doc_online_view.dart';
import 'package:im/app/modules/tc_doc_page/views/tc_doc_setting_page_view.dart';
import 'package:im/app/routes/app_pages.dart' as get_pages;
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/config.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/mini-program/javascript_hander.dart';
import 'package:im/services/server_side_configuration.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/tc_doc_utils.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/toast.dart';
import 'package:im/ws/tc_doc_handler.dart';
import 'package:im/ws/ws.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:tuple/tuple.dart';

enum TcDocPageReturnType {
  add,
  delete,
  update,
}

// ?????? clientId
String _clientId;
// openApi token
String _accessToken;
// openApi openId
String _openId;
// ??????token????????????
DateTime _expiresIn;

class TcDocPageController extends MiniProgramPageController {
  static const updateIdAppbar = 'appbar';

  TcDocPageController({this.fromSelectPage = false});

  //  ??????????????????
  bool fromSelectPage;

  /// ????????????
  DocInfoItem tcDocInfo;

  /// ??????????????????
  Uri docUrl;

  /// ??????????????????
  LinkedHashSet<String> onlineUserSet = LinkedHashSet<String>();

  /// ??????????????????
  int onlineUserNum = 0;

  /// ????????????future
  Future<DocInfoItem> docInfoFuture;

  /// access_token future
  Future tokenFuture = Future.value();

  /// ??????webview?????????????????????????????????????????????????????????,??????????????????????????????
  List<Tuple2<TcDocPageReturnType, DocInfoItem>> docs = [];

  // ??????openApi??????
  TcDocOpenApi openApi;

  // ??????????????????
  StreamSubscription _docChangeStream;

  // ??????????????????
  StreamSubscription _connectivityChangeStream;

  // ????????????????????????
  bool deleted = false;

  // ????????????appBar??????????????????????????????css????????????????????????500ms????????????????????????????????????????????????????????????
  bool shouldShowAppbarExtra = false;

  Future<void> _setDocCookie() async {
    await _setCookie("env_name", ServerSideConfiguration.to.tcDocEnvName);
    await _setCookie("env_id", ServerSideConfiguration.to.tcDocEnvId);
    await _setCookie("open_theme_id", "fanbook");
  }

  Future<void> _setCookie(String key, String value) async {
    if (!key.hasValue || !value.hasValue) return;
    await CookieManager.instance().setCookie(
      url: Uri(scheme: 'https', host: "docs.qq.com"),
      domain: '.docs.qq.com',
      name: key,
      value: value,
      isSecure: !Config.isDebug,
      maxAge: 365 * 24 * 3600,
    );
  }

  @override
  Map<String, String> get requestHeaders {
    return {
      'Authorization': Config.token,
      'Client-id': Http.dio.options.headers['Client-id'],
    };
  }

  @override
  void onInit() {
    webViewVisible = false;
    loading = false;
    super.onInit();
    _setDocCookie();
    _initDocInfo(appId).then((value) {
      update();
    });
    _listenConnectivityChange();
  }

  @override
  void onClose() {
    _reset();
    _connectivityChangeStream?.cancel();
    super.onClose();
  }

  Future<void> _initDocInfo(String appId, {bool isNew = false}) async {
    docUrl = Uri.parse(appId);
    if (TcDocUtils.docUrlReg.hasMatch(docUrl.toString())) {
      if (docUrl.pathSegments.last.isNotEmpty) {
        docInfoFuture =
            DocumentApi.docInfo(docUrl.pathSegments.last, collectTime: true);
        final docInfo = await docInfoFuture;
        if (docInfo.fileId == null) {
          deleted = true;
          loading = false;
        } else {
          unawaited(_requestTokenIfNeed());
          tcDocInfo = docInfo;
          // ????????????????????????????????????
          tcDocInfo.viewedAt = DateTime.now().millisecondsSinceEpoch;
          if (isNew) {
            // ??????????????????????????????????????????
            docs.add(Tuple2(TcDocPageReturnType.add, tcDocInfo));
          } else {
            // ???????????????
            docs.add(Tuple2(TcDocPageReturnType.update, tcDocInfo));
          }
          // ??????????????????app???????????????????????????????????????false????????????????????????
          if (tcDocInfo.type == DocType.slide) {
            resizeToAvoidBottomInset = false;
          }
          if (tcDocInfo.type == DocType.doc) {
            shouldShowAppbarExtra = true;
          }
          webViewVisible = true;
          unawaited(fetchUserList());
          _listenDocChange();
        }
      }
    }
  }

  Future<void> _requestTokenIfNeed() async {
    if (!_isTokenExpired) return;
    tokenFuture = DocumentApi.docUser();
    final res = await tokenFuture;
    if (res is Map) {
      _expiresIn = DateTime.fromMillisecondsSinceEpoch(
          (res['expires_in'] as int) * 1000);
      _accessToken = res['access_token'];
      _openId = res['open_id'];
      _clientId = res['client_id'];
    }
  }

  bool get _isTokenExpired {
    if (_accessToken == null) return true;
    // token????????????????????????????????????token
    return DateTime.now().add(const Duration(hours: 1)).compareTo(_expiresIn) >
        0;
  }

  @override
  Color get navigationBarTextColor => Get.textTheme.bodyText2.color;

  @override
  Uri getRequestUri() {
    return docUrl;
  }

  // ??????????????????
  void _listenConnectivityChange() {
    rx.Rx.defer(() => Ws.instance
            .on<WsMessage>()
            .where((event) => event.action == MessageAction.connect))
        .debounceTime(500.milliseconds)
        .listen((event) {
      DocumentApi.docJoin(tcDocInfo.fileId);
    });
  }

  // ????????????????????????????????????????????????
  void _listenDocChange() {
    _docChangeStream = rx.Rx.defer(() => Ws.instance.on<WsMessage>().where(
              (event) =>
                  event.action == MessageAction.tcDocViewUp ||
                  event.action == MessageAction.tcDocGroupUp,
            ))
        .debounceTime(3.seconds)
        .map((event) => event.data)
        .listen((event) async {
      // ??????????????????
      if (event is TcDocViewUpEvent) {
        if (event.fileId != tcDocInfo.fileId ||
            event.guildId != tcDocInfo.guildId) return;
        await fetchUserList();
      }
      // ?????????????????????
      if (event is TcDocGroupUpEvent) {
        if (event.fileId != tcDocInfo.fileId ||
            event.guildId != tcDocInfo.guildId) return;
        final DocInfoItem res = await DocumentApi.docInfo(
            docUrl.pathSegments.last,
            collectTime: true);
        if (res.role != tcDocInfo.role) {
          // ????????????????????????
          showSnackBar();
          // ???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
          if (res.role == TcDocGroupRole.view) {
            await clearFocus();
            await _addDocMask();
          }
        }
      }
    });
  }

  @override
  Future<void> onLoadStart(InAppWebViewController c, Uri url) async {
    if (UniversalPlatform.isAndroid) {
      if (TcDocUtils.tcDocUrlReg.hasMatch(url.toString())) {
        unawaited(docInfoFuture.whenComplete(() {
          JavaScriptRegister(
            guildId: tcDocInfo.guildId,
            fileId: tcDocInfo.fileId,
            controller: this,
            env: JavaScriptEnv.tc_doc,
          );
          tokenFuture.whenComplete(() {
            openApi?.onOpenApiInit(
              guildId: tcDocInfo.guildId,
              fileId: tcDocInfo.fileId,
              type: tcDocInfo.type,
              openId: _openId,
              clientId: _clientId,
              accessToken: _accessToken,
            );
          });
        }));
      }
    }
    super.onLoadStart(c, url);
  }

  @override
  Future<void> onLoadStop(Uri url) async {
    unawaited(super.onLoadStop(url));
    // ??????css??????webView??????ready??????????????????loadStart???created????????????
    await openApi.injectCss();
    shouldShowAppbarExtra = false;
    update([updateIdAppbar]);
  }

  @override
  Future<IOSNavigationResponseAction> iosOnNavigationResponse(
      InAppWebViewController controller,
      IOSWKNavigationResponse navigationResponse) async {
    final tcDocUrlReg =
        RegExp(r'docs.qq.com/(doc|sheet|mind|slide|page|flowchart)/\w+');
    if (tcDocUrlReg.hasMatch(navigationResponse.response.url.toString())) {
      unawaited(docInfoFuture.whenComplete(() {
        JavaScriptRegister(
          fileId: tcDocInfo.fileId,
          guildId: tcDocInfo.guildId,
          controller: this,
          env: JavaScriptEnv.tc_doc,
        );
        tokenFuture.whenComplete(() {
          openApi?.onOpenApiInit(
            guildId: tcDocInfo.guildId,
            fileId: tcDocInfo.fileId,
            type: tcDocInfo.type,
            openId: _openId,
            clientId: _clientId,
            accessToken: _accessToken,
          );
        });
      }));
    }
    return IOSNavigationResponseAction.ALLOW;
  }

  @override
  Future<void> onRestart() async {
    Get.until((route) =>
        (route.settings.name ?? '').startsWith(get_pages.Routes.TC_DOC_PAGE));
    // ????????????????????????push
    Get.back();
    Future.delayed(const Duration(milliseconds: 800), () {
      Get.toNamed(get_pages.Routes.TC_DOC_PAGE, parameters: {'appId': appId});
    });
  }

  @override
  Future<void> popRoute() async {
    if (tcDocInfo != null) {
      unawaited(DocumentApi.docQuit(tcDocInfo.fileId, tcDocInfo.guildId));
    }
    Get.back(result: docs);
  }

  @override
  Future<void> showMore() async {
    if (webViewController == null) return;
    await unFocus(super.showMore());
  }

  @override
  Future<void> onWebViewCreated(InAppWebViewController controller) async {
    super.onWebViewCreated(controller);
    openApi ??= TcDocOpenApi(this);
  }

  @override
  Future<MiniProgramConfig> loadConfigJson() => Future.value();

  Future<void> fetchUserList([_]) async {
    final res = await DocumentApi.docOnlineUser(tcDocInfo.fileId);
    if (res['lists'] != null) {
      final dataList = LinkedHashSet<String>.from(res['lists']);
      setOnlineUser(dataList, res['count'] ?? 0);
    }
  }

  void setOnlineUser(LinkedHashSet<String> dataList, int totalNum) {
    final isContain = dataList.contains(Global.user.id);
    // ??????????????????????????????????????????????????????????????????????????????????????????????????????
    // ???????????????????????????????????????????????????????????????????????????+1??????
    // ??????????????????????????????????????????????????????+1
    onlineUserNum = totalNum;
    if (!isContain) {
      onlineUserNum++;
    }
    // ???????????????????????????????????????????????????
    onlineUserSet
      ..clear()
      ..add(Global.user.id)
      ..addAll(dataList);
    update([updateIdAppbar]);
  }

  Future<void> handleShareAction() async {
    await unFocus(showShareActionPopup(
      context: Get.context,
      docInfo: tcDocInfo,
    ));
  }

  Future<void> showActions() async {
    final canCopy = (tcDocInfo.canCopy == true ||
            tcDocInfo.role == TcDocGroupRole.edit ||
            tcDocInfo.isOwner) &&
        PermissionUtils.hasPermission(
          permission: Permission.CREATE_DOCUMENT,
        );
    final actions = [
      if (tcDocInfo.isOwner)
        Text(
          '?????????'.tr,
          style: appThemeData.textTheme.bodyText2,
          key: const ValueKey(0),
        ),
      // Text('????????????'.tr,
      //     style: appThemeData.textTheme.bodyText2, key: const ValueKey(1)),

      if (canCopy)
        Text('????????????'.tr,
            style: appThemeData.textTheme.bodyText2, key: const ValueKey(2)),
      if (tcDocInfo.isOwner)
        Text('????????????'.tr,
            style: appThemeData.textTheme.bodyText2, key: const ValueKey(5)),
      Text('??????????????????'.tr,
          style: appThemeData.textTheme.bodyText2, key: const ValueKey(3)),
      if (tcDocInfo.isOwner)
        Text('??????'.tr,
            style: appThemeData.textTheme.bodyText2
                .copyWith(color: DefaultTheme.dangerColor),
            key: const ValueKey(4)),
    ];
    final key = await unFocus(showCustomActionSheet<ValueKey<int>>(actions));
    switch (key?.value) {
      case 0:
        await _actionRename();
        break;
      case 1:
        await _actionShowCatalog();
        break;
      case 2:
        await _actionCopy();
        break;
      case 3:
        await _actionToDocInfo();
        break;
      case 4:
        await _actionDelete();
        break;
      case 5:
        await _actionToSetting();
        break;
      default:
    }
  }

  Future<void> _actionRename() async {
    final res = await unFocus(showBottomModal(
      Get.context,
      builder: (c, s) => RenameSheetWidget(tcDocInfo.fileId, tcDocInfo.title),
      backgroundColor: CustomColor(Get.context).backgroundColor6,
      bottomInset: false,
    ));
    if (res is OptionMenuResult && res.type == OptionMenuType.rename) {
      Toast.iconToast(icon: ToastIcon.success, label: '???????????????');
      tcDocInfo.title = res.info;
      // ??????docs???????????????????????????tcDocInfo??????????????????????????????????????????
      final doc = docs.firstWhere(
          (element) => element.item2.fileId == res.fileId,
          orElse: () => null);
      if (doc == null) {
        docs.add(Tuple2(TcDocPageReturnType.update, tcDocInfo));
      }
    }
  }

  Future<void> _actionShowCatalog() async {
    showToast('?????????');
  }

  Future<void> _actionCopy() async {
    final CreateDocItem res = await DocumentApi.docCopy(tcDocInfo.fileId);
    if (res != null) {
      Toast.iconToast(icon: ToastIcon.success, label: '??????????????????'.tr);
      hideSnackBar();
      unawaited(DocumentApi.docQuit(tcDocInfo.fileId, tcDocInfo.guildId));
      _reset();
      await _initDocInfo(res.url, isNew: true);
      // loading = true;
      update();
    }
  }

  Future<void> _actionToDocInfo() async {
    await Get.toNamed(get_pages.Routes.DOCUMENT_INFO,
        arguments: tcDocInfo.fileId);
  }

  Future<void> _actionDelete() async {
    final actions = [
      Text('???????????????????????????'.tr,
          style: TextStyle(
            color: appThemeData.iconTheme.color,
            fontSize: 14,
          )),
      Text('????????????'.tr,
          style: appThemeData.textTheme.bodyText2
              .copyWith(color: DefaultTheme.dangerColor)),
    ];
    final res = await unFocus(showCustomActionSheet<int>(actions));
    if (res == 1) {
      await DocumentApi.docDel(
        tcDocInfo.guildId,
        tcDocInfo.fileId,
        DelType.delFile,
      );
      // ??????docs???????????????????????????tcDocInfo???????????????????????????????????????
      final docIndex = docs
          .indexWhere((element) => element.item2.fileId == tcDocInfo.fileId);
      if (docIndex == -1) {
        docs.add(Tuple2(TcDocPageReturnType.delete, tcDocInfo));
      } else {
        final doc = docs[docIndex];
        if (doc.item1 == TcDocPageReturnType.update) {
          docs.replaceRange(docIndex, docIndex + 1,
              [Tuple2(TcDocPageReturnType.delete, tcDocInfo)]);
        } else if (doc.item1 == TcDocPageReturnType.add) {
          // ?????????????????????????????????
          docs.remove(doc);
        }
      }
      Get.back(result: docs);
    }
  }

  Future<void> _actionToSetting() async {
    final RxBool canCopy = RxBool(tcDocInfo.canCopy);
    canCopy.listen((val) {
      tcDocInfo.canCopy = val;
    });
    final Rx<bool> canReaderComment = Rx<bool>(tcDocInfo.canReaderComment);
    canReaderComment.listen((type) {
      tcDocInfo.canReaderComment = type;
    });
    await Get.to(TcDocSettingPageView(
      fileId: tcDocInfo.fileId,
      type: tcDocInfo.type,
      canCopy: canCopy,
      canReaderComment: canReaderComment,
    ));
    await Future.delayed(500.milliseconds);
    canCopy.close();
    canReaderComment.close();
  }

  Future<void> toggleCollect() async {
    if (tcDocInfo.isCollect()) {
      final res = await DocumentApi.docCollectRemove(tcDocInfo.fileId);
      if (res == true) {
        showToast('???????????????'.tr, dismissOtherToast: true);
        tcDocInfo.setCollect(false);
      }
    } else {
      final res = await DocumentApi.docCollectAdd(tcDocInfo.fileId);
      if (res == true) {
        Toast.iconToast(
          icon: ToastIcon.success,
          label: '????????????????????????'.tr,
          dismissOtherToast: true,
        );
        tcDocInfo.setCollect(true);
      }
    }
    // ??????docs???????????????????????????tcDocInfo??????????????????????????????????????????
    final doc = docs.firstWhere(
        (element) => element.item2.fileId == tcDocInfo.fileId,
        orElse: () => null);
    if (doc == null) {
      docs.add(Tuple2(TcDocPageReturnType.update, tcDocInfo));
    }
    update([updateIdAppbar]);
  }

  Future<void> showOnlinePopup() async {
    if (tcDocInfo == null) return;
    await unFocus(showBottomModal(
      Get.context,
      backgroundColor: Get.theme.backgroundColor,
      headerBuilder: (_, __) {
        return Material(
          color: Get.theme.backgroundColor,
          child: Container(
            height: 44,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '%s???????????????'.trArgs([onlineUserNum.toString()]),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        );
      },
      builder: (_, __) => SizedBox(
          height: 400,
          child:
              SizedBox(height: 200, child: TcDocOnlineView(tcDocInfo.fileId))),
    ));
  }

  // webView????????????
  Future<T> unFocus<T>(Future<T> future) async {
    // ????????????????????????????????????????????????flutter??????
    await clearFocus();
    // ??????ios??????????????????????????????????????????????????????????????????????????????????????????
    await _addDocMask();
    return future.whenComplete(_removeDocMask);
  }

  // ???webView???????????????????????????
  Future<void> _addDocMask() async {
    const source = '''
      var ele = document.getElementById('app-mask');
      if(!ele) {
        ele = document.createElement('div');
        ele.setAttribute('id','app-mask');
        ele.setAttribute('style','left:0;top:0;width: 100vw;height: 100vh;position: fixed;z-index:99999;');
        document.body.appendChild(ele);
      }
    ''';
    await webViewController?.evaluateJavascript(source: source);
  }

  // ??????webView???????????????
  Future<void> _removeDocMask() async {
    if (snackBarVisible) return;
    const source = '''
      var ele = document.getElementById('app-mask');
      if(ele) {
        document.body.removeChild(ele)
      }
    ''';
    await webViewController?.evaluateJavascript(source: source);
  }

  void refreshDoc() {
    hideSnackBar();
    _reset();
    _initDocInfo(appId);
    // loading = true;
    update();
  }

  // ???????????????????????????
  void _reset() {
    openApi = null;
    webViewKey = ValueKey(webViewKey.value + 1);
    unawaited(_docChangeStream?.cancel());
  }
}
