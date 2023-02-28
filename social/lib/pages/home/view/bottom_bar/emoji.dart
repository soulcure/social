import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/universal_rich_input_controller.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/emo_util.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/sticker_util.dart';

class EmojiTabs extends StatefulWidget {
  final InputModel inputModel;
  final VoidCallback callback; //选中表情后回调
  final String guildId;
  final UniversalRichInputController inputController;
  final BuildContext parentContext; // web端的表情包不包裹
  final TextStyle insertTextStyle;

  const EmojiTabs({
    this.inputModel,
    this.callback,
    this.guildId,
    this.inputController,
    this.parentContext,
    this.insertTextStyle,
  });

  @override
  _EmojiTabsState createState() => _EmojiTabsState();
}

class _EmojiTabsState extends State<EmojiTabs> with TickerProviderStateMixin {
  TabController _controller;
  ThemeData _theme;
  bool isLongPressDeleting = false;
  bool isLongPress = false;

  UniversalRichInputController get controller =>
      widget.inputController ?? widget.inputModel.inputController;

  String get guildId => widget.inputModel?.guildId ?? widget.guildId;

  bool get isBuildSticker => widget.inputModel != null && !isGuildCircle;

  bool get isGuildCircle =>
      widget.inputModel?.type == ChatChannelType.guildCircle;

  @override
  void initState() {
    final hasSticker =
        StickerUtil.instance.hasStickers(guildId) && !isGuildCircle;
    _controller = TabController(
      length: (hasSticker ? 1 : 0) + 1,
      vsync: this,
    );
    StickerUtil.instance.getStickers(guildId).then((value) {
      final value = StickerUtil.instance.hasStickers(guildId) && !isGuildCircle;
      if (value != hasSticker)
        _controller = TabController(
          length: (value ? 1 : 0) + 1,
          vsync: this,
        );
      refresh();
    });
    super.initState();
  }

  void refresh() {
    if (mounted) setState(() {});
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
          padding: const EdgeInsets.only(left: 12),
          color: OrientationUtil.portrait
              ? appThemeData.scaffoldBackgroundColor
              : const Color(0xFFEEEEF3),
          height: 44,
          child: Row(
            children: <Widget>[
              Expanded(child: _tabBar()),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  deleteEmo();
//                  final int deleteLenth = String.fromCharCode(
//                          widget.textEditingController.text.runes.last)
//                      .length;
//                  widget.textEditingController.text =
//                      widget.textEditingController.text.substring(
//                          0,
//                          widget.textEditingController.text.length -
//                              deleteLenth);
                },
                onLongPress: () {
                  final text = controller.text;
                  if (text.isEmpty || !isLongPress) return;
                  int i = 0;
                  isLongPressDeleting = true;
                  int getMillSeconds() {
                    if (i > 15) return 20;
                    if (i > 5) return 50;
                    return 100;
                  }

                  void doDelete() {
                    if (!isLongPress) return;
                    if (isLongPressDeleting)
                      Future.delayed(Duration(milliseconds: getMillSeconds()),
                          () {
                        deleteEmo();
                        i++;
                        if (text.isNotEmpty)
                          doDelete();
                        else
                          isLongPressDeleting = false;
                      });
                  }

                  doDelete();
                },
                onLongPressStart: (v) => isLongPress = true,
                onLongPressEnd: (v) => isLongPress = false,
                child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 2, 16, 2),
                    width: 100,
                    height: 30,
                    alignment: Alignment.centerRight,
                    child: const Icon(
                      Icons.backspace,
                      size: 20,
                    )),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _tabBarView() {
    if (_controller == null)
      return Container(
        height: 40,
        width: 40,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    return Container(
      color: OrientationUtil.portrait
          ? appThemeData.scaffoldBackgroundColor
          : Theme.of(context).backgroundColor,
      child: TabBarView(controller: _controller, children: [
        Scrollbar(
          child: GridView.builder(
            itemCount: EmoUtil.instance.curEmoList.length,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: OrientationUtil.portrait ? 7 : 9,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              final curEmo = EmoUtil.instance.curEmoList[index];
              return FadeButton(
                onTap: () {
                  final textStyle =
                      widget.insertTextStyle?.copyWith(fontSize: 17) ??
                          Theme.of(context)
                              .textTheme
                              .bodyText2
                              .copyWith(fontSize: 17);
                  controller.insertCusEmo(curEmo.id, textStyle: textStyle);

//                m.scrollController
//                    .jumpTo(m.scrollController.position.maxScrollExtent);
                  widget.callback?.call();
                },
                child: Tooltip(
                  message: curEmo.name,
                  child: EmoUtil.instance.getEmoIcon(curEmo.name, size: 24),
                ),
              );
            },
          ),
        ),
        if (isBuildSticker)
          ...EmoUtil.instance.buildTabViews(
              widget.parentContext ?? context, widget.inputModel),
      ]),
    );
  }

  TabBar _tabBar() {
    Widget _wrapper({Widget child, int index = 0}) {
      // final isSelected = _controller.index == index;
      // final color = kIsWeb ? _theme.backgroundColor : _theme.scaffoldBackgroundColor;
      return Container(
        height: 36,
        width: 36,
        // margin: const EdgeInsets.only(left: 8),
        alignment: Alignment.center,
        child: child,
      );
    }

    return TabBar(
        isScrollable: true,
        controller: _controller,
        labelColor: _theme.primaryColor,
        unselectedLabelColor: _theme.textTheme.bodyText1.color,
        indicatorColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 0,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        indicator: BoxDecoration(
          color: _theme.backgroundColor,
          borderRadius: BorderRadius.circular(5),
        ),
        tabs: [
          _wrapper(
            child: const Icon(
              IconFont.buffTabEmoji,
              size: 24,
            ),
          ),
          if (isBuildSticker)
            ...EmoUtil.instance.buildTabs(guildId,
                (child, index) => _wrapper(child: child, index: index + 1))
        ]);
  }

  void deleteEmo() {
    if (controller.useNativeInput) {
      if (controller.text.isEmpty) return;
      final lastChar = Characters(controller.text).last;
      controller.replaceRange(
        '',
        start: controller.text.length - lastChar.length,
        end: controller.text.length,
      );
    } else {
      final value = controller.rawFlutterController.value;
      final text = value.text;
      if (text.isEmpty) return;

      final char = Characters(text);

      ///最后一个为emoji时单独删除
      final last = char.last.trim();
      final isEmo = last.isNotEmpty &&
          last.runes.last != 8203 &&
          isAllEmo(Characters(last));
      if (isEmo) {
        controller.text = char.skipLast(1).toString();
        return;
      }

      ///否则走其他的删除逻辑
      final oldValue = value;
      final tempSelection = oldValue.selection;
      final os = tempSelection.copyWith(
          baseOffset: text.length, extentOffset: text.length);
      final ns = oldValue.selection.copyWith(
          baseOffset: os.baseOffset - 1, extentOffset: os.extentOffset - 1);
      final newValue = value.copyWith(
          selection: ns, text: text.substring(0, text.length - 1));
      final nv = newValue.copyWith(selection: ns);
      controller.rawFlutterController.value = nv;
    }
  }
}
