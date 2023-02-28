import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/text_channel_controller.dart';
import 'package:im/pages/home/model/universal_rich_input_controller.dart';
import 'package:im/pages/home/view/bottom_bar/keyboard_container2.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/factory/abstract_rich_text_factory.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/rich_input_popup_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/pages/topic/controllers/topic_controller.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tun_editor/tun_editor_toolbar.dart';
import 'package:tuple/tuple.dart';

import '../../../../../icon_font.dart';
import '../../../../../loggers.dart';
import '../../../../../routes.dart';
import 'components/toolbar_io.dart';
import 'model/editor_model_tun.dart';

Future<bool> showRichInputPopup(
  BuildContext context, {
  // 回复的消息
  MessageEntity reply,
  // 撤回时的原消息
  MessageEntity originMessage,
  // 普通输入框controller
  UniversalRichInputController inputController,
  // 是否在话题详情页打开
  bool replyDetailPage = false,
  // 缓存的key
  @required String cacheKey,
}) {
  return Get.to(
    RichTunInputPop(
      reply: reply,
      originMessage: originMessage,
      inputController: inputController,
      replyDetailPage: replyDetailPage,
      cacheKey: cacheKey,
    ),
    transition: Transition.downToUp,
    fullscreenDialog: true,
  );
}

class RichTunInputPop extends RichInputPopupBase {
  // 重新编辑富文本消息需要传此参数
  final MessageEntity originMessage;

  // 是否是回复某条消息
  final MessageEntity reply;

  // 普通输入框controller
  final UniversalRichInputController inputController;

  // 是否在话题详情页打开
  final bool replyDetailPage;

  // 缓存的key值
  final String cacheKey;

  RichTunInputPop({
    this.originMessage,
    this.reply,
    this.inputController,
    this.replyDetailPage = false,
    @required this.cacheKey,
  });

  @override
  RichInputPopupBase richInputPopup(
      {MessageEntity<MessageContentEntity> originMessage,
      UniversalRichInputController inputController,
      MessageEntity<MessageContentEntity> reply,
      bool replyDetailPage,
      String cacheKey}) {
    return RichTunInputPop(
        originMessage: originMessage,
        reply: reply,
        inputController: inputController,
        replyDetailPage: replyDetailPage,
        cacheKey: cacheKey);
  }

  @override
  _RichTunInputPopState createState() => _RichTunInputPopState();
}

class _RichTunInputPopState extends State<RichTunInputPop> {
  InputRecord _inputRecord;
  bool _canAt = false;
  BehaviorSubject<String> _saveStream;
  RichTunEditorModel _model;
  String _cacheKey;
  BehaviorSubject<String> _showAtListStream;

