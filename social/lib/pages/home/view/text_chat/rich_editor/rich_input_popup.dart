import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill/widgets/default_styles.dart';
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
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/rich_input_popup_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/sub_page/channel_list.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/pages/topic/controllers/topic_controller.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/utils/show_rich_editor_tooltip.dart';
import 'package:im/widgets/button/primary_button.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sliding_sheet/sliding_sheet.dart';
import 'package:tun_editor/tun_editor_toolbar.dart';
import 'package:tuple/tuple.dart';

import '../../../../../global.dart';
import '../../../../../icon_font.dart';
import '../../../../../loggers.dart';
import '../../../../../routes.dart';
import 'components/toolbar_io.dart';

Future<bool> showRichInputPopup(
  BuildContext context, {
  double maxWidth = double.infinity,
  // ???????????????
  MessageEntity reply,
  // ?????????????????????
  MessageEntity originMessage,
  // ???????????????controller
  UniversalRichInputController inputController,
  // ??????????????????????????????
  bool replyDetailPage = false,
  // ?????????key
  @required String cacheKey,
}) async {
  if (OrientationUtil.portrait) {
    return Get.to(
      RichInputPop(
        reply: reply,
        originMessage: originMessage,
        inputController: inputController,
        replyDetailPage: replyDetailPage,
        cacheKey: cacheKey,
      ),
    );
  } else {
    final res = await showSlidingBottomSheet(
        context ?? Global.navigatorKey.currentContext,
        resizeToAvoidBottomInset: false, builder: (context) {
      return SlidingSheetDialog(
        maxWidth: maxWidth,
        elevation: 8,
        cornerRadius: 12,
        padding: EdgeInsets.zero,
        duration: const Duration(milliseconds: 300),
        scrollSpec: const ScrollSpec(physics: ClampingScrollPhysics()),
        avoidStatusBar: true,
        snapSpec: const SnapSpec(snappings: [0.96]),
        builder: (context, state) {
          return Material(
              child: SizedBox(
            height: Global.mediaInfo.size.height * 0.95,
            child: RichInputPop(
              reply: reply,
              originMessage: originMessage,
              inputController: inputController,
              replyDetailPage: replyDetailPage,
              cacheKey: cacheKey,
            ),
          ));
        },
      );
    });
    return res;
  }
}

class RichInputPop extends RichInputPopupBase {
  // ?????????????????????????????????????????????
  final MessageEntity originMessage;

  // ???????????????????????????
  final MessageEntity reply;

  // ???????????????controller
  final UniversalRichInputController inputController;

  // ??????????????????????????????
  final bool replyDetailPage;

  // ?????????key???
  final String cacheKey;

  // ????????????
  final Function(Document) onChange;

  // ????????????
  final Function(bool) onClose;

  final TextStyle titleStyle;

  final DefaultStyles documentStyle;

  RichInputPop({
    this.originMessage,
    this.reply,
    this.inputController,
    this.replyDetailPage = false,
    @required this.cacheKey,
    this.onChange,
    this.onClose,
    this.titleStyle,
    this.documentStyle,
  });

  @override
  RichInputPopupBase richInputPopup({
    MessageEntity<MessageContentEntity> originMessage,
    UniversalRichInputController inputController,
    MessageEntity<MessageContentEntity> reply,
    bool replyDetailPage,
    String cacheKey,
    Function(Document) onChange,
    Function onClose,
  }) {
    return RichInputPop(
      originMessage: originMessage,
      reply: reply,
      inputController: inputController,
      replyDetailPage: replyDetailPage,
      cacheKey: cacheKey,
      onChange: onChange,
      titleStyle: titleStyle,
      documentStyle: documentStyle,
    );
  }

  @override
  _RichInputPopState createState() => _RichInputPopState();
}

