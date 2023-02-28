import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/widgets/controller.dart';
import 'package:get/get.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/emo_util.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/web/widgets/portrait_scrollbar.dart';

import 'emoji_base.dart';

class RichEditorEmoji extends RichEditorEmojiBase {
  final QuillController textEditingController;
  final VoidCallback onTap;
  RichEditorEmoji(this.textEditingController, {this.onTap});

  @override
  // ignore: type_annotate_public_apis
  RichEditorEmojiBase richEditorEmoji(textEditingController,
      {VoidCallback onTap}) {
    return RichEditorEmoji(textEditingController, onTap: onTap);
  }

  @override
  _RichEditorEmojiState createState() => _RichEditorEmojiState();
}

class _RichEditorEmojiState extends State<RichEditorEmoji>
    with SingleTickerProviderStateMixin {
  TabController _controller;
  ThemeData _theme;
  final List<String> emojiCates = ['微笑'.tr];
  @override
  void initState() {
    _controller = TabController(
      length: 1,
      vsync: this,
    );
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: _tabBarView()),
        divider,
        Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: <Widget>[
              Expanded(child: _tabBar()),
              if (OrientationUtil.portrait)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    deleteEmo();
                  },
                  child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 2, 24, 2),
                      width: 100,
                      height: 30,
                      alignment: Alignment.centerRight,
                      child: const Icon(Icons.backspace)),
                )
            ],
          ),
        )
      ],
    );
  }

  Widget _tabBarView() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBarView(controller: _controller, children: [
        PortraitScrollbar(
          child: GridView.builder(
            itemCount: EmoUtil.instance.curEmoList.length,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              final curEmo = EmoUtil.instance.curEmoList[index];
              return FadeButton(
                onTap: () {
                  final offset = widget.textEditingController.selection.end +
                      curEmo.id.length;
                  widget.textEditingController.replaceText(
                    widget.textEditingController.selection.start,
                    0,
                    curEmo.id,
                    TextSelection.collapsed(offset: offset),
                  );
                  widget.onTap?.call();
                },
                child: Tooltip(
                  message: curEmo.name,
                  child: EmoUtil.instance.getEmoIcon(curEmo.name),
                ),
              );
            },
          ),
        )
      ]),
    );
  }

  TabBar _tabBar() {
    return TabBar(
        isScrollable: true,
        controller: _controller,
        labelColor: _theme.textTheme.bodyText2.color,
        unselectedLabelColor: _theme.textTheme.bodyText1.color,
        indicatorColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        labelPadding: const EdgeInsets.symmetric(horizontal: 10),
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 10),
        indicator: BoxDecoration(
            color: _theme.backgroundColor,
            borderRadius: BorderRadius.circular(8)),
        tabs: emojiCates
            .map((e) => Container(
                height: 30,
                margin: const EdgeInsets.only(top: 8),
                child: EmoUtil.instance.getEmoIcon(e)))
            .toList());
  }

  void deleteEmo() {
    final selectionEnd = widget.textEditingController.selection.end;
    final lookRes =
        widget.textEditingController.document.queryChild(selectionEnd);
    if (lookRes.node == null) return;
    final node = lookRes.node;
    final offset = lookRes.offset;
    final chars = node.toPlainText().characters;
    final charNumList = <int>[];
    // 保存字符串里每个字符的长度
    for (final c in chars) {
      charNumList.add(c.length);
    }
    // 获取删除的字符的长度（特殊字符，eg：emoji）
    int delIndex = -1;
    int allLen = 0;
    for (var i = 0; i < charNumList.length; i++) {
      final len = charNumList[i];
      if (offset > allLen && offset <= allLen + charNumList[i]) {
        delIndex = i;
        break;
      }
      allLen += len;
    }
    if (delIndex >= 0) {
      final delLength = charNumList[delIndex];
      widget.textEditingController.replaceText(
        selectionEnd - delLength,
        delLength,
        '',
        TextSelection.collapsed(offset: selectionEnd - delLength),
        ignoreFocus: true,
      );
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      // widget.textEditingController.notifyListeners();
    }
  }
  // final delIndex = widget.textEditingController.selection.end;
  //
  // widget.textEditingController.document.delete(delIndex - 1, 1);
  // widget.textEditingController
  //     .updateSelection(TextSelection.collapsed(offset: delIndex - 1));
  // }
}