  @override
  void initState() {
    _cacheKey = widget.cacheKey;

    if (_cacheKey != null)
      _inputRecord = Db.textFieldInputRecordBox.get(_cacheKey);

    if (TextChannelController.dmChannel != null &&
        TextChannelController.dmChannel.type == ChatChannelType.dm) {
      _canAt = false;
    } else {
      _canAt = true;
    }

    _saveStream = BehaviorSubject<String>()
      ..debounceTime(const Duration(milliseconds: 500)).listen((data) {
        _saveDoc();
      });
    _showAtListStream = BehaviorSubject<String>()
      ..debounceTime(const Duration(milliseconds: 200)).listen((data) {
        toolbarCallback.showAtList(context, _model, fromInput: true);
      });
    final map = _loadDocument();
    _saveStream.add('');
    _model = AbstractRichTextFactory.instance.createEditorModel(
      channel:
          TextChannelController.dmChannel ?? GlobalState.selectedChannel.value,
      needTitle: widget.reply == null,
      needDivider: widget.reply == null,
      titlePlaceholder: '无标题'.tr,
      editorPlaceholder: '写点什么...'.tr,
      defaultDoc: map['document'],
      defaultTitle: map['title'],
      toolbarItems: [
        if (_canAt) ToolbarMenu.at,
        ToolbarMenu.image,
        ToolbarMenu.emoji,

        // Text type.
        ToolbarMenu.textType,
        ToolbarMenu.textTypeHeadline1,
        ToolbarMenu.textTypeHeadline2,
        ToolbarMenu.textTypeHeadline3,
        ToolbarMenu.textTypeListBullet,
        ToolbarMenu.textTypeListOrdered,
        ToolbarMenu.textTypeDivider,
        ToolbarMenu.textTypeQuote,
        ToolbarMenu.textTypeCodeBlock,

        // Text style.
        ToolbarMenu.textStyle,
        ToolbarMenu.textStyleBold,
        ToolbarMenu.textStyleItalic,
        ToolbarMenu.textStyleUnderline,
        ToolbarMenu.textStyleStrikeThrough,

        ToolbarMenu.link,
      ],
      onSend: _sendDoc,
    );
    Get.put(_model);
    _model.editorController.document.changes.listen((event) {
      final _controller = _model.editorController;
      if (event.item3 == ChangeSource.REMOTE) return;
      _saveStream.add('');
      final changeList = event.item2.toList();
      bool isAt = false;
      bool isChannel = false;
      try {
        isAt = Document.fromDelta(event.item1)
            .collectStyle(max(_controller.selection.end, 0), 0)
            .containsKey(AtAttribute(null).key);
        isChannel = Document.fromDelta(event.item1)
            .collectStyle(max(_controller.selection.end, 0), 0)
            .containsKey(ChannelAttribute(null).key);
      } catch (e) {
        // logger.severe('富文本 collectStyle', e);
      }
      if (changeList.any((element) => element.isDelete) &&
          (isAt || isChannel)) {
        onDelete(event);
      } else if (changeList.any((element) => element.isInsert)) {
        onInsert(event);
      }
    });
    _model.titleController.addListener(() {
      _saveStream.add('');
    });
    // });
    super.initState();
  }

