import 'package:flutter/cupertino.dart';
import 'package:notus/notus.dart';
import 'package:flutter/services.dart';

import 'editor.dart';

mixin RawEditorStateSelectionDelegateMixin on EditorState
    implements TextSelectionDelegate {
  @override
  TextEditingValue get textEditingValue {
    // 修改，替换图片复制出来的obj空字符
    // return widget.controller.plainTextEditingValue;
    return widget.controller.plainTextEditingValue.copyWith(
        text: widget.controller.plainTextEditingValue.text
            .replaceAll(RegExp(r"\ufffc"), ' '));
  }

  @override
  set textEditingValue(TextEditingValue value) {
    // 修改，修复粘贴没有粘贴内容bug
    // widget.controller
    //     .updateSelection(value.selection, source: ChangeSource.local);
    if (value.text == textEditingValue.text) {
      widget.controller.updateSelection(value.selection);
    } else {
      __setEditingValue(value);
    }
  }

  void __setEditingValue(TextEditingValue value) async {
    if (await __isItCut(value)) {
      final ClipboardData data = await Clipboard.getData(Clipboard.kTextPlain);
      final offset = textEditingValue.selection.end - data.text.length;
      widget.controller.replaceText(
        textEditingValue.selection.start,
        textEditingValue.text.length - value.text.length,
        '',
        selection: TextSelection.collapsed(offset: offset),
      );
    } else {
      final ClipboardData data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null) {
        final length =
            textEditingValue.selection.end - textEditingValue.selection.start;
        final offset = textEditingValue.selection.end + data.text.length;

        widget.controller.replaceText(
          textEditingValue.selection.start,
          length,
          data.text,
          selection: TextSelection.collapsed(offset: offset),
        );
      }
    }
  }

  Future<bool> __isItCut(TextEditingValue value) async {
    final ClipboardData data = await Clipboard.getData(Clipboard.kTextPlain);
    return textEditingValue.text.length - value.text.length == data.text.length;
  }

  @override
  void bringIntoView(TextPosition position) {
    // TODO: implement bringIntoView
  }

  @override
  void hideToolbar([bool hideHandles = true]) {
    if (selectionOverlay?.toolbarIsVisible == true) {
      selectionOverlay?.hideToolbar();
    }
  }

  @override
  bool get cutEnabled => widget.toolbarOptions.cut && !widget.readOnly;

  @override
  bool get copyEnabled => widget.toolbarOptions.copy;

  @override
  bool get pasteEnabled => widget.toolbarOptions.paste && !widget.readOnly;

  @override
  bool get selectAllEnabled => widget.toolbarOptions.selectAll;
}
