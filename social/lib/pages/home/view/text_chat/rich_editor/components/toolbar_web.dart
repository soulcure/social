import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:im/pages/home/view/bottom_bar/keyboard_container2.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/emoji.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/toolbar_base.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/factory/abstract_rich_text_factory.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/model/editor_model.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/web/utils/web_toast.dart';
import 'package:im/widgets/cache_widget.dart';
import 'package:tun_editor/tun_editor_toolbar.dart';

import '../../../../../../icon_font.dart';

final toolbarCallback =
    AbstractRichTextFactory.instance.createToolbarCallback();

class RichEditorToolbar extends ToolbarBase {
  final BuildContext context;
  final RichEditorModel model;
  RichEditorToolbar(this.context, this.model);

  @override
  ToolbarBase editorToolbar(BuildContext context) =>
      RichEditorToolbar(context, model);

  @override
  _RichEditorToolbarState createState() => _RichEditorToolbarState();
}

class _RichEditorToolbarState extends State<RichEditorToolbar> {
  QuillController get editorController => _model.editorController;

  ValueNotifier<bool> get isEditorFocus => _model.isEditorFocus;

  ValueNotifier<ToolbarMenu> get tabIndex => _model.tabIndex;

  List<ToolbarMenu> get toolbarItems => _model.toolbarItems;

  ValueNotifier<bool> get canSend => _model.canSend;

  RichEditorModel get _model => widget.model;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CacheWidget(builder: () {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(
                left: OrientationUtil.landscape ? 14 : 0,
                right: OrientationUtil.landscape ? 14 : 0,
                top: OrientationUtil.landscape ? 10 : 0),
            child: ValueListenableBuilder<bool>(
                valueListenable: isEditorFocus,
                builder: (context, value, child) {
                  return ValueListenableBuilder<ToolbarMenu>(
                      valueListenable: tabIndex,
                      builder: (context, tabIndex, child) {
                        return QuillToolbar(
                          key: ValueKey(_model.editorController.hashCode),
                          children: [
                            if (_model.toolbarItems.contains(ToolbarMenu.at))
                              CustomToolbarButton(
                                context: context,
                                model: _model,
                                icon: IconFont.richEditorAt,
                                onPressed: toolbarCallback.showAtList,
                              ),
                            if (_model.toolbarItems.contains(ToolbarMenu.image))
                              CustomToolbarButton(
                                context: context,
                                model: _model,
                                icon: IconFont.richEditorImage,
                                onPressed: toolbarCallback.pickImages,
                              ),
                            if (_model.toolbarItems.contains(ToolbarMenu.emoji))
                              CustomToolbarButton(
                                context: context,
                                model: _model,
                                icon: IconFont.richEditorEmoji,
                                onPressed: toolbarCallback.showEmojiTab,
                              ),
                            if (_model.toolbarItems
                                .contains(ToolbarMenu.textType))
                              SelectHeaderStyleButton(
                                controller: _model.editorController,
                              ),
                            if (_model.toolbarItems
                                .contains(ToolbarMenu.textTypeListBullet))
                              ToggleStyleButton(
                                attribute: Attribute.ol,
                                controller: _model.editorController,
                                icon: IconFont.richEditorTextTypeListOrdered,
                              ),
                            if (_model.toolbarItems
                                .contains(ToolbarMenu.textTypeListOrdered))
                              ToggleStyleButton(
                                attribute: Attribute.ul,
                                controller: _model.editorController,
                                icon: IconFont.richEditorTextTypeListBullet,
                              ),
                            if (_model.toolbarItems
                                .contains(ToolbarMenu.textTypeDivider))
                              InsertEmbedButton(
                                controller: _model.editorController,
                                icon: IconFont.richEditorDivider,
                              ),
                            if (_model.toolbarItems
                                .contains(ToolbarMenu.textTypeQuote))
                              ToggleStyleButton(
                                attribute: Attribute.blockQuote,
                                controller: _model.editorController,
                                icon: IconFont.richEditorQuote,
                              ),
                            if (_model.toolbarItems
                                .contains(ToolbarMenu.textTypeCodeBlock))
                              ToggleStyleButton(
                                attribute: Attribute.codeBlock,
                                controller: _model.editorController,
                                icon: IconFont.richEditorCode,
                              ),
                            if (_model.toolbarItems
                                .contains(ToolbarMenu.textStyleBold))
                              ToggleStyleButton(
                                attribute: Attribute.bold,
                                icon: IconFont.richEditorTextStyleBold,
                                controller: _model.editorController,
                              ),
                            if (_model.toolbarItems
                                .contains(ToolbarMenu.textStyleItalic))
                              ToggleStyleButton(
                                attribute: Attribute.italic,
                                icon: IconFont.richEditorTextStyleItalic,
                                controller: _model.editorController,
                              ),
                            if (_model.toolbarItems
                                .contains(ToolbarMenu.textStyleUnderline))
                              ToggleStyleButton(
                                attribute: Attribute.underline,
                                icon: IconFont.richEditorTextStyleUnderline,
                                controller: _model.editorController,
                              ),
                            if (_model.toolbarItems
                                .contains(ToolbarMenu.textStyleStrikeThrough))
                              ToggleStyleButton(
                                attribute: Attribute.strikeThrough,
                                icon: IconFont.richEditorTextStyleStrikeThrough,
                                controller: _model.editorController,
                              ),
                            if (_model.toolbarItems.contains(ToolbarMenu.link))
                              CustomLinkStyleButton(
                                controller: _model.editorController,
                                icon: IconFont.richEditorLink,
                              ),
                          ],
                        );
                      });
                }),
          ),
          _buildKeyboardContainer(),
        ],
      );
    });
  }

  Widget _buildKeyboardContainer() {
    return ValueListenableBuilder(
        valueListenable: _model.tabIndex,
        builder: (context, tabIndex, child) {
          Widget child;
          switch (tabIndex) {
            case ToolbarMenu.emoji:
              child = RichEditorEmoji(editorController);
              break;
            default:
              child = const SizedBox();
          }
          return KeyboardContainer2(
            expand: _model.expand,
            childHeight: 300,
            titleFocusNode: _model.titleFocusNode,
            editorFocusNode: _model.editorFocusNode,
            builder: (context) {
              return child;
            },
          );
        });
  }
}

