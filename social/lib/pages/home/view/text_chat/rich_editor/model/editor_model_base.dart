import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:rich_input/rich_input.dart';

abstract class RichEditorModelBase extends GetxController {
  dynamic get editorController => null;

  RichInputController get titleController => null;

  int get maxMediaNum => 50;

  dynamic get expand => null;

  RichEditorModelBase richEditorModel(
      {bool needTitle = true,
      String titlePlaceholder = '',
      String editorPlaceholder = '',
      int titleLength = 100,
      int maxMediaNum = 50,
      VoidCallback onSend,
      bool showScrollbar = false,
      List<CircleTopicDataModel> optionTopics = const [],
      List toolbarItems = const []});

  List<String> getUploadCache(String key) {
    return [];
  }
}
