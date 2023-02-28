import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/circle/model/circle_dynamic_data_controller.dart';
import 'package:im/pages/home/model/universal_rich_input_controller.dart';
import 'package:im/pages/home/view/bottom_bar/emoji.dart';
import 'package:im/pages/home/view/bottom_bar/keyboard_container2.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_base.dart';

class DynamicEditorToolbar extends ToolbarBase {
  final BuildContext context;

  DynamicEditorToolbar(this.context);

  @override
  ToolbarBase editorToolbar(BuildContext context) =>
      DynamicEditorToolbar(context);

  @override
  _DynamicEditorToolbarState createState() => _DynamicEditorToolbarState();
}

class _DynamicEditorToolbarState extends State<DynamicEditorToolbar> {
  UniversalRichInputController get editorController => _model.inputController;

  // ValueNotifier<bool> get isEditorFocus => _model.isEditorFocus;
  // ValueNotifier<bool> get canSend => _model.canSend;
  // SubToolbar _showingSubToolbar = SubToolbar.none;
  // bool _readOnly = false;
  CircleDynamicDataController _model;
  ToolbarIndex toolbarIndex = ToolbarIndex.none;

  @override
  void initState() {
    // _model = Provider.of<RichTunEditorModel>(context, listen: false);
    _model = Get.find<CircleDynamicDataController>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              top:
                  BorderSide(color: DividerTheme.of(context).color, width: 0.5),
            ),
          ),
          child: GetBuilder<CircleDynamicDataController>(
            id: _model.circleDynamicToolbarIdentifier,
            builder: (c) {
              final defaultColor = appThemeData.iconTheme.color;
              final disableColor = defaultColor.withOpacity(0.4);
              final butColor = c.isEditorFocus ? defaultColor : disableColor;
              return Row(
                children: [
                  IconButton(
                    icon: Icon(
                      IconFont.richEditorAt,
                      color: butColor,
                      size: 24,
                    ),
                    onPressed: c.isEditorFocus
                        ? () async {
                            toolbarIndex = ToolbarIndex.at;
                            final res = await c.atSelectorModel.selectUser();
                            c.atSelectorModel.insertUser(res);
                          }
                        : null,
                  ),
                  IconButton(
                    icon: Icon(
                      IconFont.richEditorImage,
                      color: (c.isEditorFocus && c.isEnableImage)
                          ? defaultColor
                          : disableColor,
                      size: 24,
                    ),
                    onPressed: (c.isEditorFocus && c.isEnableImage)
                        ? () {
                            toolbarIndex = ToolbarIndex.image;
                            c.pickImages(isAdd: true);
                          }
                        : null,
                  ),
                  IconButton(
                    icon: Icon(
                      IconFont.richEditorEmoji,
                      color: butColor,
                      size: 24,
                    ),
                    onPressed: c.isEditorFocus ? c.emoji : null,
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  GestureDetector(
                    onTap: !c.canSend ? null : c.onSend,
                    child: Container(
                      width: 44,
                      height: 36,
                      padding: const EdgeInsets.fromLTRB(11, 6, 9, 6),
                      decoration: ShapeDecoration(
                          color: c.canSend
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).scaffoldBackgroundColor,
                          shape: const StadiumBorder()),
                      child: Icon(
                        IconFont.buffTabSend,
                        color:
                            c.canSend ? Colors.white : const Color(0xFFC2C5CC),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        _buildKeyboardContainer(_model),
      ],
    );
  }

  Widget _buildKeyboardContainer(CircleDynamicDataController model) {
    return ValueListenableBuilder(
        valueListenable: model.tabIndex,
        builder: (context, tabIndex, child) {
          Widget child;
          switch (tabIndex) {
            case ToolbarIndex.emoji:
              child = EmojiTabs(
                inputController: model.inputController,
              );
              // AbstractRichTextFactory.instance
              // .createRichEditorEmoji(model.editorController);
              break;
            default:
              child = const SizedBox();
          }
          return KeyboardContainer2(
            expand: model.expand,
            childHeight: 300,
            titleFocusNode: model.titleFocusNode,
            editorFocusNode: model.textFieldFocusNode,
            builder: (context) {
              return child;
            },
          );
        });
  }
}
