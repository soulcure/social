import 'package:flutter/material.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/default_theme.dart';

class CheckSquareBox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CheckSquareBox({Key key, this.value = false, this.onChanged})
      : super(key: key);

  @override
  _CheckSquareBoxState createState() => _CheckSquareBoxState();
}

class _CheckSquareBoxState extends State<CheckSquareBox> {
  bool _isCheck = false;

  @override
  void initState() {
    _isCheck = widget.value;
    super.initState();
  }

  @override
  void didUpdateWidget(CheckSquareBox oldWidget) {
    if (oldWidget.value != widget.value) _isCheck = widget.value;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: GestureDetector(
        onTap: () {
          _isCheck = !_isCheck;
          widget.onChanged?.call(_isCheck);
          setState(() {});
        },
        child: _isCheck
            ? Icon(
                IconFont.buffSelectCheck,
                size: 22,
                color: primaryColor,
              )
            : Icon(
                IconFont.buffSelectUncheck,
                size: 22,
                color: Theme.of(context).iconTheme.color.withOpacity(.5),
              ),
      ),
    );
  }
}
