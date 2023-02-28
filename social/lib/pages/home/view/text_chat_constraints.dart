import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// 保存聊天公屏布局参数以及context
class TextChatConstraints extends InheritedWidget {
  final BuildContext context;
  final BoxConstraints constraints;
  const TextChatConstraints({
    Key key,
    @required this.context,
    @required this.constraints,
    @required Widget child,
  })  : assert(constraints != null),
        assert(child != null),
        super(key: key, child: child);
  static TextChatConstraints of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TextChatConstraints>();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }
}
