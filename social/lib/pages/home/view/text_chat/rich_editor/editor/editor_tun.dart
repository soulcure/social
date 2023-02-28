import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/editor/editor_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model_base.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/widgets/text_field/native_input.dart';
import 'package:native_text_field/native_text_field.dart';
import 'package:rich_input/rich_input.dart';
import 'package:tun_editor/controller.dart';
import 'package:tun_editor/tun_editor.dart';

import '../model/editor_model_tun.dart';

const double _pagePadding = 16;

//移动端富文本代码
class RichTunEditor extends RichEditorBase {
  final RichTunEditorModel model;

  RichTunEditor(this.model);

  @override
  RichEditorBase richEditor(RichEditorModelBase model) => RichTunEditor(model);

  @override
  RichTunEditorState createState() => RichTunEditorState();
}

class RichTunEditorState extends State<RichTunEditor> {
  TunEditorController get editorController => widget.model.editorController;

  RichInputController get titleController => widget.model.titleController;

  NativeTextFieldController get titleNativeController =>
      widget.model.titleNativeController;

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

    final editor = TunEditor(
      placeholder: widget.model.editorPlaceholder,
      padding:
          const EdgeInsets.symmetric(horizontal: _pagePadding, vertical: 10),
      controller: editorController,
      focusNode: widget.model.editorFocusNode,
      fileBasePath: Global.deviceInfo.thumbDir,
      imageStyle: {
        'width': Get.width * 0.33,
        'align': 'left',
      },
      videoStyle: {
        'width': Get.width * 0.33,
        'align': 'left',
      },
      enableMarkdownSyntax: false,
    );

    return GetBuilder<RichTunEditorModel>(
      builder: (model) {
        return Column(
          children: [
            _buildTitle(),
            if (widget.model.needDivider) divider,
            Expanded(
              child: !model.showScrollbar
                  ? editor
                  : Scrollbar(
                      child: editor,
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTitle() {
    if (!widget.model.needTitle) return const SizedBox();
    return NativeInput(
      controller: titleController,
      nativeController: titleNativeController,
      focusNode: titleFocusNode,
      onSubmitted: (string) async {
        if (editorFocusNode.canRequestFocus) {
          titleFocusNode.unfocus();
          await Future.delayed(const Duration(milliseconds: 100));
          editorFocusNode.requestFocus();
        }
      },
      style: Theme.of(context)
          .textTheme
          .bodyText2
          .copyWith(fontSize: 16, fontWeight: FontWeight.w500),
      keyboardType: TextInputType.multiline,
      inputFormatters: [
        LengthLimitingTextInputFormatter(widget.model.titleLength)
      ],
      forceNative: true,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        isDense: true,
        counterText: "",
        border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(20),
            gapPadding: 0),
        hintStyle: TextStyle(
            fontSize: 17,
            color: CustomColor(context).disableColor.withOpacity(0.5),
            fontWeight: FontWeight.w500),
        hintText: widget.model.titlePlaceholder,
      ),
    );
  }

  String getFilename(String filePath) {
    final index = filePath.lastIndexOf('/');
    return index > -1 ? filePath.substring(index + 1, filePath.length) : '';
  }

// Future<bool> _onWillPop() async {
//   if (Loading.visible) {
//     return false;
//   }
//   return true;
// }
}
