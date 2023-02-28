import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as fq;
import 'package:flutter_quill/widgets/editor.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/editor/editor_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/factory/abstract_rich_text_factory.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:rich_input/rich_input.dart';
import '../model/editor_model.dart';

const double _pagePadding = 16;

class EnterIntent extends Intent {}

//以前的富文本代码，现用来做web端
class RichEditor extends RichEditorBase {
  final RichEditorModel model;

  RichEditor(this.model);

  @override
  RichEditorBase richEditor(RichEditorModelBase model) => RichEditor(model);

  @override
  RichEditorState createState() => RichEditorState();
}

class RichEditorState extends State<RichEditor> {
  RichEditorModel get model => widget.model;

  fq.QuillController get editorController => widget.model.editorController;

  RichInputController get titleController => widget.model.titleController;

  FocusNode get titleFocusNode => widget.model.titleFocusNode;

  FocusNode get editorFocusNode => widget.model.editorFocusNode;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.model?.editorController == null)
      return const Center(child: CircularProgressIndicator());
    final zefyrScaffold = QuillEditor(
      placeholder: widget.model.editorPlaceholder,
      customStyles: RichEditorUtils.defaultDocumentStyle(context),
      autoFocus: false,
      readOnly: false,
      expands: true,
      scrollable: true,
      scrollController: widget.model.scrollController,
      padding: EdgeInsets.symmetric(
          horizontal: OrientationUtil.portrait ? _pagePadding : 24,
          vertical: 10),
      controller: editorController,
      focusNode: editorFocusNode,
      embedBuilder: (context, node, readOnly) =>
          AbstractRichTextFactory.instance.createEmbedBuilder(
              node, widget.model), //RichEditorEmbedBuilder(node, widget.model),
    );
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Material(
          color: Theme.of(context).backgroundColor,
          child: Column(
            children: [
              if (OrientationUtil.landscape) ...[
                AbstractRichTextFactory.instance
                    .createEditorToolbar(context, widget.model),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                )
              ],
              _buildTitle(),
              Expanded(
                  child: Stack(
                children: [
                  if (!widget.model.showScrollbar)
                    zefyrScaffold
                  else
                    Scrollbar(
                      child: zefyrScaffold,
                    )
                ],
              )),
              Divider(
                height: 0.5,
                thickness: 0.5,
                color: CustomColor(context).disableColor.withOpacity(0.2),
              ),
              if (OrientationUtil.portrait)
                AbstractRichTextFactory.instance
                    .createEditorToolbar(context, widget.model),
            ],
          )),
    );
  }

  Widget _buildTitle() {
    if (!widget.model.needTitle) return const SizedBox();
    return Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.enter): EnterIntent(),
          LogicalKeySet(LogicalKeyboardKey.numpadEnter): EnterIntent(),
        },
        child: Actions(
          actions: {
            EnterIntent: CallbackAction<EnterIntent>(
                onInvoke: (_) => FocusScope.of(context).nextFocus()),
          },
          child: RichInput(
            selectionWidthStyle: BoxWidthStyle.max,
            selectionHeightStyle: BoxHeightStyle.max,
            enableSuggestions: false,
            controller: titleController,
            focusNode: titleFocusNode,
            style: Theme.of(context)
                .textTheme
                .bodyText2
                .merge(widget.model.titleStyle),
            keyboardType: TextInputType.multiline,
            maxLength: 5000,
            inputFormatters: [
              LengthLimitingTextInputFormatter(widget.model.titleLength)
            ],
            decoration: InputDecoration(
              contentPadding: OrientationUtil.portrait
                  ? const EdgeInsets.fromLTRB(16, 0, 16, 8)
                  : const EdgeInsets.fromLTRB(24, 0, 24, 8),
              isDense: true,
              counterText: "",
              border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(20),
                  gapPadding: 0),
              hintStyle: TextStyle(
                  fontSize: widget.model.titleStyle?.fontSize ?? 17,
                  color: CustomColor(context).disableColor.withOpacity(0.5)),
              hintText: widget.model.titlePlaceholder,
            ),
            textInputAction: TextInputAction.next,
          ),
        ));
  }

  String getFilename(String filePath) {
    final index = filePath.lastIndexOf('/');
    return index > -1 ? filePath.substring(index + 1, filePath.length) : '';
  }

  Future<bool> _onWillPop() async {
    if (Loading.visible) {
      return false;
    }
    return true;
  }
}
