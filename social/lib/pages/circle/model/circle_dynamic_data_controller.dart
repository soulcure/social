import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/db/db.dart';
import 'package:im/pages/circle/circle_post_entity.dart';
import 'package:im/pages/circle/content/circle_post_image_item.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/input_prompt/dynamic_at_model.dart';
import 'package:im/pages/home/model/universal_rich_input_controller.dart';
import 'package:im/pages/home/view/bottom_bar/keyboard_container2.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/factory/abstract_rich_text_factory.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:native_text_field/native_text_field.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rich_input/rich_input.dart';

// typedef AtCallback = void Function(BuildContext context);

enum ToolbarIndex {
  none,
  at,
  image,
  emoji,
}

class CircleDynamicDataController extends GetxController {
  final ChatChannel channel;
  CirclePostType circleType;
  int maxImages;
  final List<CirclePostImageItem> _assetList;

  //标题
  RichInputController titleController = RichInputController(text: "");

  // 是否需要显示标题文本框
  bool needTitle = true;
  String titlePlaceholder = '填写标题可能会获得很多赞哦~';
  NativeTextFieldController titleNativeController = NativeTextFieldController();
  FocusNode titleFocusNode = FocusNode();

  VoidCallback onSend;

  // AtCallback atAction;

  final ValueNotifier<ToolbarIndex> _tabIndex = ValueNotifier(null);

  ValueNotifier<ToolbarIndex> get tabIndex => _tabIndex;

  final ValueNotifier<KeyboardStatus> _expand =
      ValueNotifier(KeyboardStatus.hide);

  ValueNotifier<KeyboardStatus> get expand => _expand;

  bool canSend = false;
  bool isEditorFocus = false;

  String lastString;

  InputModel _inputModel;

  DynamicAtModel _atSelectorModel;

  DynamicAtModel get atSelectorModel => _atSelectorModel;

  final bool _isLoading = false;

  bool get isLoading => _isLoading;

  bool get isEnableImage {
    if (assetList.isEmpty) {
      return true;
    }

    final item = assetList.last;
    return item.isAdd;
  }

  UniversalRichInputController get inputController =>
      _atSelectorModel.inputModel.inputController;

  FocusNode get textFieldFocusNode =>
      _atSelectorModel.inputModel.textFieldFocusNode;

  ScrollController get scrollController =>
      _atSelectorModel.inputModel.scrollController;

  CircleDynamicDataController({
    @required this.channel,
    this.maxImages = 0,
    this.circleType,
    List<CirclePostImageItem> assets,
    this.onSend,
  }) : _assetList = assets ?? [];

  String circleGridIdentifier = 'circleImageGrid';
  String circleDynamicToolbarIdentifier = 'circleDynamicToolbarIdentifier';

  @override
  void onInit() {
    _inputModel = InputModel(
      channelId: channel.id,
      guildId: channel.guildId,
      type: ChatChannelType.guildCircle,
    );
    _atSelectorModel = DynamicAtModel(_inputModel, channel);
    inputController.addListener(setSendButtonStatus);
    textFieldFocusNode.addListener(_onInputFocus);
    super.onInit();
    setSendButtonStatus();
  }

  void _onInputFocus() {
    isEditorFocus = textFieldFocusNode.hasFocus;
    if (isEditorFocus) {
      _expand.value = KeyboardStatus.input_keyboard;
      _tabIndex.value = null;
    }

    update([circleDynamicToolbarIdentifier]);
  }

