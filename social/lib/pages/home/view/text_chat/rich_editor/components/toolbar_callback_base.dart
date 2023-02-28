import 'package:flutter/cupertino.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model_base.dart';

abstract class ToolbarCallbackBase {
  Future<void> showAtList(BuildContext context, RichEditorModelBase model,
      {bool fromInput = false});
  Future<void> showChannelList(BuildContext context, RichEditorModelBase model,
      {bool fromInput = false});
  Future<void> pickImages(BuildContext context, RichEditorModelBase model);
  Future<void> showEmojiTab(BuildContext context, RichEditorModelBase model);
}
