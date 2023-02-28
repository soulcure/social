import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/pages/circle/circle_post_entity.dart';
import 'package:im/pages/circle/content/circle_post_image_item.dart';
import 'package:im/pages/circle/model/circle_dynamic_data_controller.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/universal_rich_input_controller.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/embed_builder_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/embed_builder_web.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/emoji.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/emoji_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_callback_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_callback_web.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_dynamic_io.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_web.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/editor/editor.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/editor/editor_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/factory/abstract_rich_text_factory.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/rich_input_popup.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/rich_input_popup_base.dart';
import 'package:im/web/utils/image_picker/image_picker.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:tun_editor/tun_editor_toolbar.dart';
import 'package:universal_html/html.dart' as html;

class LandscapeRichTextFactory extends AbstractRichTextFactory {
  @override
  RichEditorModelBase createEditorModel({
    ChatChannel channel,
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
        titleStyle: titleStyle,
        // documentStyle: documentStyle,
        showScrollbar: showScrollbar,
        optionTopics: optionTopics,
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
    return ToolbarCallback();
  }

  @override
  // ignore: type_annotate_public_apis
  RichEditorEmojiBase createRichEditorEmoji(textEditingController,
      {VoidCallback onTap}) {
    return RichEditorEmoji(
      textEditingController,
      onTap: onTap,
    );
  }

  @override
  RichInputPopupBase createRichInputPopup(
      {BuildContext context,
      MessageEntity originMessage,
      UniversalRichInputController inputController,
      MessageEntity reply,
      bool replyDetailPage,
      @required String cacheKey}) {
    return RichInputPop(
        originMessage: originMessage,
        reply: reply,
        inputController: inputController,
        replyDetailPage: replyDetailPage,
        cacheKey: cacheKey);
  }

  @override
  EmbedBuilderBase createEmbedBuilder(Embed node, RichEditorModelBase model) {
    return RichEditorEmbedBuilder(node, model);
  }

  @override
  ToolbarBase createEditorToolbar(
      BuildContext context, RichEditorModelBase model) {
    return RichEditorToolbar(context, model);
  }

  @override
  ToolbarBase createDynamicEditorToolbar(BuildContext context) {
    return DynamicEditorToolbar(context);
  }

  @override
  RichEditorBase createRichEditor(RichEditorModelBase model) {
    return RichEditor(model);
  }

  @override
  Future<List<CirclePostImageItem>> pickImages(
      int maxImages, List<String> selectedAssets,
      {FBMediaSelectType mediaSelectType = FBMediaSelectType.all}) async {
    final List<html.File> originFiles =
        await ImagePicker.pickFile2(accept: 'image/*,video/*', multiple: true);
    if (originFiles.isEmpty) return [];

    return [];
  }
}