class _RichInputPopState extends State<RichInputPop> {
  InputRecord _inputRecord;
  bool _canAt = false;
  BehaviorSubject<String> _saveStream;
  RichEditorModel _model;
  String _cacheKey;
  bool fromInput = false;
  @override
  void initState() {
    _cacheKey = widget.cacheKey;
    if (_cacheKey != null)
      _inputRecord = widget.replyDetailPage
          ? TopicController.getInputCache(_cacheKey)
          : Db.textFieldInputRecordBox.get(_cacheKey);

    if (OrientationUtil.portrait) {
      _canAt = TextChannelController.dmChannel?.type != ChatChannelType.dm;
    } else {
      _canAt = GlobalState.selectedChannel.value?.type != ChatChannelType.dm;
    }

    _saveStream = BehaviorSubject<String>();
    _saveStream.debounceTime(const Duration(milliseconds: 500)).listen((data) {
      _saveDoc();
    });

    // _loadDocument().then((map) {
    final map = _loadDocument();
    _saveStream.add('');
    // setState(() {
    final channel =
        TextChannelController.dmChannel ?? GlobalState.selectedChannel.value;
    _model = AbstractRichTextFactory.instance.createEditorModel(
      channel: channel,
      needTitle: widget.reply == null,
      titlePlaceholder: '?????????'.tr,
      editorPlaceholder: '????????????...'.tr,
      defaultDoc: map['document'],
      defaultTitle: map['title'],
      titleStyle: widget.titleStyle,
      documentStyle: widget.documentStyle,
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
        // logger.severe('????????? collectStyle', e);
      }
      if (changeList.any((element) => element.isDelete) &&
          (isAt || isChannel)) {
        onDelete(event);
      } else if (changeList.any((element) => element.isInsert)) {
        onInsert(event);
      }
      widget.onChange?.call(_model.editorController.document);
    });
    _model.titleController.addListener(() {
      _saveStream.add('');
    });
    // });
    // });
    super.initState();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).backgroundColor,
      child: Column(
        children: [
          _buildHeader(),
          _buildReplyInfo(),
          Expanded(
            child: AbstractRichTextFactory.instance.createRichEditor(_model),
          ),
          AbstractRichTextFactory.instance
              .createEditorToolbar(context, _model),
          Container(
            height: 64,
            alignment: Alignment.centerRight,
            color: Theme.of(context).backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ValueListenableBuilder(
              valueListenable: _model.canSend,
              builder: (context, canSend, child) {
                return PrimaryButton(
                  label: '??????',
                  height: 32,
                  borderRadius: 4,
                  textStyle: const TextStyle(fontSize: 14),
                  enabled: canSend,
                  disabledStyle: PrimaryButtonStyle(
                    text: Colors.white.withOpacity(0.49),
                    background:
                        Theme.of(context).primaryColor.withOpacity(0.49),
                  ),
                  onPressed: !canSend ? null : _sendDoc,
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _model.tabIndex.value = null;
        _model.expand.value = KeyboardStatus.hide;
      },
      child: Container(
          height: 38,
          padding: const EdgeInsets.fromLTRB(0, 17, 17, 0),
          alignment: Alignment.bottomRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 24,
              maxWidth: 24,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(IconFont.buffChatTextShrink,
                  size: 18, color: CustomColor(context).disableColor),
              onPressed: () {
                widget.onClose?.call(false);
                if (OrientationUtil.portrait) {
                  Routes.pop(context);
                } else {
                  widget.onClose?.call(false);
                }
              },
            ),
          )),
    );
  }

  Widget _buildReplyInfo() {
    if (widget.reply == null) return const SizedBox();
    final TextStyle textStyle = TextStyle(
        fontSize: OrientationUtil.portrait ? 14 : 16,
        fontWeight: FontWeight.bold,
        color: CustomColor(context).disableColor);
    return Padding(
      padding: OrientationUtil.portrait
          ? const EdgeInsets.fromLTRB(16, 3, 16, 0)
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Text('?????? '.tr, style: textStyle),
//            // TODO breakWord ??????
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
    // ???????????????????????????
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
      // logger.severe('?????????????????????', e);
    }
    if (richContent == null) {
      // ???????????????????????????
      final inputDoc = _generateDocFromInput(widget.inputController);
      // ???????????????????????????????????????????????????????????????????????????????????????????????????
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
    // ???????????????????????????
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
      // ??????????????????
      final isEmbedObject = nextOperation != null && nextOperation.isEmbed;
      final isLast = RichEditorUtils.isLastOperation(event.item1, oIndex);
      // ??????????????????????????????
      if (isLast || isEmbedObject) {
        change.insert('\n');
      }
      try {
        _controller.document.compose(change, ChangeSource.REMOTE);
      } catch (_) {}
      _controller.updateSelection(
          TextSelection.collapsed(offset: lenBeforeOperation),
          ChangeSource.REMOTE);
    }
  }

  Future<void> onInsert(Tuple3<Delta, Delta, ChangeSource> event) async {
    final _controller = _model.editorController;

    final changeList = event.item2.toList();
    final after = _controller.document.toDelta();
    final oIndex =
        RichEditorUtils.getOperationIndex(after, _controller.selection.end - 1);
    if (oIndex == -1) return;
    // ???@???#??????????????????
    final current = after.elementAt(oIndex);
    if (current.isAt || current.isChannel) {
      final start = RichEditorUtils.getLenBeforeOperation(after, oIndex);
      _controller.formatText(start, after.elementAt(oIndex).length,
          current.isAt ? AtAttribute(null) : ChannelAttribute(null));
      return;
    }
    final o = changeList.firstWhere((element) => element.isInsert,
        orElse: () => null);
    if (o?.value == '@') {
      if (!_canAt) return;
      fromInput = true;
      await toolbarCallback.showAtList(context, _model, fromInput: true);
    } else if (o?.value == '#' && !GlobalState.isDmChannel) {
      if (OrientationUtil.portrait) {
        await _showChannelList(context, _model);
      } else {
        await showWebRichEditorTooltip<bool>(context, builder: (c, done) {
          _model.closeChannelList = done;
          return SizedBox(
              height: 500,
              child: RichEditorChannelListPage(
                onSelect: (channel) {
                  _model.onSelectChannel(channel);
                  done(true);
                },
                onClose: () => done(false),
              ));
        });
      }
    }
  }

  Future<void> _sendDoc() async {
    try {
      final _controller = _model.editorController;
      final _titleController = _model.titleController;
      final deltaList = _controller.document.toDelta().toList();
      final str = _controller.document
          .toPlainText()
          .replaceAll(RegExp(r"\n+| |\u200B"), '');
      if (deltaList.where((element) => element.isEmbed).length >
          _model.maxMediaNum) {
        showToast('???????????????%s?????????'.trArgs([_model.maxMediaNum.toString()]));
        return;
      }
      if (str.runes.length > 5000) {
        showToast('????????????????????????'.tr);
        return;
      }
      Loading.show(context);
      FocusScope.of(context).unfocus();
      final title = _titleController.text.trim();
      // ?????????????????????????????????????????????????????????
      if (UniversalPlatform.isMobileDevice) {
        await RichEditorUtils.uploadFileInDoc(_controller.document,
            title: title);
      }
      // printDoc();
      String curChannelId;
      if (GlobalState.isDmChannel) {
        curChannelId = TextChannelController.dmChannel?.id;
      } else {
        curChannelId = GlobalState.selectedChannel.value?.id;
      }
      final inputModel = TextChannelController.to(
          channelId: widget.reply?.channelId ?? curChannelId);

      inputModel.jumpToBottom();
      await inputModel.sendContent(
          RichTextEntity(
              title: title,
              document: Document.fromDelta(_controller.document.toDelta())),
          reply: widget.reply);
      // ????????????????????????????????????????????? saveDoc??????
      _controller
        ..document.replace(0, _controller.document.length - 1, '')
        ..updateSelection(
            const TextSelection.collapsed(offset: 0), ChangeSource.REMOTE);
      _titleController.clear();
      if (_cacheKey != null) {
        final inputRecordText = _inputRecord?.content;
        if (!isNotNullAndEmpty(inputRecordText)) {
          unawaited(Db.textFieldInputRecordBox.delete(_cacheKey));
        } else {
          unawaited(Db.textFieldInputRecordBox.put(
              _cacheKey,
              InputRecord(
                replyId: _inputRecord.replyId,
                content: inputRecordText,
              )));
        }
      }

      if (widget.onClose == null) {
        Routes.pop(context, true);
      } else {
        widget.onClose?.call(true);
      }
    } catch (e) {
      logger.severe('?????????????????????', e);
    } finally {
      Loading.hide();
    }
  }
}

