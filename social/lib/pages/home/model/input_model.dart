import 'package:event_bus/event_bus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:im/api/bot_api.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/query_result_article.dart';
import 'package:im/api/entity/query_result_photo.dart';
import 'package:im/api/entity/role_bean.dart';
import 'package:im/common/extension/future_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/config.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/bot_commands/model/displayed_cmds_model.dart';
import 'package:im/pages/home/gif_search_controller.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_field_utils.dart';
import 'package:im/pages/home/model/universal_rich_input_controller.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:rxdart/rxdart.dart';

part 'input_model.g.dart';

@HiveType(typeId: 3)
class InputRecord {
  @HiveField(0)
  String replyId;
  @HiveField(1)
  String content;
  @HiveField(2)
  String richContent;

  InputRecord({this.replyId, this.content, this.richContent});
}

class SetArticleFilter {
  final String value;
  final String robotId;
  final List<EntityQueryResultArticle> initData;

  SetArticleFilter(this.robotId, this.value, this.initData);
}

class SetEmojiFilter {
  final String value;
  final String robotId;
  final List<EntityQueryResultPhoto> initData;

  SetEmojiFilter(this.robotId, this.value, this.initData);
}

typedef ReplyChangeCallback = void Function(MessageEntity, String);

class InputModel extends ChangeNotifier {
  final FocusNode textFieldFocusNode;
  final ScrollController scrollController;
  String channelId;
  final String guildId;
  final ChatChannelType type;
  MessageEntity _reply;

  MessageEntity get reply => _reply;
  final PublishSubject<String> _contentChangeStream;

  PublishSubject<String> get contentChangeStream => _contentChangeStream;

  final ReplyChangeCallback onReplyChange;

  /// 机器人搜索内容
  String _searchValue;

  ValueNotifier<double> paddingBottom = ValueNotifier(0);

  RobotCmdInputListener robotCmdListener;

  UniversalRichInputController inputController;

  bool _inputListening = true;

  set reply(MessageEntity value) {
    _reply = value;
    inputController.clear();
    onReplyChange?.call(value, inputController.data);
    notifyListeners();
  }

  final EventBus eventBus = EventBus();

  String _gifSearchControllerTag;

  InputModel({
    @required this.channelId,
    @required this.guildId,
    @required this.type,
    this.onReplyChange,
  })  : inputController = UniversalRichInputController(),
        textFieldFocusNode = FocusNode(),
        scrollController = ScrollController(),
        _contentChangeStream = PublishSubject(sync: true) {
    _gifSearchControllerTag = "${Get.currentRoute}\$$channelId";
    Get.put<GifSearchController>(
      GifSearchController(
          textEditingController: inputController,
          focusNode: textFieldFocusNode,
          channelId: channelId),
      tag: _gifSearchControllerTag,
    );

    inputController.addListener(_onInput);
  }

  Future<void> _onInput() async {
    if (!_inputListening) return;
    _contentChangeStream.add(inputController.data);
    robotCmdListener?.isInputting(inputController.text.hasValue);

    robotCmdListener?.onAtRobot(null);
  }

  // ignore: unused_element
  Future<void> _checkAtContent() async {
    /// todo 每次都搜索全部文本？只匹配最后一个@？只判断了@用户的情况，@角色会报错
    final value = inputController.data;

    final atIndex = value.lastIndexOf("{@");
    if (atIndex < 0) return;
    final endIndex = value.indexOf('}', atIndex + 1);
    if (endIndex < atIndex && (value.length - 1 != endIndex)) return;
    final userId = value.substring(atIndex + 3, endIndex);
    final content = value.substring(endIndex + 1);

    if (_searchValue != content && content.isNotEmpty) {
      final atRole = await UserInfo.get(userId);
      if (!atRole.isBot) return;
      _searchValue = content;

      final result = await BotApi.getArticles({
        'bot_id': userId,
        'user_id': Global.user.id,
        'query': content,
        'offset': '1'
      });
      if (result != null) {
        final List<dynamic> datas = result['results'];
        if (datas.isEmpty) return;
        switch (datas.first['type']) {
          case 'article':
            final list = datas
                .map((json) => EntityQueryResultArticle.fromJson(
                    Map<String, dynamic>.from(json)))
                .toList();
            eventBus.fire(SetArticleFilter(userId, content, list));
            eventBus.fire(SetEmojiFilter(null, null, []));
            break;
          case 'photo':
            final list = datas
                .map((json) => EntityQueryResultPhoto.fromJson(
                    Map<String, dynamic>.from(json)))
                .toList();
            eventBus.fire(SetEmojiFilter(userId, content, list));
            eventBus.fire(SetArticleFilter(null, null, []));
            break;
        }
      }
    }
  }

  @override
  void dispose() {
    Get.delete<GifSearchController>(tag: _gifSearchControllerTag);
    _contentChangeStream.close();
    paddingBottom.dispose();
    textFieldFocusNode.dispose();
    inputController.dispose();

    eventBus.destroy();
    scrollController.dispose();
    super.dispose();
  }

