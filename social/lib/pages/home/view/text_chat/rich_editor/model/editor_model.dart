import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill/widgets/controller.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/bottom_bar/keyboard_container2.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model_base.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:rich_input/rich_input.dart';
import 'package:tun_editor/tun_editor_toolbar.dart';

import '../utils.dart';

//移动端富文本数据模型，editor_model.dart拷贝过来，稍微修改的
class RichEditorModel extends RichEditorModelBase {
  final ChatChannel channel;
  // 是否需要显示标题文本框
  final bool needTitle;
  final String titlePlaceholder;
  final String editorPlaceholder;
  final int titleLength;
  @override
  final int maxMediaNum;
  final bool showScrollbar;

  // 发送回调
  final VoidCallback onSend;
  Document defaultDoc;
  final String defaultTitle;
  QuillController _editorController;
  @override
  QuillController get editorController => _editorController;
  RichInputController _titleController;

  @override
  RichInputController get titleController => _titleController;

  FocusNode _titleFocusNode;

  FocusNode get titleFocusNode => _titleFocusNode;

  FocusNode _editorFocusNode;

  FocusNode get editorFocusNode => _editorFocusNode;

  final ValueNotifier<ToolbarMenu> _tabIndex = ValueNotifier(null);

  ValueNotifier<ToolbarMenu> get tabIndex => _tabIndex;

  final ValueNotifier<KeyboardStatus> _expand =
      ValueNotifier(KeyboardStatus.hide);
  @override
  ValueNotifier<KeyboardStatus> get expand => _expand;

  final ValueNotifier<bool> _isEditorFocus = ValueNotifier(false);

  ValueNotifier<bool> get isEditorFocus => _isEditorFocus;

  final ValueNotifier<bool> _canSend = ValueNotifier(false);

  ValueNotifier<bool> get canSend => _canSend;

  // 缓存上传结果，图片只有一个url，视频有两个url，0：视频url，1：封面url
  final Map<String, List<String>> _uploadCache = <String, List<String>>{};

  Map<String, List<String>> get uploadCache => _uploadCache;

  final List<ToolbarMenu> toolbarItems;

  final List<CircleTopicDataModel> optionTopics;

  ScrollController _scrollController;

  ScrollController get scrollController => _scrollController;

  final TextStyle titleStyle;

  // final List<CircleTopicDataModel> selTopics;

  // 横屏参数
  Function closeEditor;

  Function closeAtList;

  Function closeChannelList;

  bool isAtFromInput = false;

  RichEditorModel({
    @required this.channel,
    this.needTitle = true,
    this.defaultDoc,
    this.defaultTitle = '',
    this.titlePlaceholder = '',
    this.editorPlaceholder = '',
    this.titleLength = 100,
    this.maxMediaNum = 50,
    this.titleStyle,
    // this.documentStyle,
    this.onSend,
    this.showScrollbar = false,
    this.optionTopics = const [],
    this.toolbarItems = const [
      ToolbarMenu.at,
      ToolbarMenu.image,
      ToolbarMenu.emoji
    ],
  }) {
    _scrollController = ScrollController();
    defaultDoc =
        defaultDoc ?? Document.fromJson(jsonDecode(r'[{"insert":"\n"}]'));

    _editorController = QuillController(
        document: defaultDoc,
        selection: const TextSelection(baseOffset: 0, extentOffset: 0))
      ..document.changes.listen((event) {
        setSendButtonStatus();
      });
    _titleController = RichInputController(text: defaultTitle);
    _editorFocusNode = FocusNode()
      ..addListener(() {
        _isEditorFocus.value = _editorFocusNode.hasFocus;
        if (_editorFocusNode.hasFocus) {
          _expand.value = KeyboardStatus.input_keyboard;
          _tabIndex.value = null;
        }
      });

    if (needTitle) {
      _titleFocusNode = FocusNode()
        ..addListener(() {
          if (_titleFocusNode.hasFocus) {
            _expand.value = KeyboardStatus.input_keyboard;
            _tabIndex.value = null;
          }
        })
        ..requestFocus();
    } else {
      _editorController.updateSelection(
          TextSelection.collapsed(offset: _editorController.document.length),
          ChangeSource.LOCAL);
      // delay(() {
      _editorFocusNode.requestFocus();
      // }, 100);
    }
    setSendButtonStatus();
  }

