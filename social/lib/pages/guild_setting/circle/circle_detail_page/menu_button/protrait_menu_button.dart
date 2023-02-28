import 'package:flutter/material.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/icon_font.dart';
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
  final CallbackBuilder callbackBuilder;

  const MenuButton({
    Key key,
    @required this.postData,
    this.onRequestSuccess,
    this.iconColor,
    this.onRequestError,
    this.padding,
    this.size = 16,
    this.iconAlign = Alignment.topRight,
    this.callbackBuilder,
  }) : super(key: key);

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
      onRequestError: widget.onRequestError,
    );
    super.initState();
  }

  @override
  void didUpdateWidget(MenuButton oldWidget) {
    if (_model.data != widget.postData) {
      _model = MenuButtonModel(
        data: widget.postData,
        onRequestSuccess: widget.onRequestSuccess,
        onRequestError: widget.onRequestError,
      );
    }
    super.didUpdateWidget(oldWidget);
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
                onTap: () {
                  _model.showCircleDetailMenu(context);
                },
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
}
