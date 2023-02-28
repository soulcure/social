import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/icon_font.dart';
import 'package:im/web/widgets/popup/web_popup.dart';
import 'package:pedantic/pedantic.dart';
import 'package:provider/provider.dart';

import 'menu_button.dart';
import 'model.dart';

class MenuButton extends StatefulWidget {
  final CirclePostDataModel postData;
  final Color iconColor;
  final Function(MenuButtonType type, {List param}) onRequestSuccess;
  final Function(int code, MenuButtonType type) onRequestError;
  final EdgeInsets padding;
  final double size;
  final AlignmentGeometry iconAlign;

  const MenuButton(
      {Key key,
      @required this.postData,
      this.onRequestSuccess,
      this.iconColor,
      this.onRequestError,
      this.padding,
      this.size = 16,
      this.iconAlign = Alignment.topRight})
      : super(key: key);

  @override
  _MenuButtonState createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  MenuButtonModel _model;

  @override
  void initState() {
    _model = MenuButtonModel(
        data: widget.postData,
        onRequestSuccess: widget.onRequestSuccess,
        onRequestError: widget.onRequestError);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color1 = theme.textTheme.bodyText2.color;
    return ChangeNotifierProvider.value(
      value: _model,
      child: Selector<MenuButtonModel, bool>(
        selector: (_, model) => model.loading,
        builder: (context, loading, child) {
          if (loading)
            return Center(
              child: Container(
                padding: widget.padding ?? EdgeInsets.zero,
                alignment: Alignment.topRight,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          else
            return GestureDetector(
                onTap: onPress,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: widget.padding ?? EdgeInsets.zero,
                  alignment: widget.iconAlign,
                  child: Icon(
                    IconFont.buffMoreHorizontal,
                    size: widget.size,
                    color: widget.iconColor ?? color1,
                  ),
                ));
        },
      ),
    );
  }

  Future onPress() async {
    final List<SelectionAction> actions = [
      if (_model.canUnStick)
        SelectionAction(IconFont.buffChatUnstick, "取消置顶".tr, 2),
      if (_model.canStick)
        SelectionAction(IconFont.buffChatStick, "置顶动态".tr, 3),
      if (_model.canReport)
        SelectionAction(IconFont.buffCommonNoData, "举报".tr, 0),
      if (_model.canDel) SelectionAction(IconFont.buffChatDelete, "删除动态".tr, 1),
    ];
    final index = await showWebSelectionPopup(
      context,
      actions: actions,
    );
    if (index == 0) {
      _model.reportMessage(context);
    } else if (index == 1) {
      _model.deleteMessage(context);
    } else if (index == 2) {
      _model.unStickMessage(context);
    } else if (index == 3) {
      unawaited(_model.stickMessage(context));
    }
  }
}