  @override
  void dispose() {
    _model.dispose();
    Get.delete<RichTunEditorModel>();
    _saveStream?.close();
    _showAtListStream?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildReplyInfo(),
            Expanded(
              child: AbstractRichTextFactory.instance.createRichEditor(_model),
            ),
            AbstractRichTextFactory.instance
                .createEditorToolbar(context, _model),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
        height: 38,
        alignment: Alignment.bottomRight,
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            _model.titleNativeController?.updateFocus(false);
            _model.tabIndex.value = null;
            _model.expand.value = KeyboardStatus.hide;
            Get.back();
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(0, 17, 24, 0),
            alignment: Alignment.bottomRight,
            height: 38,
            width: 68,
            child: Icon(IconFont.buffChatTextShrink,
                size: 18, color: CustomColor(context).disableColor),
          ),
        ));
  }

  Widget _buildReplyInfo() {
    if (widget.reply == null) return const SizedBox();
    final TextStyle textStyle = TextStyle(
        fontWeight: FontWeight.bold, color: CustomColor(context).disableColor);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 3, 16, 0),
      child: Row(
        children: [
          Text('回复 '.tr, style: textStyle),
//            // TODO breakWord 属性
          LimitedBox(
              maxWidth: 150,
              child: RealtimeNickname(
                userId: widget.reply.userId,
                style: textStyle,
                showNameRule: ShowNameRule.remarkAndGuild,
              )),

          Expanded(
            child: FutureBuilder(
                future: widget.reply.toNotificationString(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  return Text(
                    ": ${snapshot.data}".replaceAll("\n", " "),
                    style: textStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  );
                }),
          ),
        ],
      ),
    );
  }

  Map _loadDocument() {
    // 重新编辑撤回的消息
    if (widget.originMessage != null) {
      final entity = widget.originMessage.content as RichTextEntity;
      return {
        'title': entity.title,
        'document': Document.fromDelta(entity.document.toDelta()),
      };
    }
    final defaultDoc = Document.fromJson(jsonDecode(r'[{"insert":"\n"}]'));
    Map richContent;
    try {
      richContent = jsonDecode(_inputRecord?.richContent);
    } catch (e) {
      // logger.severe('富文本加载失败', e);
    }
    if (richContent == null) {
      // 获取普通输入框文本
      final inputDoc = _generateDocFromInput(widget.inputController);
      // 获取普通输入框的内容不为空，则填充到富文本，然后需空普通输入框内容
      if (inputDoc != null) {
        unawaited(delay(() {
          widget?.inputController?.clear();
        }));
      }
      return {
        'title': '',
        'document': inputDoc ?? defaultDoc,
      };
    }
    // 否则获取富文本缓存
    return {
      'title': richContent['title'] ?? '',
      'document': richContent['document'] != null
          ? Document.fromJson(richContent['document'])
          : defaultDoc
    };
  }

  void _saveDoc() {
    final _controller = _model.editorController;
    final _titleController = _model.titleController;
    if (_cacheKey == null || _controller == null) return;
    final isEmptyDoc = _controller.document.isContentEmpty &&
        _titleController.text.trim().isEmpty;
    if (!widget.replyDetailPage) {
      final inputRecord = Db.textFieldInputRecordBox.get(_cacheKey);
      if (isEmptyDoc && !isNotNullAndEmpty(inputRecord?.content)) {
        Db.textFieldInputRecordBox.delete(_cacheKey);
      } else {
        Db.textFieldInputRecordBox.put(
          _cacheKey,
          InputRecord(
            replyId: widget.reply?.messageId,
            content: inputRecord?.content,
            richContent: isEmptyDoc
                ? null
                : jsonEncode({
                    'title': _titleController.text.trim(),
                    'document': _controller.document.toDelta(),
                  }),
          ),
        );
      }
    } else {
      final inputRecord = TopicController.getInputCache(_cacheKey);
      if (isEmptyDoc && !isNotNullAndEmpty(inputRecord?.content)) {
        TopicController.removeInputCache(_cacheKey);
      } else {
        final newer = InputRecord(
          replyId: widget.reply?.messageId,
          content: inputRecord?.content,
          richContent: isEmptyDoc
              ? null
              : jsonEncode({
                  'title': _titleController.text.trim(),
                  'document': _controller.document.toDelta(),
                }),
        );
        TopicController.updateInputCache(_cacheKey, newer);
        Db.textFieldInputRecordBox.put(_cacheKey, newer);
      }
    }
  }

  void onDelete(Tuple3<Delta, Delta, ChangeSource> event) {
    final _controller = _model.editorController;

    final changeList = event.item2.toList();
    final delPosition = changeList.first.length;
    final int oIndex =
        RichEditorUtils.getOperationIndex(event.item1, delPosition);
    final lenBeforeOperation =
        RichEditorUtils.getLenBeforeOperation(event.item1, oIndex);
    if (oIndex != -1) {
      final Delta change = Delta()
        ..retain(lenBeforeOperation)
        ..delete(event.item1.elementAt(oIndex).length - 1);
      final nextOperation =
          RichEditorUtils.getNextOperation(event.item1, oIndex);
      // 是否嵌入节点
      final isEmbedObject = nextOperation != null && nextOperation.isEmbed;
      final isLast = RichEditorUtils.isLastOperation(event.item1, oIndex);
      // 特殊情况需插入换行符
      if (isLast || isEmbedObject) {
        change.insert('\n');
      }
      _controller.document.compose(change, ChangeSource.REMOTE);
      _controller.updateSelection(
          TextSelection.collapsed(offset: lenBeforeOperation),
          ChangeSource.REMOTE);
    }
  }

  void onInsert(Tuple3<Delta, Delta, ChangeSource> event) {
    final changeList = event.item2.toList();
    // final after = _controller.document.toDelta();
    // final oIndex =
    //     RichEditorUtils.getOperationIndex(after, _controller.selection.end - 1);
    // if (oIndex == -1) return;
    // 在@和#中间插入字符
    // final current = after.elementAt(oIndex);
    // if (current.isAt || current.isChannel) {
    //   final start = RichEditorUtils.getLenBeforeOperation(after, oIndex);
    //   _controller.formatText(start, after.elementAt(oIndex).length,
    //       current.isAt ? AtAttribute(null) : ChannelAttribute(null));
    //   return;
    // }
    final o = changeList.firstWhere((element) => element.isInsert,
        orElse: () => null);
    if (o?.value == '@') {
      if (!_canAt) return;
      _showAtListStream.add('');
    } else if (o?.value == '#' && !GlobalState.isDmChannel) {
      _showChannelList(context, _model);
    }
  }

  Future<void> _sendDoc() async {
    try {
      logger.info('sendDoc...');
      logger.info(_model.editorController.document.toDelta().toJson());
      final _controller = _model.editorController;
      final _titleController = _model.titleController;
      final tempDoc = Document.fromDelta(_controller.document.toDelta());
      final deltaList = tempDoc.toDelta().toList();
      final str = tempDoc.toPlainText().replaceAll(RegExp(r"\n+| |\u200B"), '');
      if (deltaList.where((element) => element.isEmbed).length >
          _model.maxMediaNum) {
        showToast('最多只能发${_model.maxMediaNum}个文件');
        return;
      }
      if (str.runes.length > 5000) {
        showToast('内容长度超出限制'.tr);
        return;
      }
      Loading.show(context);
      FocusScope.of(context).unfocus();
      _model.titleNativeController?.updateFocus(false);
      final title = _titleController.text.trim();
      await RichEditorUtils.uploadFileInDoc(tempDoc, title: title);
      String curChannelId;
      if (GlobalState.isDmChannel) {
        curChannelId = TextChannelController.dmChannel.id;
      } else {
        curChannelId = GlobalState.selectedChannel.value?.id;
      }
      final inputModel = TextChannelController.to(
          channelId: widget.reply?.channelId ?? curChannelId);

      inputModel.jumpToBottom();
      unawaited(_saveStream?.close());
      await inputModel.sendContent(
        RichTextEntity(
            title: title,
            document: Document.fromJson(tempDoc.toDelta().toJson())),
        reply: widget.reply,
      );
      if (_cacheKey != null) {
        final inputRecordText = _inputRecord?.content;
        if (!isNotNullAndEmpty(inputRecordText)) {
          if (widget.replyDetailPage) {
            TopicController.removeInputCache(_cacheKey);
          }
          unawaited(Db.textFieldInputRecordBox.delete(_cacheKey));
          if (widget.reply != null) {
            unawaited(
                Db.textFieldInputRecordBox.delete(widget.reply.messageId));
          }
          widget?.inputController?.clear();
        } else {
          unawaited(Db.textFieldInputRecordBox.put(
              _cacheKey,
              InputRecord(
                replyId: _inputRecord.replyId,
                content: inputRecordText,
              )));
        }
      }
      // 发送成功返回true
      Routes.pop(context, true);
    } catch (e, s) {
      logger.severe('富文本发送失败', e, s);
    } finally {
      Loading.hide();
    }
  }
}

