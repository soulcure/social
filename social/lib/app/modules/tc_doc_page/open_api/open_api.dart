import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/document_online/document_api.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/tc_doc_page/controllers/tc_doc_page_controller.dart';
import 'package:im/pages/tool/url_handler/link_handler_preset.dart';
import 'package:im/routes.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';
import 'package:pedantic/pedantic.dart';

class TcDocOpenApi {
  final TcDocPageController pageController;

  String guildId;
  String fileId;
  DocType type;
  String openId;
  String clientId;
  String accessToken;

  /// openApi是否初始化
  bool inited = false;

  TcDocOpenApi(this.pageController) {
    // window初始化完成抛出openapi_init事件
    pageController.webViewController.addJavaScriptHandler(
        handlerName: "openapi_init", callback: (_) => configDocOpenApi());
  }

  InAppWebViewController get webViewController =>
      pageController.webViewController;

  // 初始化openApi
  Future<void> onOpenApiInit({
    @required String guildId,
    @required String fileId,
    @required DocType type,
    @required String openId,
    @required String clientId,
    @required String accessToken,
  }) async {
    if (inited) return;
    this.guildId = guildId;
    this.fileId = fileId;
    this.type = type;
    this.openId = openId;
    this.clientId = clientId;
    this.accessToken = accessToken;

    const source = '''
       window.addEventListener('showAtList',function(e) {
            window.flutter_inappwebview.callHandler("showAtList");
      });
    ''';
    await webViewController.evaluateJavascript(source: source);
    webViewController.addJavaScriptHandler(
        handlerName: "showAtList", callback: (_) => showAtList());
    webViewController.addJavaScriptHandler(
        handlerName: "atUserAndNotify", callback: atUserAndNotify);
    webViewController.addJavaScriptHandler(
        handlerName: "onProfileClick", callback: onProfileClick);
    webViewController.addJavaScriptHandler(
        handlerName: "onOpenLink", callback: onOpenLink);
    inited = true;
  }

  // 配置openApi参数
  Future<void> configDocOpenApi() async {
    debugPrint('configureOpenApi...');
    final isSheet = type == DocType.sheet;
    // 配置openApi，注册输入或点击@的回调
    final source = '''
        // 最后一次点击@时间
        var lastProfileClickTime = new Date();
        // @用户点击定时器
        var profileClickTimer;
        // @点击时间间隔（用于区分双击和单击）
        var profileClickInterval = 300;
        if(window.openApi){
              window.openApi.configure(
                  "$clientId",
                  "$openId",
                  "$accessToken",
                  (success, error) => {
                    if (success) {
                      window.openApi.registerMentionCallbacks(
                          window.debounce(function(){
                            window.flutter_inappwebview.callHandler("showAtList").then(function(res){
                              if(!res)  {
                                  window.openApi.cancelInsertMention();
                              } else {
                                window.openApi.insertMention({
                                    uin: res['id'],
                                    uid: res['id'],
                                    mentionId: res['id'],
                                    mark:res['nickname'],
                                    nick:res['nickname'],
                                    markname:res['nickname'],
                                    "mentionFrom":{
                                        "avatar":"",
                                        "corp_id":"",
                                        "nick":"",
                                        "uid":"",
                                        "uin":"",
                                        "socketUid":"",
                                        "uidSource":1,
                                        "uid_source":1,
                                        "work_id":""
                                    }
                                });
                                window.flutter_inappwebview.callHandler('atUserAndNotify',{'userId':res['id'],'fileId': '$fileId'});
                              }
                            });
                          }),
                       function onProfileClick(val) {
                          console.log('onProfileClick',val['uid']);
                          // sheet文档单击和双击都会触发onProfileClick，与文档原有点的双击进入编辑态的逻辑有冲突
                          // 所以双击时需判断两次点击的时间间隔，单次点击才弹出用户信息面板
                          if($isSheet){
                            if(new Date()-lastProfileClickTime < profileClickInterval) {
                              if(profileClickTimer) clearTimeout(profileClickTimer);
                              return;
                            };
                            lastProfileClickTime = new Date();
                            profileClickTimer = setTimeout(function(){
                              if(!val ||!val['uid']) return;
                              window.flutter_inappwebview.callHandler('onProfileClick',{'uid':val['uid']});
                            },profileClickInterval);
                          } else {
                            if(!val ||!val['uid']) return;
                            window.flutter_inappwebview.callHandler('onProfileClick',{'uid':val['uid']});
                          }
                          
                       },
                       function onOpenLink(url){
                          window.flutter_inappwebview.callHandler('onOpenLink',{'url':url});
                       }
                      )
                    } else {
                      console.log('configure failed!')
                    }
                  }
                );
          } else{
            console.log('window.openApi 对象不存在')
          }
    ''';
    await webViewController.evaluateJavascript(source: source);
  }

  // 拉起@列表
  Future<Map> showAtList() async {
    if (UniversalPlatform.isAndroid)
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
    final atList =
        await Routes.pushRichEditorAtListPage(Get.context, guildId: guildId);
    if (atList.isNotEmpty && atList.first is UserInfo) {
      return {
        'id': (atList.first as UserInfo).userId,
        'nickname': (atList.first as UserInfo).showName(hideRemarkName: true),
      };
    }
    return null;
  }

  // 注入部分css
  Future<void> injectCss() async {
    // 修改@样式、顶部编辑栏高度
    return webViewController.injectCSSCode(source: '''
      #floatingLayerDebugger{
        display: none !important;
      }
      .tdocs-mention-qq-component{
        padding-right: 4px !important;
        box-shadow: unset !important;
        background-color: rgba(25, 140, 254, 0.1) !important;
        color: #198CFE !important;
        border-radius: 0 !important;
        padding-left: 2px !important;
        padding-left: 2px !important;
        border: 0 !important;
      }
      .melo-line-fragment{
        margin-left: 1px;
        margin-right: 1px;
      }
      .header-container--2O03w{
        height: 35px! important;
      }
      #mobile-titlebar-home,#mobile-titlebar-collab,#mobile-titlebar-star,#mobile-titlebar-more-menu{
        display:none !important;
      }
      
      .melo-page-view{
        padding-top:32px !important;
      }
      .tdocs-mention-qq-component::after{
        display:none !important;
      }

    ''');
  }

  // @人发送通知
  Future<void> atUserAndNotify(List args) async {
    if (args.isEmpty) return;
    final userId = (args.first as Map<String, dynamic>)['userId'] as String;
    final fileId = (args.first as Map<String, dynamic>)['fileId'] as String;
    await DocumentApi.docAtUser(fileId, userId);
  }

  // @人点击弹出用户信息
  Future<void> onProfileClick(List args) async {
    if (args.isEmpty) return;
    final userId = (args.first as Map<String, dynamic>)['uid'] as String;
    await pageController
        .unFocus(showUserInfoPopUp(Get.context, userId: userId));
  }

  // 打开链接回调（包括点击按钮、直接点解链接）
  Future<void> onOpenLink(List args) async {
    if (args.isEmpty) return;
    final url = (args.first as Map<String, dynamic>)['url'] as String;
    unawaited(LinkHandlerPreset.common.handle(url));
    // 由于安卓上直接点解链接打开新页面，会延迟聚焦，所以页面取消聚焦也需要延迟
    Future.delayed(200.milliseconds, pageController.clearFocus);
  }
}
