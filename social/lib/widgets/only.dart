import 'package:flutter/material.dart';

/// 显示其中一个
class Only extends StatelessWidget {
  final List<Widget> children;
  final int showIndex;
  const Only({
    @required this.children,
    this.showIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    assert(children != null && children.isNotEmpty);
    var index = showIndex;
    if (index >= children.length) {
      index = children.length - 1;
    } else if (showIndex < 0) {
      index = 0;
    }
    return children[index];
  }
}