typedef GestureContextCallback = void Function(BuildContext, RichEditorModel);

class CustomToolbarButton extends StatelessWidget {
  final BuildContext context;
  final RichEditorModel model;
  final IconData icon;
  final GestureContextCallback onPressed;

  const CustomToolbarButton(
      {Key key,
      @required this.context,
      @required this.model,
      @required this.icon,
      this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final isDisabled = !model.editorFocusNode.hasFocus;
    return QuillIconButton(
      icon: Icon(
        icon,
        size: 19,
        // color: isDisabled
        //     ? Theme.of(context).iconTheme.color.withOpacity(0.5)
        //     : Theme.of(context).iconTheme.color,
      ),
      highlightElevation: 0,
      hoverElevation: 0,
      size: kDefaultIconSize * 1.77,
      fillColor: Theme.of(context).canvasColor,
      onPressed: () => onPressed?.call(context, model),
    );
  }
}

class CustomLinkStyleButton extends StatefulWidget {
  const CustomLinkStyleButton({
    @required this.controller,
    this.iconSize = kDefaultIconSize,
    this.icon,
    Key key,
  }) : super(key: key);

  final QuillController controller;
  final IconData icon;
  final double iconSize;

  @override
  _CustomLinkStyleButtonState createState() => _CustomLinkStyleButtonState();
}

class _CustomLinkStyleButtonState extends State<CustomLinkStyleButton> {
  void _didChangeSelection() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_didChangeSelection);
  }

  @override
  void didUpdateWidget(covariant CustomLinkStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeSelection);
      widget.controller.addListener(_didChangeSelection);
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_didChangeSelection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = !widget.controller.selection.isCollapsed;
    final pressedHandler = isEnabled
        ? () => _openLinkDialog(context)
        : () {
            showWebToast('请选中设置链接的文本');
          };
    return QuillIconButton(
      highlightElevation: 0,
      hoverElevation: 0,
      size: widget.iconSize * kIconButtonFactor,
      icon: Icon(
        widget.icon ?? Icons.link,
        size: widget.iconSize,
        color: isEnabled ? theme.iconTheme.color : theme.disabledColor,
      ),
      fillColor: Theme.of(context).canvasColor,
      onPressed: pressedHandler,
    );
  }

  void _openLinkDialog(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (ctx) {
        return const _LinkDialog();
      },
    ).then(_linkSubmitted);
  }

  void _linkSubmitted(String value) {
    if (value == null || value.isEmpty) {
      return;
    }
    widget.controller.formatSelection(LinkAttribute(value));
  }
}

class _LinkDialog extends StatefulWidget {
  const _LinkDialog({Key key}) : super(key: key);

  @override
  _LinkDialogState createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  String _link = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: TextField(
        style: const TextStyle(fontSize: 16),
        decoration: const InputDecoration(
            labelText: '设置链接', labelStyle: TextStyle(height: 1, fontSize: 18)),
        autofocus: true,
        onChanged: _linkChanged,
      ),
      actions: [
        TextButton(
          onPressed: _link.isNotEmpty ? _applyLink : null,
          child: const Text('确定'),
        ),
      ],
    );
  }

  void _linkChanged(String value) {
    setState(() {
      _link = value;
    });
  }

  void _applyLink() {
    Navigator.pop(context, _link);
  }
}
