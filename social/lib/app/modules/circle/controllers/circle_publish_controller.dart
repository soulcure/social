import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/models/documents/attribute.dart';
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/modules/circle/views/widgets/circle_channel_list.dart';
import 'package:im/app/modules/circle/views/widgets/topics_popup.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/core/config.dart';
import 'package:im/db/db.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/circle/content/circle_post_image_item.dart';
import 'package:im/pages/guild_setting/role/role.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/universal_rich_input_controller.dart';
import 'package:im/pages/home/view/bottom_bar/keyboard_container2.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/factory/abstract_rich_text_factory.dart';
import 'package:im/routes.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/tc_doc_utils.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:native_text_field/native_text_field.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rich_input/rich_input.dart';
import 'package:rxdart/rxdart.dart';

import 'circle_controller.dart';
// typedef AtCallback = void Function(BuildContext context);

enum ToolbarIndex {
  none,
  at,
  image,
  emoji,
  channel,
}

const int maxImages = 9;

class CirclePublishController extends GetxController {
  //
  static int resourceId = 101;
  static int atListId = 102;
  String circleGridIdentifier = 'circleImageGrid';
  String circleDynamicToolbarIdentifier = 'circleDynamicToolbarIdentifier';
  String circleDynamicDocumentIdentifier = 'circleDynamicDocumentIdentifier';

  /// 页面状态
  final selectedTopicId = ''.obs;
  final needSaveToAlbum = false.obs;

  /// 业务数据
  final ChatChannel channel;
  final CirclePostInfoDataModel editedData;
  final String defaultTopicId;
  int beginEditTime; // 记录进入该页面时的时间戳
  List<CirclePostImageItem> assetList; // 图片/视频 资源显示

  /// at #
  Set<String> mentionList = {}; // @提醒谁看中的提及的用户
  Set<String> atList = {}; // 正文中@的用户
  Map<String, String> insertRichMap = {}; // # @ 的内容

  /// 文档
  DocItem docItem;

  /// 处理输入
  PublishSubject<String> _stream;
  int _textLength = 0;

  double videoThumbAspectRadio = 0;

  UniversalRichInputController get inputController =>
      _inputModel.inputController;

  FocusNode get textFieldFocusNode => _inputModel.textFieldFocusNode;

  ScrollController get scrollController => _inputModel.scrollController;
  NativeTextFieldController titleNativeController = NativeTextFieldController();
  FocusNode titleFocusNode = FocusNode();
  InputModel _inputModel;
  RichInputController titleController = RichInputController(text: ""); // 标题

  CirclePublishController({
    @required this.channel,
    this.editedData,
    List<CirclePostImageItem> assets,
    this.defaultTopicId,
  }) : assetList = assets ?? [];

  @override
  void onInit() {
    _inputModel = InputModel(
      channelId: channel.id,
      guildId: channel.guildId,
      type: ChatChannelType.guildCircle,
    );
    inputController.addListener(setSendButtonStatus);
    // 防抖处理
    _stream = PublishSubject();
    _inputModel.inputController.addListener(_onInput);
    _inputModel.textFieldFocusNode.addListener(_onInput);
    _stream
        .debounceTime(const Duration(milliseconds: 500))
        .listen(submitFilter);
    textFieldFocusNode.addListener(_onInputFocus);
    titleFocusNode.addListener(_onInputFocus);
    //
    beginEditTime = DateTime.now().millisecondsSinceEpoch;

    // 获取topicList
    getTopicList();

    requestMediaData();

    loadDocument();

    super.onInit();
    if (assetList.isNotEmpty && !isImage)
      updateVideoThumbAspectRatio(assetList.first.thumbName);
    setSendButtonStatus();
  }

  bool get isImage {
    if (assetList.isEmpty) return true;
    return assetList.first.type == 'image';
  }

  // 是否需要显示标题文本框

  final ValueNotifier<ToolbarIndex> _tabIndex = ValueNotifier(null);

  ValueNotifier<ToolbarIndex> get tabIndex => _tabIndex;

  final ValueNotifier<KeyboardStatus> _expand =
      ValueNotifier(KeyboardStatus.hide);

