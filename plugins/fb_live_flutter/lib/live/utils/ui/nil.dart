import 'package:flutter/widgets.dart';

/// 一个 [Nil] 实例, 可以用在你的布局中.
const nil = Nil();

/// 这个 Widget 不做任何事情.
/// 当你要返回个 Widget 但又不能返回 null 的时候，非常适合.
class Nil extends Widget {
  /// Creates a [Nil] widget.
  const Nil({Key? key}) : super(key: key);

  @override
  Element createElement() => _NilElement(this);
}

class _NilElement extends Element {
  _NilElement(Nil widget) : super(widget);

  @override
  bool get debugDoingBuild => false;

  @override
  void performRebuild() {}
}
