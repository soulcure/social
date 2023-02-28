import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:im/pages/home/view/bottom_bar/text_chat_bottom_bar.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/cache_widget.dart';

class KeyboardContainer extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final double childHeight;
  final FocusNode focusNode;
  final ValueNotifier<FocusIndex> selectIndex;
  final Color backgroundColor;

  const KeyboardContainer({
    @required this.builder,
    @required this.childHeight,
    @required this.focusNode,
    @required this.selectIndex,
    this.backgroundColor,
  });

  @override
  _KeyboardContainerState createState() => _KeyboardContainerState();
}

/// 隐藏、拓展键盘、输入键盘
enum KeyboardStatus {
  hide,
  extend_keyboard,
  input_keyboard,
  // 附着在输入法之上，频道快捷指令列表使用
  sticky_input_keyboard,
}

class _KeyboardContainerState extends State<KeyboardContainer>
    with SingleTickerProviderStateMixin {
  Stream<bool> get onChange => _keyboardController.onChange;
  double _keyboardHeight = 0; //键盘高度
  final _bottomInset = getBottomViewInset();

  /// animation
  AnimationController _animationController;
  Animation _animation;

  /// extend index record
  FocusIndex preselectIndex = FocusIndex.none;
  KeyboardStatus _currentStatus = KeyboardStatus.hide;
  StreamSubscription _onChangeSub;

  KeyboardVisibilityController _keyboardController;
  void animateTo(KeyboardStatus status) {
    void _animateTo(double to) {
      _animation = Tween<double>(begin: _animation.value * 1.0, end: to)
          .animate(CurvedAnimation(
              parent: _animationController, curve: Curves.easeOutCirc));
      _animationController
        ..value = 0.0
        ..forward();
    }

    if (_animationController == null) return;
    switch (status) {
      case KeyboardStatus.hide:
        _animateTo(_bottomInset);
        break;
      case KeyboardStatus.extend_keyboard:
        _animateTo(widget.childHeight + _bottomInset);
        break;
      case KeyboardStatus.input_keyboard:
        if (_keyboardHeight != 0) {
          _animateTo(_keyboardHeight);
        }
        break;
      case KeyboardStatus.sticky_input_keyboard:
        final mq = MediaQuery.of(context);
        final bottomInset = mq.viewInsets.bottom + mq.padding.bottom;
        _animateTo(bottomInset);
        break;
    }
    _currentStatus = status;
  }

  void _shouldUpdateBottomSize() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    if (bottomInset != 0) {
      final preKeyboardHeight = _keyboardHeight;
      _keyboardHeight = bottomInset;

      /// 键盘发生高度变化后处理
      if (_currentStatus == KeyboardStatus.input_keyboard &&
          preKeyboardHeight != bottomInset)
        animateTo(KeyboardStatus.input_keyboard);
    }
  }

  @override
  void initState() {
    _keyboardController = KeyboardVisibilityController();

    /// init animation
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 250), vsync: this);
    _animation = Tween(begin: _bottomInset, end: widget.childHeight)
        .animate(_animationController);

    /// add listener
    widget.selectIndex?.addListener(() async {
      final value = widget.selectIndex.value;
      if (value == FocusIndex.none) {
        if (preselectIndex == FocusIndex.robotCmds &&
            widget.focusNode.hasFocus) {
          animateTo(KeyboardStatus.sticky_input_keyboard);
        } else if (preselectIndex != FocusIndex.at)
          animateTo(KeyboardStatus.hide);
      } else if (value == FocusIndex.at) {
        if (widget.focusNode.hasFocus)
          animateTo(KeyboardStatus.input_keyboard);
        else
          animateTo(KeyboardStatus.hide);
      } else if (value == FocusIndex.robotCmds) {
        animateTo(KeyboardStatus.sticky_input_keyboard);
      } else {
        animateTo(KeyboardStatus.extend_keyboard);
      }
      preselectIndex = value;
    });

    _onChangeSub = onChange.listen((event) {
      if (event) {
        if (widget.focusNode.hasFocus) animateTo(KeyboardStatus.input_keyboard);
      } else {
        animateTo((widget.selectIndex.value != FocusIndex.none &&
                widget.selectIndex.value != FocusIndex.at &&
                widget.selectIndex.value != FocusIndex.robotCmds)
            ? KeyboardStatus.extend_keyboard
            : KeyboardStatus.hide);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _animationController = null;
    _onChangeSub?.cancel();
    _onChangeSub = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _shouldUpdateBottomSize();

    return CacheWidget(builder: () {
      return GestureDetector(
        onHorizontalDragStart: (_) {},
        onHorizontalDragCancel: () {},
        onHorizontalDragUpdate: (_) {},
        onHorizontalDragDown: (_) {},
        onHorizontalDragEnd: (_) {},
        onTap: () {},
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              height: _animation.value * 1.0,
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.topCenter,
              color:
                  widget.backgroundColor ?? Theme.of(context).backgroundColor,
              child: SizedBox(
                height: widget.childHeight,
                child: widget.builder(context),
              ),
            );
          },
        ),
      );
    });
  }
}