  ValueNotifier<KeyboardStatus> get expand => _expand;

  bool isEditorFocus = false;

  List<CircleTopicDataModel> _topicList;

  bool get isEnableImage {
    if (assetList.isEmpty) {
      return true;
    }

    final item = assetList.last;
    return item.isAdd;
  }

  void _onInput() {
    // web上光标停留在输入框，但是某些情况下inputModel.textFieldFocusNode.hasFocus会返回false
    if (!_inputModel.textFieldFocusNode.hasFocus && !kIsWeb) return;
    _stream.add(_inputModel.inputController.text);
  }

  Future<void> getTopicList() async {
    if (Get.isRegistered<CircleController>()) {
      _topicList = CircleController.to.circleTopicList;
    } else {
      final circleInfo =
          await CircleApi.circleInfo(channel.guildId, channel.id);
      final List topicList = circleInfo['topic'] ?? [];
      _topicList =
          topicList.map((e) => CircleTopicDataModel.fromJson(e)).toList();
    }
  }

  Future<void> submitFilter(String text) {
    if (_textLength < text.length) {
      final cursorPosition = _inputModel.inputController.selection.baseOffset;
      if (text[max(0, cursorPosition - 1)] == '@') {
        showTunAtList(Get.context, fromInput: true);
      }
      if (text[max(0, cursorPosition - 1)] == '#') {
        showTunChannelList(Get.context, fromInput: true);
      }
    }
    _textLength = text.length;
    return Future.value();
  }

  void _onInputFocus() {
    isEditorFocus = textFieldFocusNode.hasFocus || titleFocusNode.hasFocus;
    if (isEditorFocus) {
      _expand.value = KeyboardStatus.input_keyboard;
      _tabIndex.value = null;
    }

    update([circleDynamicToolbarIdentifier]);
  }

  void loadDocument() {
    // 编辑模式
    if (editedData != null) {
      selectedTopicId.value = editedData.topicId;
      titleController.text = editedData.title;
      docItem = editedData.docItem;
      setContent(editedData.content ?? '');
      return;
    }
    // 新增模式
    // 无缓存
    final circleDraft = Db.circleDraftBox.get(channel.id);
    if (circleDraft == null) {
      selectedTopicId.value = defaultTopicId;
      return;
    }
    // 有缓存
    String topicId = circleDraft.topicId ?? defaultTopicId;
    if (circleDraft.topicId != null) {
      final topicList = _topicList ?? [];
      topicId = topicList
          .firstWhere((element) => element.topicId == circleDraft.topicId,
              orElse: () => null)
          ?.topicId;
    }
    selectedTopicId.value = topicId;
    titleController.text = circleDraft.title;
    docItem = circleDraft.docItem;
    setContent(circleDraft.content ?? '');
  }

  Future<void> sendDynamicDoc() async {
    if (selectedTopicId.value.noValue) {
      showTopicPopup();
      return;
    }

    FocusScope.of(Get.context).unfocus();
    if (inputController.data.runes.length > 5000) {
      showToast('内容长度超出限制'.tr);
      return;
    }

    try {
      //将标题和内容，进行内容审核
      final titleAndContent =
          titleController.data.trim() + inputController.data.trim();
      if (titleAndContent.isNotEmpty) {
        const textChannel = TextChannelType.FB_CIRCLE_POST_TEXT;
        final textRes = await CheckUtil.startCheck(
            TextCheckItem(titleAndContent, textChannel,
                checkType: CheckType.circle),
            toastError: false);
        if (!textRes) {
          showToast(defaultErrorMessage);
          throw CheckTypeException(defaultErrorMessage);
        }
      }

      saveDoc();
      Get.back();
      if (editedData != null) Get.back();

      unawaited(CircleController.sendDynamic(
          timeMillis: beginEditTime,
          needSaveToAlbum: needSaveToAlbum.value,
          guildId: channel.guildId,
          channelId: channel.id));
    } catch (e, s) {
      logger.severe('圈子发送失败', e, s);
    } finally {}
  }

  bool get isEmptyDoc {
    return getContent().isEmpty && titleController.text.trim().isEmpty;
  }

