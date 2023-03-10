import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../icon_font.dart';

class FBCheckBox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const FBCheckBox({Key key, this.value = false, this.onChanged})
      : super(key: key);

  @override
  _FBCheckBoxState createState() => _FBCheckBoxState();
}

class _FBCheckBoxState extends State<FBCheckBox> {
  bool _isCheck = false;

  @override
  void initState() {
    _isCheck = widget.value;
    super.initState();
  }

  @override
  void didUpdateWidget(FBCheckBox oldWidget) {
    if (oldWidget.value != widget.value) _isCheck = widget.value;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    const normalColor = Color(0x595C6273);
    final selectedColor = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: () {
        widget.onChanged?.call(!_isCheck);
        setState(() {});
      },
      child: _isCheck
          ? Icon(
              IconFont.buffSelectGroup,
              size: 20,
              color: selectedColor,
            )
          : const Icon(
              IconFont.buffUnselectGroup,
              size: 20,
              color: normalColor,
            ),
    );
  }
}