// 从聊天输入框生成富文本需要的doc，填充到富文本
Document _generateDocFromInput(UniversalRichInputController controller) {
  final data = controller?.data;
  if (data == null || data.trim().isEmpty) return null;
  final List<Tuple3<int, int, String>> atUserList = [];
  final List<Tuple3<int, int, String>> atRoleList = [];
  final List<Tuple3<int, int, String>> channelList = [];
  final atMatches = TextEntity.atPattern.allMatches(data);
  final channelMatches = TextEntity.channelLinkPattern.allMatches(data);
  for (final i in atMatches) {
    final isRole = i.group(1) == '&';
    if (isRole) {
      atRoleList.add(Tuple3(i.start, i.end, i.group(2)));
    } else {
      atUserList.add(Tuple3(i.start, i.end, i.group(2)));
    }
  }
  for (final i in channelMatches) {
    channelList.add(Tuple3(i.start, i.end, i.group(1)));
  }
  final tempList = [...atUserList, ...atRoleList, ...channelList]
    ..sort((a, b) => a.item1.compareTo(b.item1));
  final delta = Delta();
  // 没包含@、#的情况
  if (tempList.isEmpty) {
    delta.insert(data);
  }
  for (var i = 0; i < tempList.length; i++) {
    final e = tempList[i];
    int start;
    int end;
    if (tempList.first == e) {
      start = 0;
      end = e.item1;
    } else {
      start = tempList[i - 1].item2;
      end = e.item1;
    }
    // 插入普通字符串
    final str = data.substring(start, end);
    if (str.trim().isNotEmpty) {
      delta.insert(str);
    }
    // 插入特殊字符 @、#
    final id = e.item3;
    if (atRoleList.contains(e)) {
      final role = PermissionModel.getPermission(
              ChatTargetsModel.instance.selectedChatTarget.id)
          .roles
          .firstWhere((element) => element.id == id, orElse: () => null);
      if (role != null)
        delta.insert('@${role.name}', {'at': TextEntity.getAtString(id, true)});
    }
    if (atUserList.contains(e)) {
      final user = Db.userInfoBox.get(id);
      if (user != null)
        delta.insert(
            '@${user.nickname}', {'at': TextEntity.getAtString(id, false)});
    }
    if (channelList.contains(e)) {
      final channel = Db.channelBox.get(id);
      if (channel != null)
        delta.insert('@${channel.name}',
            {'channel': TextEntity.getChannelLinkString(id)});
    }
    delta.insert(' ');
    // 插入结尾的字符
    if (tempList.last == e) {
      delta.insert(data.substring(e.item2, data.length));
    }
  }
  // 文档须已换行结尾
  delta.insert('\n');
  return Document.fromDelta(delta);
}