  void saveDoc() {
    if (isEmptyDoc) {
      // 删除草稿
      for (final asset in assetList) {
        if (asset.requestId.hasValue) {
          MediaPicker.isDraftExist(requestId: asset.requestId).then((exist) {
            if (exist) MediaPicker.deleteDraft(requestId: asset.requestId);
          });
        }
      }
      Db.circleDraftBox.delete(channel.id);
    } else {
      final String titleText = titleController?.text?.trim() ?? '';
      //是否有加入文档
      final tcDoc = docItem != null ? json.encode(docItem?.toJson()) : '';
      Db.circleDraftBox.put(
        channel.id,
        CirclePostInfoDataModel(
          guildId: channel.guildId,
          channelId: channel.id,
          topicId: selectedTopicId.value,
          title: titleText,
          postType: isImage ? 'image' : 'video',
          content: isEmptyDoc ? null : getContent(),
          postId: editedData?.postId,
          tcDocContent: tcDoc,
        ),
      );
    }
  }

  void showTopicPopup() {
    _inputModel.textFieldFocusNode.unfocus();
    expand.value = KeyboardStatus.hide;
    _tabIndex.value = ToolbarIndex.none;
    final firstCustomTopic = _topicList.firstWhere(
        (e) => e.type == CircleTopicType.common,
        orElse: () => null);
    if (firstCustomTopic != null)
      showTopicListPopup(Get.context, _topicList);
    else
      showToast('暂无可选的频道'.tr);
  }

  Future<void> requestMediaData({bool isAdd = false}) async {
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

  void emoji() {
    textFieldFocusNode.unfocus();
    _expand.value = KeyboardStatus.extend_keyboard;
    _tabIndex.value = ToolbarIndex.emoji;
  }

  Future<void> insertTCDoc() async {
    docItem = await Routes.pushSelectDocument(channel.guildId);
    update([circleDynamicDocumentIdentifier, circleDynamicToolbarIdentifier]);
  }

  void removeTCDoc() {
    docItem = null;
    update([circleDynamicDocumentIdentifier, circleDynamicToolbarIdentifier]);
  }

  Future<void> editTCDoc() async {
    final docList = TcDocUtils.toDocPage(docItem.url);
    print(docList);
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
          .pickImages(max, assetList.map((e) => e.requestId).toList(),
              mediaSelectType: FBMediaSelectType.image);
      if (selectList.isNotEmpty) {
        assetList.addAll(selectList);
      }
    } else {
      /// 处理video
      if (assetList.length > 1) return;
    }

    await getMediaThumb(isUpdate: false);

    ///更新UI
    setSendButtonStatus();
    // 图片更新id
    update([resourceId]);
    unawaited(requestMediaData());
  }

  Future<void> pickVideoCover() async {
    final videoItem = assetList.first;
    final exist =
        await MediaPicker.isDraftExist(requestId: videoItem.requestId);
    if (!exist) return;
    final asset =
        await MediaPicker.pickVideoCover(requestId: videoItem.requestId);
    final imagePath = asset.thumbFilePath;

    videoItem.thumbName = imagePath;
    videoItem.customCover = true;
    unawaited(updateVideoThumbAspectRatio(imagePath));
  }

  ///解析视频封面缩略图决定显示比例
  Future<void> updateVideoThumbAspectRatio(String imageName) async {
    final image = await decodeImageFromList(
        File('${Global.deviceInfo.mediaDir}$imageName').readAsBytesSync());
    videoThumbAspectRadio = (image.width >= image.height) ? 1.33 : 0.75;
    update([resourceId]);
  }

  Future<void> previewVideo() async {
    final requestId = assetList.first?.requestId;
    if (requestId.noValue) return;
    final exist = await MediaPicker.isDraftExist(requestId: requestId);
    if (!exist) return;
    unawaited(MediaPicker.previewVideo(requestId: requestId));
  }

  Future<void> reEditorVideo() async {
    final requestId = assetList.first?.requestId;
    if (requestId.noValue) return;
    final exist = await MediaPicker.isDraftExist(requestId: requestId);
    if (!exist) return;
    unawaited(MediaPicker.reEditorMedia(requestId: requestId));
  }