// ??????????????????????????????????????????doc?????????????????????
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
  // ?????????@???#?????????
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
    // ?????????????????????
    final str = data.substring(start, end);
    if (str.trim().isNotEmpty) {
      delta.insert(str);
    }
    // ?????????????????? @???#
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
    // ?????????????????????
    if (tempList.last == e) {
      delta.insert(data.substring(e.item2, data.length));
    }
  }
  // ????????????????????????
  delta.insert('\n');
  return Document.fromDelta(delta);
}

Future<void> _showChannelList(
    BuildContext context, RichEditorModel model) async {
  FocusScope.of(context).unfocus();
  model.tabIndex.value = null;
  model.expand.value = KeyboardStatus.hide;

  final controller = model.editorController;
  final ChatChannel channel =
      await Routes.pushRichEditorChannelListPage(context);
  if (channel == null) {
    // model.editorFocusNode.requestFocus();
    return;
  }
  final d1 = Delta()
    ..retain(controller.selection.end - 1)
    ..delete(1);
  controller.compose(d1, controller.selection, ChangeSource.REMOTE);
  // }
  final String channelId = TextEntity.getChannelLinkString(channel.id);
  final String channelMark = '#${channel.name}';
  final start = controller.selection.end;
  final offset = start + channelMark.length;
  final isEmbed = RichEditorUtils.isEmbedEnd(
      controller.document.toDelta(), controller.selection.end);
  final d = Delta()..retain(controller.selection.end);
  if (isEmbed) d.insert('\n');
  d.insert(channelMark, {'channel': channelId});
  controller
    ..document.compose(d, ChangeSource.REMOTE)
    ..updateSelection(
        TextSelection.collapsed(offset: offset + (isEmbed ? 1 : 0)),
        ChangeSource.LOCAL);
  // ????????????
  controller
    ..document.insert(controller.selection.end, ' ')
    ..updateSelection(
        TextSelection.collapsed(offset: controller.selection.end + 1),
        ChangeSource.LOCAL);
  // ??????????????????
  controller.formatText(
      controller.selection.end - 1, 1, ChannelAttribute(null));
}
