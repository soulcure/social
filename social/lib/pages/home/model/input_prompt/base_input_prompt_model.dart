import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:rxdart/rxdart.dart';

import '../input_model.dart';
import '../text_field_utils.dart';

abstract class InputPromptModel<T> extends ChangeNotifier {
  final InputModel inputModel;
  final PublishSubject<String> _stream;
  final String matchChar;

  bool visible = false;
  MatchInputContentResult matchInputContentResult;
  List<T> completeList = [];
  List<T> list = [];

  InputPromptModel(this.inputModel, this.matchChar)
      : _stream = PublishSubject() {
    inputModel.inputController.addListener(_onInput);
    inputModel.textFieldFocusNode.addListener(_onInput);
    _stream
        .debounceTime(const Duration(milliseconds: 500))
        .listen(submitFilter);
    inputModel.textFieldFocusNode.addListener(() {
      if (!inputModel.textFieldFocusNode.hasFocus) {
        visible = false;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _stream.close();
    inputModel.textFieldFocusNode.removeListener(_onInput);
    inputModel.inputController.removeListener(_onInput);
    super.dispose();
  }

  void _onInput() {
    // web上光标停留在输入框，但是某些情况下inputModel.textFieldFocusNode.hasFocus会返回false
    if (!inputModel.textFieldFocusNode.hasFocus && !kIsWeb) return;
    _stream.add(inputModel.inputController.text);
  }

  Future<void> onMatch(String match);

  @protected
  Future<void> submitFilter(String text) async {
    ///群聊去除 #
    if (inputModel.type == ChatChannelType.group_dm && text == "#") return;

    ///群聊去除 @ 和 #
    if (inputModel.type == ChatChannelType.dm && (text == "#" || text == "@"))
      return;

    final result = TextFieldUtils.matchInputContent(
        inputController: inputModel.inputController, matchChar: matchChar);
    matchInputContentResult = result;

    final controller = inputModel.inputController;
    switch (result.code) {
      case MatchInputContentCode.DELETE_CHAR:
        if (TextFieldUtils.getCharBeforeCaret(controller) == matchChar) {
          completeList = list = await getCompleteList();
          visible = true;
        } else {
          visible = false;
        }
        break;
      case MatchInputContentCode.NO_MATCH:
        visible = false;
        break;
      case MatchInputContentCode.ENTER_CHAR:
        completeList = list = await getCompleteList();
        visible = inputModel.textFieldFocusNode.hasFocus;
        break;
      case MatchInputContentCode.MATCH:
        final str = text.substring(result.matchIndex + 1, result.caretIndex);
        await onMatch(str);
        break;
    }
    notifyListeners();
    // 修复web上拉起At列表输入框会失去焦点
    // if (kIsWeb) {
    //   try {
    //     final shouldFocus =
    //         FocusManager.instance.primaryFocus.context == null ||
    //             (FocusManager.instance.primaryFocus.context as StatefulElement)
    //                 .state is! EditableTextState;
    //     if (shouldFocus) {
    //       FocusScope.of(Get.context)
    //           .requestFocus(inputModel.textFieldFocusNode);
    //     }
    //   } on Exception catch (_) {}
    // }
  }

  Future<List<T>> getCompleteList();
}