  @override
  RichEditorModelBase richEditorModel({
    ChatChannel channel,
    bool needTitle = true,
    Document defaultDoc,
    String defaultTitle = '',
    String titlePlaceholder = '',
    String editorPlaceholder = '',
    int titleLength = 100,
    int maxMediaNum = 50,
    VoidCallback onSend,
    bool showScrollbar = false,
    List<CircleTopicDataModel> optionTopics = const [],
    List toolbarItems = const [],
  }) {
    return RichEditorModel(
        channel: channel,
        needTitle: needTitle,
        defaultDoc: defaultDoc,
        defaultTitle: defaultTitle,
        titlePlaceholder: titlePlaceholder,
        editorPlaceholder: editorPlaceholder,
        titleLength: titleLength,
        maxMediaNum: maxMediaNum,
        onSend: onSend,
        showScrollbar: showScrollbar,
        optionTopics: optionTopics,
        toolbarItems: toolbarItems);
  }

  @override
  void dispose() {
    _titleFocusNode?.dispose();
    _editorFocusNode?.dispose();
    _editorController?.dispose();
    _titleController?.dispose();
    _tabIndex.dispose();
    _expand.dispose();
    _isEditorFocus.dispose();
    _canSend.dispose();
    _uploadCache.clear();
    closeEditor?.call(null);
    closeAtList?.call(null);
    closeChannelList?.call(null);
    // 横屏模式会自动销毁，所以不需销毁
    if (OrientationUtil.portrait) {
      super.dispose();
    }
  }

  Future<void> setSendButtonStatus() async {
    final isContentEmpty = _editorController?.document?.isContentEmpty ?? true;
    _canSend.value = !isContentEmpty;
    // _isContentEmpty.value = _editorController?.document?.toPlainText() != '\n';
  }

  void addUploadCache(String key, List<String> urls) {
    if (key == null || urls == null) return;
    _uploadCache[key] = urls;
  }

  @override
  List<String> getUploadCache(String key) {
    return _uploadCache[key];
  }

  void onSelectAt(List res) {
    // atListController.hide();
    final controller = editorController;
    if (res == null || res.isEmpty) {
      // model.editorFocusNode.requestFocus();
      return;
    }
    if (isAtFromInput) {
      final d = Delta()
        ..retain(controller.selection.end - 1)
        ..delete(1);
      controller.compose(d, controller.selection, ChangeSource.LOCAL);
      isAtFromInput = false;
    }
    res.forEach((e) {
      String atId = '';
      String atMark = '';
      if (e is Role) {
        atId = TextEntity.getAtString(e.id, true);
        atMark = '@${e.name}';
      } else if (e is UserInfo) {
        atId = TextEntity.getAtString(e.userId, false);
        atMark = '@${e.nickname}';
      }
      final start = controller.selection.end;
      final offset = start + atMark.length;
      final isEmbed = RichEditorUtils.isEmbedEnd(
          controller.document.toDelta(), controller.selection.end);
      final d = Delta()..retain(controller.selection.end);
      if (isEmbed) d.insert('\n');
      d.insert(atMark, {'at': atId});
      controller
        ..document.compose(d, ChangeSource.REMOTE)
        ..updateSelection(
            TextSelection.collapsed(offset: offset + (isEmbed ? 1 : 0)),
            ChangeSource.LOCAL);
    });
    // 插入空格
    controller
      ..document.insert(controller.selection.end, ' ')
      ..updateSelection(
          TextSelection.collapsed(offset: controller.selection.end + 1),
          ChangeSource.LOCAL);
    // 切换普通样式
    controller.formatText(controller.selection.end - 1, 1, AtAttribute(null));
  }

  void onSelectChannel(ChatChannel channel) {
    // channelListController.hide();
    if (channel == null) {
      // model.editorFocusNode.requestFocus();
      return;
    }
    final controller = editorController;
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
    // 插入空格
    controller
      ..document.insert(controller.selection.end, ' ')
      ..updateSelection(
          TextSelection.collapsed(offset: controller.selection.end + 1),
          ChangeSource.LOCAL);
    // 切换普通样式
    controller.formatText(
        controller.selection.end - 1, 1, ChannelAttribute(null));
  }
}
