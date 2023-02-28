import 'package:flutter/foundation.dart';
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
import 'package:im/pages/home/view/text_chat/rich_editor/components/emoji_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_callback_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/editor/editor_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/factory/landscape_rich_text_factory.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/factory/portrait_rich_text_factory.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/rich_input_popup_base.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:tun_editor/tun_editor_toolbar.dart';

abstract class AbstractRichTextFactory {
  static AbstractRichTextFactory _instance;

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
  });

  CircleDynamicDataController createDynamicController({
    @required ChatChannel channel,
    int maxImages = 9,
    CirclePostType circleType = CirclePostType.CirclePostTypeImage,
    List<CirclePostImageItem> assetList,
    VoidCallback onSend,
  });

  ToolbarCallbackBase createToolbarCallback();

  // ignore: type_annotate_public_apis
  RichEditorEmojiBase createRichEditorEmoji(textEditingController,
      {VoidCallback onTap});

  RichInputPopupBase createRichInputPopup(
      {MessageEntity originMessage,
      UniversalRichInputController inputController,
      MessageEntity reply,
      bool replyDetailPage,
      @required String cacheKey});

  EmbedBuilderBase createEmbedBuilder(Embed node, RichEditorModelBase model);

  RichEditorBase createRichEditor(RichEditorModelBase model);

  ToolbarBase createEditorToolbar(
      BuildContext context, RichEditorModelBase model);

  ToolbarBase createDynamicEditorToolbar(BuildContext context);

  // selectType: selectAll selectVideo  selectImage selectSingleType
  Future<List<CirclePostImageItem>> pickImages(
      int maxImages, List<String> selectedAssets,
      {FBMediaSelectType mediaSelectType = FBMediaSelectType.all});

  static AbstractRichTextFactory get instance {
    if (_instance == null) {
      if (UniversalPlatform.isMobileDevice) {
        _instance = PortraitRichTextFactory();
      } else {
        _instance = LandscapeRichTextFactory();
      }
    }

    return _instance;
  }
}
