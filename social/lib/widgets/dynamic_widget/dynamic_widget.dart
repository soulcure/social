import 'package:dio/dio.dart';
import 'package:dynamic_card/dynamic_card.dart';
import 'package:dynamic_card/widgets/title/vote_title.dart';
import 'package:flutter/material.dart';
import 'package:im/api/bot_api.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/http_middleware/interceptor/logging_interceptor.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/task_entity.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/json/vote_entity.dart';
import 'package:im/pages/home/view/text_chat/text_chat_ui_creator.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/utils.dart';

import '../../global.dart';
import '../../pages/tool/url_handler/link_handler_preset.dart';
import '../../routes.dart';

class DynamicWidget extends StatefulWidget {
  final Map json;
  final MessageEntity message;
  final DynamicController controller;
  final TempWidgetConfig config;
  final bool onlyRead;

  const DynamicWidget({
    Key key,
    @required this.json,
    this.message,
    this.controller,
    this.config,
    this.onlyRead = false,
  }) : super(key: key);

  @override
  _DynamicWidgetState createState() => _DynamicWidgetState();
}

class _DynamicWidgetState extends State<DynamicWidget> {
  WidgetNode _node;
  Map _tempJson;
  final nodeController = NodeController();

  @override
  void initState() {
    final json = widget.json ?? {};
    _tempJson = json;
    initialNode(json);
    widget.controller?._nodeCallback = getNode;

    super.initState();
  }

  void initialNode(Map json) {
    final config = widget.config.copy(controller: nodeController);
    try {
      _node = JsonToNodeParser.instance.toNode(
        json,
        buttonCallback: (event) {
          onClick(
            event,
            message: widget.message,
          );
        },
        config: config,
        isRoot: true,
      );
    } catch (e) {
      logger.warning('动态卡片转换错误:$e');
    }
  }

  @override
  void dispose() {
    nodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildWidget();
  }

  @override
  void didUpdateWidget(DynamicWidget oldWidget) {
    try {
      final mes = widget.message;
      if (mes?.content is TaskEntity) {
        final mesContent = mes?.content as TaskEntity;
        final oldMesContent = oldWidget.message?.content as TaskEntity;
        final ms1 = mesContent?.content?.toString();
        final ms2 = oldMesContent.content?.toString();
        final tempJsonString = _tempJson.toString();
        if (tempJsonString != ms1 || tempJsonString != ms2) {
          initialNode(mesContent?.content ?? oldMesContent?.content ?? {});
          _tempJson = mesContent.content;
        }
      } else if (mes?.content is VoteEntity) {
        if (widget.json.toString() != _tempJson.toString()) {
          _tempJson = widget.json;
          initialNode(widget.json);
        }
      }
    } catch (e) {
      print('动态卡片更新错误:$e');
    }
    super.didUpdateWidget(oldWidget);
  }

  Widget buildWidget() {
    try {
      if (_node == null) return TextChatUICreator.unSupportWidget(context);
      final resultWidget = widgetVisitor.visitNode(_node);
      if (resultWidget is ColumnWidget) {
        final columnChildren = resultWidget.children ?? [];
        if (columnChildren.isEmpty) return resultWidget;
        final List<Widget> children = [];
        final first = columnChildren.first;
        final needPadding = !isTitle(first);
        if (widget.onlyRead) {
          columnChildren.forEach((child) {
            children.add(canTap(child) ? child : AbsorbPointer(child: child));
          });
          resultWidget.children.clear();
          resultWidget.children.addAll(children);
        }
        if (needPadding)
          resultWidget.children?.insert(0, const SizedBox(height: 8));
      } else if (resultWidget is! ButtonWidget && widget.onlyRead)
        return AbsorbPointer(child: resultWidget);
      return resultWidget;
    } catch (e) {
      logger.warning('动态卡片解析错误:$e');
      return TextChatUICreator.unSupportWidget(context);
    }
  }

  WidgetNode getNode() => _node;

  bool canTap(Widget widget) =>
      widget is ButtonWidget ||
      widget is TextWidget ||
      widget is ContentTextWidget;

  bool isTitle(Widget widget) =>
      widget is TitleWidget ||
      widget is IconTitleWidget ||
      widget is VoteTitleWidget;
}

class DynamicController {
  WidgetNode Function() _nodeCallback;

  void dispose() {
    _nodeCallback = null;
  }

  WidgetNode getNode() {
    return _nodeCallback?.call();
  }
}

final widgetVisitor = DynaWidgetVisitor();

class FunctionName {
  static const String openMiniProgram = 'mini_program';
  static const String openHtmlPage = 'html_page';
  static const String requestBotApi = 'bot_api';
  static const String detailPage = 'detail_page';
  static const String request = 'request';
}

class ParamName {
  static const String url = 'url';
  static const String appId = 'appId';
  static const String callbackData = 'callback_data';
  static const String data = 'data';
  static const String title = 'title';
  static const String extParam = 'ext_param';
  static const String fbParam = 'fb_param';
  static const String messageId = 'message_id';
  static const String userId = 'user_id';
  static const String clientId = 'client_user_id';
  static const String formId = 'form_id';
  static const String nickname = 'nickname';
  static const String avatar = 'avatar';
}

void onClick(ButtonCallbackParam btnParam, {MessageEntity message}) {
  if (btnParam.event == null || btnParam.event.method == null) return;
  final param = btnParam.event.param ?? {};
  if (param == null || param is! Map) return;
  switch (btnParam.event.method) {
    case FunctionName.openMiniProgram:
      Routes.pushMiniProgram(param[ParamName.appId]);
      break;
    case FunctionName.openHtmlPage:
      LinkHandlerPreset.common.handle(param[ParamName.url] ?? '');
      break;
    case FunctionName.requestBotApi:
      if (message == null) return;
      BotApi.invokeRemoteCallback(
        userId: Global.user.id,
        data: param[ParamName.callbackData] ?? '',
        message: message,
      );
      break;
    case FunctionName.detailPage:
      final json = param[ParamName.data] ?? {};
      final title = param[ParamName.title] ?? '';
      Routes.pushDynamicPage(json: json, message: message, title: title);
      break;
    case FunctionName.request:
      final extParam = param[ParamName.extParam] ?? {};
      final url = (param[ParamName.url] ?? '').toString();
      final fbParam = {
        ParamName.messageId: message?.messageId,
        ParamName.userId: message?.userId,
        ParamName.clientId: Global.user.id,
        ParamName.nickname: Global.user.nickname,
        ParamName.avatar: Global.user.avatar,
      };
      if (url.isEmpty) return;
      _postVote(url, {
        ParamName.extParam: extParam,
        ParamName.fbParam: fbParam,
        ParamName.formId: btnParam.formParam
      });
      break;
  }
}

void _postVote(String url, Map data) {
  final _dio = Dio(); //dio 构造为 factory 可以直接使用
  _dio.interceptors.add(LoggingInterceptor());
  _dio.options.connectTimeout = 5000;

  ///添加代理
  final String proxy = SpService.to.getString(SP.proxySharedKey);
  if (Http.useProxy && isNotNullAndEmpty(proxy)) Http.setProxy(_dio, proxy);

  _dio.post(url, data: data);
}