  void add(
    String id,
    String name, {
    // 是否跳过搜索匹配和替换，直接添加到输入框内
    bool addDirectly = false,
    @required bool atRole,
    bool isBot = false,
  }) {
    if (!UniversalPlatform.isIOS) _inputListening = false;
    robotCmdListener?.isInputting(true);
    final bool isPureText = _shouldInsertPureText(atRole, id);
    final at = TextEntity.getAtString(id, atRole);
    if (isPureText) {
      _insertAtText(name, addDirectly: addDirectly);
    } else {
      _insertAt(name, at, addDirectly: addDirectly);
    }
    if (!atRole && isBot && !isPureText) {
      Future.delayed(
        Duration(milliseconds: UniversalPlatform.isIOS ? 100 : 0),
        () => robotCmdListener?.onAtRobot(id),
      );
    }
    if (!UniversalPlatform.isIOS)
      Future.delayed(
          const Duration(milliseconds: 100), () => _inputListening = true);
  }

  // 当用户在该频道没有查看消息权限时插入纯文本
  bool _shouldInsertPureText(bool atRole, String id) {
    if (type != ChatChannelType.guildVoice &&
        type != ChatChannelType.guildText &&
        type != ChatChannelType.guildText &&
        type != ChatChannelType.guildVideo) {
      return false;
    }
    return !atRole &&
        RoleBean.isContain(id, guildId) &&
        !_hasViewChannelPermission(id, RoleBean.get(id, guildId));
  }

  // 计算是否有查看频道权限
  bool _hasViewChannelPermission(String userId, List<String> roles) {
    if (roles == null) return false;
    final gp = PermissionModel.getPermission(guildId).clone();
    // 在服务器的用户计算权限
    gp.userRoles = [...roles, gp.guildId];
    return PermissionUtils.isChannelVisible(gp, channelId, userId: userId);
  }

  void _insertAtText(String name, {bool addDirectly = false}) {
    final atText = '@$name ';
    if (addDirectly) {
      inputController.insertText(atText);
    } else {
      final matchInputResult = TextFieldUtils.matchInputContent(
          inputController: inputController, matchChar: "@");
      if (!Config.useNativeInput)
        inputController.replaceRange(
          '',
          start: matchInputResult.matchIndex,
          end: matchInputResult.caretIndex,
        );
      inputController.insertText(atText,
          backSpaceLength:
              matchInputResult.caretIndex - matchInputResult.matchIndex);
    }
  }

  Future<void> _insertAt(String name, String data,
      {bool addDirectly = false}) async {
    if (addDirectly) {
      inputController.insertAt(name,
          data: data, textStyle: TextStyle(color: primaryColor, fontSize: 17));
    } else {
      final matchInputResult = TextFieldUtils.matchInputContent(
          inputController: inputController, matchChar: "@");
      if (!Config.useNativeInput)
        inputController.replaceRange(
          '',
          start: matchInputResult.matchIndex,
          end: matchInputResult.caretIndex,
        );
      inputController.insertAt(name,
          data: data,
          textStyle: TextStyle(color: primaryColor, fontSize: 17),
          backSpaceLength:
              matchInputResult.caretIndex - matchInputResult.matchIndex);
    }
  }

  void webInsertText(String text) {
    final selection = inputController.selection;
    inputController.rawFlutterController.value = TextEditingValue(
        text: inputController.text.substring(0, selection.start) +
            text +
            inputController.text.substring(selection.start),
        selection: TextSelection.collapsed(
            offset: inputController.selection.start + text.length));
  }

  Future setValue(String text,
      {bool requestFocus = false, MessageEntity reply}) async {
    final pattern = RegExp(r"\$\{.*?\}");
    final atList = pattern.allMatches(text ?? "").toList(growable: false);
    if (atList.isEmpty) {
      inputController.text = text ?? '';
    } else {
      void doWork() {
        if (UniversalPlatform.isAndroid) inputController.clear();
        final chunks = text.split(RegExp(r"\$\{.*?\}"));
        bool isReplaced = false;
        for (int i = 0; i < chunks.length; i++) {
          if (chunks[i].isNotEmpty) {
            inputController.insertText(chunks[i],
                backSpaceLength: isReplaced ? 0 : -1);
            isReplaced = true;
          }

          if (i < chunks.length - 1) {
            final match = atList[i].group(0);
            if (match.startsWith(r"${@")) {
              final id = match.substring(4, match.length - 1);
              String name;
              if (match[3] == "!") {
                name = Db.userInfoBox.get(id)?.showName(guildId: guildId) ?? "";
              } else {
                final gp = PermissionModel.getPermission(guildId);
                name = gp.roles
                        .firstWhere((element) => element.id == id,
                            orElse: () => null)
                        ?.name ??
                    "";
              }
              inputController.insertAt(name,
                  data: match,
                  textStyle: TextStyle(color: primaryColor, fontSize: 17),
                  backSpaceLength: isReplaced ? 0 : -1);
              isReplaced = true;
            } else if (match.startsWith(r"${#")) {
              final id = match.substring(3, match.length - 1);
              final channel = Db.channelBox.get(id);
              inputController.insertChannelName(channel?.name ?? '',
                  data: match,
                  textStyle: TextStyle(color: primaryColor, fontSize: 17),
                  backSpaceLength: isReplaced ? 0 : -1);
              isReplaced = true;
            }
          }
        }
      }

      if (UniversalPlatform.isIOS) {
        delay(doWork).unawaited;
      } else {
        doWork();
      }
    }
    if (requestFocus) textFieldFocusNode.requestFocus();
    if (reply != null) {
      _reply = reply;
      notifyListeners();
    }
  }
}
