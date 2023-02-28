import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/pages/circle/circle_post_entity.dart';
import 'package:im/pages/circle/content/circle_post_image_item.dart';
import 'package:im/pages/circle/model/circle_dynamic_data_controller.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/universal_rich_input_controller.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/embed_builder_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/embed_builder_io.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/emoji_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/emoji_tun.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_callback_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_callback_io.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_dynamic_io.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_io.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/editor/editor_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/editor/editor_tun.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/factory/abstract_rich_text_factory.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model_tun.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/rich_input_popup_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/rich_input_popup_tun.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:tun_editor/tun_editor_toolbar.dart';

class PortraitRichTextFactory extends AbstractRichTextFactory {
  @override
  RichEditorModelBase createEditorModel({
    @required ChatChannel channel,
    bool needTitle = true,
    bool needDivider = true,
    Document defaultDoc,
    String defaultTitle = '',
    String titlePlaceholder = '',
    String editorPlaceholder = '',
    int titleLength = 100,
    int maxMediaNum = 50,
    VoidCallback onSend,
    bool showScrollbar = false,
    TextStyle titleStyle,
    DefaultStyles documentStyle,
    List<CircleTopicDataModel> optionTopics = const [],
    List<CirclePostImageItem> assetList = const [],
    List<ToolbarMenu> toolbarItems = defaultToolbarMenu,
  }) {
    return RichTunEditorModel(
        channel: channel,
        needTitle: needTitle,
        needDivider: needDivider,
        defaultDoc: defaultDoc,
        defaultTitle: defaultTitle,
        titlePlaceholder: titlePlaceholder,
        editorPlaceholder: editorPlaceholder,
        titleLength: titleLength,
        maxMediaNum: maxMediaNum,
        onSend: onSend,
        showScrollbar: showScrollbar,
        optionTopics: optionTopics,
        assetList: assetList,
        toolbarItems: toolbarItems);
  }

  @override
  CircleDynamicDataController createDynamicController({
    @required ChatChannel channel,
    int maxImages = 9,
    CirclePostType circleType = CirclePostType.CirclePostTypeImage,
    List<CirclePostImageItem> assetList,
    VoidCallback onSend,
  }) {
    return CircleDynamicDataController(
        channel: channel,
        maxImages: maxImages,
        circleType: circleType,
        assets: assetList,
        onSend: onSend);
  }

  @override
  ToolbarCallbackBase createToolbarCallback() {
    return ToolbarTunCallback();
  }

  @override
  // ignore: type_annotate_public_apis
  RichEditorEmojiBase createRichEditorEmoji(textEditingController,
      {VoidCallback onTap}) {
    return RichTunEditorEmoji(
      textEditingController,
      onTap: onTap,
    );
  }

  @override
  RichInputPopupBase createRichInputPopup(
      {MessageEntity originMessage,
      UniversalRichInputController inputController,
      MessageEntity reply,
      bool replyDetailPage,
      @required String cacheKey}) {
    return RichTunInputPop(
        originMessage: originMessage,
        reply: reply,
        inputController: inputController,
        replyDetailPage: replyDetailPage,
        cacheKey: cacheKey);
  }

  @override
  EmbedBuilderBase createEmbedBuilder(Embed node, RichEditorModelBase model) {
    return RichTunEditorEmbedBuilder(node, model);
  }

  @override
  ToolbarBase createEditorToolbar(
      BuildContext context, RichEditorModelBase model) {
    return RichTunEditorToolbar(context, model);
  }

  @override
  ToolbarBase createDynamicEditorToolbar(BuildContext context) {
    return DynamicEditorToolbar(context);
  }

  @override
  RichEditorBase createRichEditor(RichEditorModelBase model) {
    return RichTunEditor(model);
  }

  @override
  Future<List<CirclePostImageItem>> pickImages(
      int maxImages, List<String> selectedAssets,
      {FBMediaSelectType mediaSelectType = FBMediaSelectType.all}) async {
    FBMediaShowType showType = FBMediaShowType.all;
    //设置显示类型
    if (mediaSelectType == FBMediaSelectType.video) {
      showType = FBMediaShowType.video;
    } else if (mediaSelectType == FBMediaSelectType.image) {
      showType = FBMediaShowType.image;
    }

    List<Asset> result;
    try {
      result = await MediaPicker.showMediaPicker(
        maxImages: maxImages,
        mediaSelectType: mediaSelectType,
        mediaShowType: showType,
        selectedAssets: selectedAssets ?? [],
        doneButtonText: '下一步'.tr,
        thumbType: FBMediaThumbType.origin,
        cupertinoOptions: CupertinoOptions(
            takePhotoIcon: "chat",
            selectionStrokeColor:
                "#${appThemeData.primaryColor.value.toRadixString(16)}",
            selectionFillColor:
                "#${appThemeData.primaryColor.value.toRadixString(16)}"),
        materialOptions: MaterialOptions(
          allViewTitle: "所有图片".tr,
          selectCircleStrokeColor:
              "#${appThemeData.primaryColor.value.toRadixString(16)}",
        ),
      );
    } catch (e) {
      e.toString();
    }

    final List<CirclePostImageItem> assetList = [];
    if (result != null && result.isNotEmpty) {
      for (final asset in result) {
        double width = asset.originalWidth;
        double height = asset.originalHeight;
        if (width == null || width == 0) width = asset.thumbWidth;
        if (height == null || height == 0) height = asset.thumbHeight;

        final item = CirclePostImageItem(
            requestId: asset.requestId,
            name: asset.filePath,
            identifier: asset.identifier,
            thumbName: asset.thumbFilePath,
            width: width,
            height: height,
            type: asset.fileType == 'video' ? 'video' : 'image',
            duration: asset.duration);
        assetList.add(item);
      }
    }

    return assetList;
  }
}
