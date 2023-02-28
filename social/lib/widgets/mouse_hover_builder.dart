import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:im/utils/orientation_util.dart';

class MouseHoverBuilder extends StatelessWidget {
  final Widget Function(BuildContext, bool) builder;
  final SystemMouseCursor cursor;

  MouseHoverBuilder({
    this.builder,
    this.cursor = SystemMouseCursors.basic,
  });

  final ValueNotifier _value = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    if (OrientationUtil.portrait) return builder(context, false);
    return MouseRegion(
      onEnter: (_) => _value.value = true,
      onExit: (_) => _value.value = false,
      cursor: cursor,
      child: ValueListenableBuilder(
        valueListenable: _value,
        builder: (context, value, child) {
          return builder(context, value);
        },
      ),
    );
  }
}