Future<void> _showChannelList(
    BuildContext context, RichTunEditorModel model) async {
  model.tabIndex.value = null;
  model.expand.value = KeyboardStatus.hide;

  final controller = model.editorController;
  final ChatChannel channel =
      await Routes.pushRichEditorChannelListPage(context);
  if (channel == null) {
    // model.editorFocusNode.requestFocus();
    return;
  }
  // final d1 = Delta()aw
  //   ..retain(controller.selection.end - 1)
  //   ..delete(1);
  // controller.compose(d1, controller.selection, ChangeSource.REMOTE);
  // }
  final String channelId = TextEntity.getChannelLinkString(channel.id);
  final String channelMark = '#${channel.name}';
  controller.insertMention(channelId, channelMark,
      prefixChar: '#', replaceLength: 1);
  controller.insert(
    controller.selection.end,
    ' ',
  );
  // final start = controller.selection.end;
  // final offset = start + channelMark.length;
  // final isEmbed = RichEditorUtils.isEmbedEnd(
  //     controller.document.toDelta(), controller.selection.end);
  // final d = Delta()..retain(controller.selection.end);
  // if (isEmbed) d.insert('\n');
  // d.insert(channelMark, {'channel': channelId});
  // controller
  //   ..document.compose(d, ChangeSource.REMOTE)
  //   ..updateSelection(
  //       TextSelection.collapsed(offset: offset + (isEmbed ? 1 : 0)),
  //       ChangeSource.LOCAL);
  // // 插入空格
  // controller
  //   ..document.insert(controller.selection.end, ' ')
  //   ..updateSelection(
  //       TextSelection.collapsed(offset: controller.selection.end + 1),
  //       ChangeSource.LOCAL);
  // // 切换普通样式
  // controller.formatText(
  //     controller.selection.end - 1, 1, ChannelAttribute(null));
}
