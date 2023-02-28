import 'package:flutter/material.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model_base.dart';
import 'package:flutter_quill/flutter_quill.dart';

abstract class EmbedBuilderBase extends StatefulWidget {
  EmbedBuilderBase embedBuilder(Embed node, RichEditorModelBase model);
}
