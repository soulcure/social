import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/controllers/circle_publish_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/universal_rich_input_controller.dart';
import 'package:im/pages/home/view/bottom_bar/emoji.dart';
import 'package:im/pages/home/view/bottom_bar/keyboard_container2.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_base.dart';
import 'package:im/themes/const.dart';

class CirclePublishToolbar extends ToolbarBase {
  final BuildContext context;
  final VoidCallback onTap;

  CirclePublishToolbar(this.context, {this.onTap});

  @override
  ToolbarBase editorToolbar(BuildContext context) =>
      CirclePublishToolbar(context);

  @override
  _DynamicEditorToolbarState createState() => _DynamicEditorToolbarState();
}

class _DynamicEditorToolbarState extends State<CirclePublishToolbar> {
  UniversalRichInputController get editorController => _model.inputController;

  // ValueNotifier<bool> get isEditorFocus => _model.isEditorFocus;
  // ValueNotifier<bool> get canSend => _model.canSend;
  // SubToolbar _showingSubToolbar = SubToolbar.none;
  // bool _readOnly = false;
  CirclePublishController _model;
  ToolbarIndex toolbarIndex = ToolbarIndex.none;

  @override
  void initState() {
    // _model = Provider.of<RichTunEditorModel>(context, listen: false);
    _model = Get.find<CirclePublishController>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: appThemeData.backgroundColor,
            border: Border(
              top:
                  BorderSide(color: DividerTheme.of(context).color, width: 0.5),
            ),
          ),
          child: GetBuilder<CirclePublishController>(
            id: _model.circleDynamicToolbarIdentifier,
            builder: (c) {
              final butColor = appThemeData.iconTheme.color;
              return Row(
                children: [
                  if (c.textFieldFocusNode.hasFocus) ...[
                    IconButton(
                      icon: Icon(
                        IconFont.richEditorAt,
                        color: butColor,
                        size: 24,
                      ),
                      onPressed: c.isEditorFocus
                          ? () => _model.showTunAtList(context)
                          : null,
                    ),
                    IconButton(
                      icon: Icon(
                        IconFont.buffPoundSign,
                        color: butColor,
                        size: 24,
                      ),
                      onPressed: c.isEditorFocus
                          ? () => _model.showTunChannelList(context)
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
                    IconButton(
                      icon: Icon(
                        IconFont.buffDocument,
                        color: c.docItem == null
                            ? butColor
                            : appThemeData.iconTheme.color.withOpacity(.4),
                        size: 24,
                      ),
                      onPressed: (c.isEditorFocus && c.docItem == null)
                          ? c.insertTCDoc
                          : () {},
                    ),
                  ],
                  const Expanded(
                    child: sizedBox,
                  ),
                  GestureDetector(
                    onTap: () => widget.onTap?.call(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        '完成'.tr,
                        style: appThemeData.textTheme.bodyText2.copyWith(
                            color: appThemeData.primaryColor,
                            fontWeight: FontWeight.bold),
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

  Widget _buildKeyboardContainer(CirclePublishController model) {
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