  Future<void> requestMediaData({bool isAdd = false}) async {
    for (final CirclePostImageItem mediaItem in _assetList) {
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

  Future<void> pickImages({bool isAdd = false}) async {
    /// 检测相册权限
    final hasPermission = await checkPhotoAlbumPermissions();

    /// 未授权
    if (hasPermission != true) return;

    int max = 0;
    int selectImageNum = 0;
    if (isAdd == true) {
      _assetList?.forEach((element) {
        if (element.isAdd == false) {
          selectImageNum++;
        }
      });

      //当编辑页面删掉所有媒体后，可选9张图片 或 1个视频 两者可二选一（但不可以混选）
      if (selectImageNum == 0) {
        max = 9; //因为不确定用户第一张是选图片，还是 视频，所以这里将最大选择数置为 9；
      } else {
        max = maxImages - selectImageNum;
      }
    }

    final List<CirclePostImageItem> selectList =
        await AbstractRichTextFactory.instance.pickImages(max, []);
    _assetList.addAll(selectList);
    //当编辑页面删掉所有媒体后，可选9张图片 或 1个视频 两者可二选一 （相当于改变了圈子动态的类型）
    if (isAdd == true && _assetList.isNotEmpty) {
      final CirclePostImageItem item = _assetList.first;
      if (item.type.contains('image')) {
        maxImages = 9;
        circleType = CirclePostType.CirclePostTypeImage;
      } else if (item.type.contains('video')) {
        maxImages = 1;
        circleType = CirclePostType.CirclePostTypeVideo;
      }
    }

    await getMediaThumb(isUpdate: false);

    ///更新UI
    setSendButtonStatus();
    update([circleGridIdentifier]);
    if (isAdd == true) {
      unawaited(requestMediaData(isAdd: isAdd));
    }
  }

  List<CirclePostImageItem> get assetList {
    final List<CirclePostImageItem> assets = List.from(_assetList);

    if (assets.length >= maxImages) {
      return assets;
    }

    if (assets.isNotEmpty) {
      final item = assets.last;
      if (item.isAdd == false) {
        final item = CirclePostImageItem(isAdd: true);
        assets.add(item);
      }
    }

    return assets;
  }

  void insertAssetItem(CirclePostImageItem item, int index,
      {bool isUpdate = true}) {
    _assetList.insert(index, item);
    if (isUpdate) {
      setSendButtonStatus();
      update([circleGridIdentifier]);
    }
  }

  void removeAssetItemWithIndex(int index, {bool isUpdate = true}) {
    _assetList.removeAt(index);
    if (isUpdate) {
      setSendButtonStatus();
      update([circleGridIdentifier]);
    }
  }

  void removeAssetItem(CirclePostImageItem item, {bool isUpdate = true}) {
    _assetList.remove(item);
    if (isUpdate) {
      setSendButtonStatus();
      update([circleGridIdentifier]);
    }
  }

  void setSendButtonStatus() {
    canSend = !((inputController?.data?.isEmpty ?? true) &&
        (_assetList?.isEmpty ?? true));
    update([circleDynamicToolbarIdentifier]);
  }

  String getType() {
    return circleType == CirclePostType.CirclePostTypeVideo ? 'video' : 'image';
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
      // NOTE: 2022/4/11 解决富文本中含有其他属性（如链接）不能编辑的问题
      if (attributeV is Map &&
          attributeV.isNotEmpty &&
          attributeV['at'] != null) {
        final atStr = attributeV['at'];
        textContent = textContent + atStr;
        _atSelectorModel.atMap[atStr] = insertV ?? '';
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
                _atSelectorModel.atList.add(id);
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
    for (final CirclePostImageItem mediaItem in _assetList) {
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
      final dynamic insertV = map['insert'] ?? '';
      if (insertV is Map) {
        final Map insertMap = insertV;
        final type = insertMap['_type'] ?? '';
        if (type == 'image' || type == 'video') {
          break;
        }
      }
      textList.add(map);
    }

    setTextContent(textList);

    final List medias = dynamicMediaList(contentList);

    for (final Map itemJson in medias) {
      final imageItem = CirclePostImageItem.fromJson(itemJson);
      _assetList.add(imageItem);
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
    if (text.isEmpty && _assetList.isEmpty) {
      return '';
    }

    final List contents = [];
    if (text.isEmpty) {
      // contents.add({"insert": ""});
    } else {
      text.splitMapJoin(RegExp(r"\$\{.*?\}"), onMatch: (m) {
        final matchStr = m.group(0);
        if (matchStr.isNotEmpty) {
          contents.add({
            "insert": _atSelectorModel.atMap[matchStr] ?? '',
            "attributes": {"at": matchStr}
          });
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

    // contents.add({"insert": "\n"});

    for (final item in assetList) {
      if (item.isAdd == false) {
        contents.add({"insert": item.toJson()});
      }
    }

    contents.add({"insert": "\n"});
    final String contentStr = json.encode(contents);
    return contentStr;
  }

  @override
  void dispose() {
    titleFocusNode?.dispose();
    titleController?.dispose();
    _tabIndex.dispose();
    _expand.dispose();
    super.dispose();
  }
}
