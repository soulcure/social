import 'package:flutter/material.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model_base.dart';

abstract class RichEditorBase extends StatefulWidget {
  RichEditorBase richEditor(RichEditorModelBase model);
}
