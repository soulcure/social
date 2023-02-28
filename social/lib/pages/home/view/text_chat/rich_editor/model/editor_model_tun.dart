import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/pages/circle/content/circle_post_image_item.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/bottom_bar/keyboard_container2.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/factory/abstract_rich_text_factory.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model_base.dart';
import 'package:im/routes.dart';
import 'package:im/utils/texture_overlap_notifier.dart';
import 'package:im/utils/utils.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:native_text_field/native_text_field.dart';
import 'package:oktoast/oktoast.dart';
import 'package:rich_input/rich_input.dart';
import 'package:tun_editor/controller.dart';
import 'package:tun_editor/tun_editor_toolbar.dart';

//移动端富文本数据模型，editor_model.dart拷贝过来，稍微修改的
class RichTunEditorModel extends RichEditorModelBase {
  final ChatChannel channel;
  // 是否需要显示标题文本框
  final bool needTitle;
  final bool needDivider;
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

  final List<CirclePostImageItem> assetList;
  bool get isImage {
    if (assetList.isEmpty) return true;
    return assetList.first.type == 'image';
  }

  // @提醒谁看中的提及的用户
  List<String> mentionList = [];
  // 正文中@的用户
  List<String> atList = [];

  TunEditorController _editorController;
  @override
  TunEditorController get editorController => _editorController;

  RichInputController _titleController;
  @override
  RichInputController get titleController => _titleController;

  NativeTextFieldController _titleNativeController;
  NativeTextFieldController get titleNativeController => _titleNativeController;

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

  final ValueNotifier<bool> _isEditMode = ValueNotifier(false);
  ValueNotifier<bool> get isEditMode => _isEditMode;

  final ValueNotifier<bool> _isContentEmpty = ValueNotifier(false);
  ValueNotifier<bool> get isContentEmpty => _isContentEmpty;

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

  static int resourceId = 101;
  static int atListId = 102;