  void setSendButtonStatus() {
    updateArticleUser();
    update([circleDynamicToolbarIdentifier]);
  }

  //发动态圈子，因为每次进来前都需要重新选择图片或视频，所以这里是空的
  List dynamicMediaList(List contentList) {
    final List mediaList = [];

    if (contentList.isNotEmpty) {
      for (final item in contentList) {
        final itemContent = item['insert'];
        if (itemContent is Map) {
          final type = itemContent['_type'] ?? '';
          if (type == 'image' || type == 'video') {
            mediaList.add(itemContent);
          }
        }
      }
    }

    return mediaList;
  }

  Future setTextContent(List textList, {bool requestFocus = false}) async {
    String textContent = '';
    for (final Map<String, dynamic> map in textList) {
      final insertV = map['insert'] ?? '';
      final attributeV = map['attributes'] ?? {};
      if (attributeV is Map && attributeV.isNotEmpty) {
        if (attributeV.keys.contains('at')) {
          final val = attributeV['at'];
          textContent = textContent + val;
          insertRichMap[val] = insertV;
        } else if (attributeV.keys.contains('channel')) {
          final val = attributeV['channel'];
          textContent = textContent + val;
          insertRichMap[val] = insertV;
        } else if (attributeV.keys.contains('link')) {
          final String val = attributeV['link']?.split('-')?.first ?? '';
          if (val.length < 2) continue;
          final channelId = val.substring(2);
          final match = '\${#$channelId}';
          textContent = textContent + match;
          insertRichMap[match] = insertV.substring(1);
        }
      } else if (insertV is String) {
        textContent = textContent + insertV;
      }
    }

    //去掉尾部换行符
    final text = textContent.replaceAll(RegExp(r"^\n+|\n+$"), "");
    final pattern = RegExp(r"\$\{.*?\}");
    final atList = pattern.allMatches(text).toList(growable: false);
    if (atList.isEmpty) {
      inputController.text = text ?? '';
    } else {
      void doWork() {
        inputController.clear();
        final chunks = text.split(RegExp(r"\$\{.*?\}"));
        for (int i = 0; i < chunks.length; i++) {
          if (chunks[i].isNotEmpty) {
            inputController.insertText(chunks[i]);
          }

          if (i < chunks.length - 1) {
            final match = atList[i].group(0);
            if (match.startsWith(r"${@")) {
              final id = match.substring(4, match.length - 1);
              if (id.isNotEmpty) {
                // _atSelectorModel.atList.add(id);
                // todo: _inputModel
              }
              String name;
              if (match[3] == "!") {
                name = Db.userInfoBox.get(id)?.showName(hideRemarkName: true) ??
                    "";
              } else {
                final gp = PermissionModel.getPermission(channel.guildId);
                name = gp.roles
                        .firstWhere((element) => element.id == id,
                            orElse: () => null)
                        ?.name ??
                    "";
              }
              inputController.insertAt(name,
                  data: match,
                  textStyle: TextStyle(color: primaryColor, fontSize: 17));
            } else if (match.startsWith(r"${#")) {
              inputController.insertChannelName(insertRichMap[match],
                  data: match,
                  textStyle: TextStyle(color: primaryColor, fontSize: 17));
            }
          }
        }
      }

      if (UniversalPlatform.isIOS) {
        unawaited(delay(doWork));
      } else {
        doWork();
      }
    }
    if (requestFocus) textFieldFocusNode.requestFocus();
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
      update([circleGridIdentifier]);
    }
  }

  void setContent(String content) {
    if (content.isEmpty) {
      return;
    }

    List contentList = [];
    try {
      contentList = json.decode(content);
    } catch (_) {}

    if (contentList.isEmpty) {
      return;
    }

    final textList = [];
    for (final Map map in contentList) {
      final saveAlbum = map['save_album'];
      if (saveAlbum != null) {
        needSaveToAlbum.value = saveAlbum;
        continue;
      }

      final dynamic insertV = map['insert'] ?? '';
      if (insertV is Map) {
        final Map insertMap = insertV;
        final type = insertMap['_type'] ?? '';
        if (type == 'image' || type == 'video') {
          continue;
        }
      }

      final dynamic attributes = map['attributes'] ?? '';
      if (attributes is Map) {
        if (attributes.containsKey('mentions')) {
          mentionList = Set.from(attributes['mentions']);
        }
      }

      textList.add(map);
    }

    setTextContent(textList);

    final List medias = dynamicMediaList(contentList);

    for (final Map itemJson in medias) {
      final imageItem = CirclePostImageItem.fromJson(itemJson);
      assetList.add(imageItem);
    }

    unawaited(getMediaThumb());

    setSendButtonStatus();
    update([circleGridIdentifier]);
  }

  Future<void> uploadFile() async {
    await requestMediaData();
    for (final item in assetList) {
      if (item.isAdd == false) {
        await item.upload();
      }
    }
  }

  String getContent() {
    final text = inputController.data;
    if (text.isEmpty && assetList.isEmpty) {
      return '';
    }

    final List contents = [];
    if (text.isEmpty) {
      // contents.add({"insert": ""});
    } else {
      text.splitMapJoin(RegExp(r"\$\{.*?\}"), onMatch: (m) {
        final matchStr = m.group(0);
        if (matchStr.length > 5) {
          final isChannel = matchStr[2] == '#';
          final channelId = matchStr.substring(3, matchStr.length - 1);
          if (_topicList.indexWhere((e) => e.topicId == channelId) < 0) {
            contents.add({
              "insert": insertRichMap[matchStr],
              "attributes": {isChannel ? "channel" : "at": matchStr}
            });
          } else {
            contents.add({
              "insert": '#${insertRichMap[matchStr]}',
              "attributes":
                  LinkAttribute('#T$channelId-${channel.guildId}').toJson()
            });
          }
        }
        return matchStr;
      }, onNonMatch: (n) {
        /// 兼容windows版本，当n为空时，插入一个空格，以保证windows的@能正常显示出来
        if (n.isNotEmpty) {
          contents.add({"insert": n});
        } else {
          contents.add({"insert": " "});
        }
        return n;
      });
    }

    // 添加@列表到content里面
    if (mentionList.isNotEmpty) {
      contents.add({
        "insert": "",
        "attributes": {"mentions": List.from(mentionList)}
      });
    }

    contents.add({"save_album": needSaveToAlbum.value});

    for (final item in assetList) {
      if (item.isAdd == false) {
        contents.add({"insert": item.toJson()});
      }
    }

    contents.add({"insert": "\n"});
    final String contentStr = json.encode(contents);
    return contentStr;
  }

  Future<void> editAssetItem(CirclePostImageItem item) async {
    if (editedData != null) return; // 编辑状态下不给编辑
    if (item.requestId.noValue) return;
    final exist = await MediaPicker.isDraftExist(requestId: item.requestId);
    if (!exist) return;
    final actions = [
      Text(
        '编辑',
        style: appThemeData.textTheme.bodyText2,
      ),
      Text(
        '删除',
        style: appThemeData.textTheme.bodyText2
            .copyWith(color: DefaultTheme.dangerColor),
      ),
    ];
    final actionIndex = await showCustomActionSheet(actions);

    if (actionIndex == 0) {
      final index = assetList.indexWhere((e) => e.requestId == item.requestId);
      if (index >= 0) {
        final res = await MediaPicker.reEditorMedia(requestId: item.requestId);

        /// 更新
        assetList[index] = CirclePostImageItem.fromAsset(res.first);
        update([resourceId]);
      }
    } else if (actionIndex == 1) {
      removeAssetItem(item);
    }
  }

  void removeAssetItem(CirclePostImageItem item) {
    if (assetList.length <= 1) {
      unawaited(showConfirmDialog(
        title: "至少需要发布一张照片".tr,
        confirmText: '',
        cancelText: '知道啦',
        cancelStyle: appThemeData.textTheme.bodyText2
            .copyWith(color: appThemeData.primaryColor),
        showCancelButton: false,
      ));
      return;
    }
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
    DLogManager.getInstance().customEvent(
        actionEventId: 'post_issue_click',
        actionEventSubId: 'click_post_issue_edit',
        actionEventSubParam: 'mention',
        extJson: {"guild_id": channel.guildId});

    tabIndex.value = ToolbarIndex.at;
    expand.value = KeyboardStatus.hide;
    final List res = await Routes.pushRichEditorAtListPage(Get.context,
        channel: channel, guildId: channel.guildId);
    if (res == null || res.isEmpty) return;
    final user = res.first;
    if (mentionList.contains(user.userId)) return;
    mentionList.add(user.userId);
    update([atListId]);
  }

  Future<void> showTunChannelList(BuildContext context,
      {bool fromInput = false}) async {
    DLogManager.getInstance().customEvent(
        actionEventId: 'post_issue_click',
        actionEventSubId: 'click_post_issue_edit',
        actionEventSubParam: 'chat_channel',
        extJson: {"guild_id": this.channel.guildId});

    _tabIndex.value = ToolbarIndex.channel;
    final ChatChannel channel =
        await showCircleChannelListDialog(context, _topicList);
    if (channel == null) {
      return;
    }
    final String channelId = TextEntity.getChannelLinkString(channel.id);
    final String channelMark = channel.name;
    if (!Config.useNativeInput && fromInput) {
      inputController.rawFlutterController.insertText('');
      final cursorPosition =
          inputController.rawFlutterController.selection.baseOffset;
      inputController.replaceRange(
        '',
        start: cursorPosition - 1,
        end: cursorPosition,
      );
    }
    insertRichMap[channelId] = channelMark;
    inputController.insertChannelName(channelMark,
        data: channelId, backSpaceLength: fromInput ? 1 : 0);
  }

  Future<void> showTunAtList(BuildContext context,
      {bool fromInput = false}) async {
    DLogManager.getInstance().customEvent(
        actionEventId: 'post_issue_click',
        actionEventSubId: 'click_post_issue_edit',
        actionEventSubParam: 'mention',
        extJson: {"guild_id": channel.guildId});

    _tabIndex.value = ToolbarIndex.at;
    final List res = await Routes.pushRichEditorAtListPage(context,
        channel: channel, guildId: channel.guildId);
    if (res == null || res.isEmpty) {
      return;
    }
    res.forEach((e) {
      String atId = '';
      String atMark = '';
      if (e is Role) {
        atId = TextEntity.getAtString(e.id, true);
        atMark = e.name;
      } else if (e is UserInfo) {
        atId = TextEntity.getAtString(e.userId, false);
        atMark = e.showName(guildId: channel.guildId);
      }

      if (!Config.useNativeInput && fromInput) {
        inputController.rawFlutterController.insertText('');
        final cursorPosition =
            inputController.rawFlutterController.selection.baseOffset;
        inputController.replaceRange(
          '',
          start: cursorPosition - 1,
          end: cursorPosition,
        );
      }
      insertRichMap[atId] = atMark;
      inputController.insertAt(atMark,
          data: atId, backSpaceLength: fromInput ? 1 : 0);
    });
  }

  // 更新正文中@用户
  void updateArticleUser() {
    final data = inputController.data;
    final Set<String> newAtSet = {};
    data.splitMapJoin(RegExp(r"\$\{.*?\}"), onMatch: (m) {
      final matchStr = m.group(0);
      if (matchStr.length > 5 && matchStr[2] == '@') {
        final val = matchStr.substring(4, matchStr.length - 1);
        newAtSet.add(val);
      }
      return matchStr;
    });

    final diff = atList.difference(newAtSet);
    if (atList.length != newAtSet.length || diff.isNotEmpty) {
      atList = newAtSet;
      update([atListId]);
    }
  }

  // 最终展示的at列表
  List<String> get showAtList {
    final ret = mentionList.union(atList);
    return ret.toList();
  }

  void removeMention(String id) {
    mentionList.remove(id);
    update([atListId]);
  }

  @override
  void onClose() {
    titleFocusNode.removeListener(_onInputFocus);
    titleController?.dispose();
    _tabIndex.dispose();
    _expand.dispose();
    _inputModel.dispose();
    super.onClose();
  }
}