  RichTunEditorModel({
    @required this.channel,
    this.needTitle = true,
    this.needDivider = false,
    this.defaultDoc,
    this.defaultTitle = '',
    this.titlePlaceholder = '',
    this.editorPlaceholder = '',
    this.titleLength = 100,
    this.maxMediaNum = 50,
    this.onSend,
    this.showScrollbar = false,
    this.optionTopics = const [],
    this.toolbarItems = defaultToolbarMenu,
    this.assetList = const [],
    this.mentionList,
    this.atList,
  }) {
    TextureOverlapNotifier.instance.emit(TextureOverlapEvent(overlap: true));
    _scrollController = ScrollController();
    defaultDoc =
        defaultDoc ?? Document.fromJson(jsonDecode(r'[{"insert":"\n"}]'));
    _editorController = TunEditorController(
        document: defaultDoc,
        selection: const TextSelection.collapsed(offset: 0))
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
          // 是圈子发布页面
          Get.currentRoute;
          if (Get.currentRoute == richEditorAtListRoute) {
            _isEditMode.value = true;
          }
        }
      });

    if (needTitle) {
      _titleNativeController = NativeTextFieldController();
      _titleFocusNode = FocusNode()
        ..addListener(() {
          if (_titleFocusNode.hasFocus) {
            _expand.value = KeyboardStatus.input_keyboard;
            _tabIndex.value = null;
          }
        });
      _titleFocusNode.requestFocus();
    } else {
      delay(() {
        _editorController.updateSelection(
            TextSelection.collapsed(offset: _editorController.document.length),
            ChangeSource.LOCAL);
        _editorFocusNode.requestFocus();
      });
    }
    mentionList ??= [];
    atList ??= [];
    setSendButtonStatus();
    updateArticleUser();
  }

  @override
  RichEditorModelBase richEditorModel({
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
    return RichTunEditorModel(
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
    // _editorFocusNode?.dispose();
    _editorController?.dispose();
    _titleController?.dispose();
    _tabIndex.dispose();
    _expand.dispose();
    _isContentEmpty.dispose();
    _isEditorFocus.dispose();
    _canSend.dispose();
    _uploadCache.clear();
    TextureOverlapNotifier.instance.emit(TextureOverlapEvent());
    super.dispose();
  }

  Future<void> requestMediaData() async {
    for (final CirclePostImageItem mediaItem in assetList) {
      if ((mediaItem?.identifier?.isEmpty ?? true) ||
          (mediaItem?.url?.isNotEmpty ?? false)) {
        continue;
      }
      try {
        final list = await MultiImagePicker.requestMediaData(
            thumb: false, selectedAssets: [mediaItem.identifier]);
        list.forEach((element) {
          mediaItem.name = element.name;
          mediaItem.thumbName = element.thumbName;
          mediaItem.checkPath = element.checkPath ?? '';
          mediaItem.identifier = element.identifier ?? '';
          mediaItem.url = element.filePath;
          mediaItem.thumbUrl = element.thumbFilePath;
          mediaItem.type =
              (element.fileType.contains('video')) ? 'video' : 'image';
          mediaItem.width = element.originalWidth;
          mediaItem.height = element.originalHeight;
          mediaItem.duration = element?.duration ?? 0;
        });
      } catch (e) {
        showToast("加载失败，请重试".tr);
      }
    }
  }

  Future<void> setSendButtonStatus() async {
    final isContentEmpty = _editorController?.document?.isContentEmpty;
    _canSend.value = !(isContentEmpty ?? true);
    _isContentEmpty.value = _editorController?.document?.toPlainText() != '\n';
  }

  void addUploadCache(String key, List<String> urls) {
    if (key == null || urls == null) return;
    _uploadCache[key] = urls;
  }

  @override
  List<String> getUploadCache(String key) {
    return _uploadCache[key];
  }

  Future<void> uploadFile() async {
    await requestMediaData();
    for (final item in assetList) {
      if (item.isAdd == false) {
        await item.upload();
      }
    }
  }

  String getContent({bool forSave = true}) {
    final List<Map<String, dynamic>> contents = editorController?.document
        ?.toDelta()
        ?.toJson()
        ?.map((e) => Map<String, dynamic>.from(e))
        ?.toList();
    if (contents.isEmpty && assetList.isEmpty) {
      return '';
    }

    // 添加@列表到content里面
    if (mentionList.isNotEmpty && forSave) {
      contents.add({"mentions": mentionList});
    }

    for (final item in assetList) {
      if (item.isAdd == false) {
        contents.add({"insert": item.toJson()});
      }
    }

    contents.add({"insert": "\n"});
    final String contentStr = json.encode(contents);
    return contentStr;
  }

  Future<void> pickImages() async {
    /// 检测相册权限
    final hasPermission = await checkPhotoAlbumPermissions();

    /// 未授权
    if (hasPermission != true) return;

    if (assetList.isEmpty || assetList.first?.type == 'image') {
      if (assetList.length >= 9) return;

      final max = 9 - assetList.length;

      final List<CirclePostImageItem> selectList = await AbstractRichTextFactory
          .instance
          .pickImages(max, assetList.map((e) => e.identifier).toList());
      print('selectList $selectList');
      if (selectList.isNotEmpty) {
        assetList.clear();
        assetList.addAll(selectList);
      }
    } else {
      /// 处理video
      if (assetList.length > 1) return;
    }

    await getMediaThumb(isUpdate: false);

    ///更新UI
    unawaited(setSendButtonStatus());
    // 图片更新id
    update([resourceId]);
    unawaited(requestMediaData());
  }

  Future<void> getMediaThumb({bool isUpdate = true}) async {
    for (final CirclePostImageItem mediaItem in assetList) {
      if ((mediaItem?.identifier?.isEmpty ?? true) ||
          (mediaItem?.url?.isNotEmpty ?? false) ||
          (mediaItem?.thumbData?.isNotEmpty ?? false)) {
        continue;
      }

      final thumbData =
          await MultiImagePicker.fetchMediaThumbData(mediaItem.identifier);
      mediaItem.thumbData = thumbData;
    }

    if (isUpdate) {
      update([resourceId]);
    }
  }

  void removeAssetItem(CirclePostImageItem item) {
    assetList.remove(item);
    update([resourceId]);
  }

  void swapAsset(int from, int to) {
    final item = assetList.removeAt(from);
    assetList.insert(to, item);
    update([resourceId]);
  }

  // 添加提及的@用户
  Future<void> appendMentionUser() async {
    tabIndex.value = null;
    expand.value = KeyboardStatus.hide;
    final List res = await Routes.pushRichEditorAtListPage(Get.context,
        channel: channel, guildId: channel.guildId);
    if (res == null || res.isEmpty) return;
    final user = res.first;
    if (mentionList.contains(user.userId)) return;
    mentionList.add(user.userId);
    update([atListId]);
  }

  // 更新正文中@用户
  void updateArticleUser() {
    final List<Operation> opts = editorController.document.toDelta().toList();
    final ids = opts.where((e) {
      final data = e.data;
      if (data is Map) {
        if (!data.keys.contains('mention')) return false;
        if (data['mention'] == null ||
            data['mention']['id'] == null ||
            data['mention']['prefixChar'] != '@') return false;
        return true;
      }
      return false;
    }).map((e) {
      final Map data = e.data;
      final id = data['mention']['id'];
      return id.substring(4, id.length - 1);
    }).toList();
    final setIds = Set.from(ids).cast<String>().toList();
    if (atList.join('-') != setIds.join('-')) {
      atList = setIds;
      update();
    }
  }

  // 最终展示的at列表
  List<String> get showAtList {
    final list = [...mentionList, ...atList];
    return Set<String>.from(list).toList();
  }

  void removeMention(String id) {
    mentionList.remove(id);
    update([atListId]);
  }
}
