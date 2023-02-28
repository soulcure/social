import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:im/pages/home/view/bottom_bar/text_chat_bottom_bar.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:tun_editor/controller.dart';

class KeyboardContainer2 extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final double childHeight;
  final ValueNotifier<KeyboardStatus> expand;
  final FocusNode titleFocusNode;
  final FocusNode editorFocusNode;
  final TunEditorController editorController;

  const KeyboardContainer2(
      {@required this.builder,
      @required this.childHeight,
      @required this.expand,
      @required this.titleFocusNode,
      @required this.editorFocusNode,
      this.editorController});

  @override
  _KeyboardContainer2State createState() => _KeyboardContainer2State();
}

/// 隐藏、拓展键盘、输入键盘
enum KeyboardStatus {
  hide,
  extend_keyboard,
  input_keyboard,
}

class _KeyboardContainer2State extends State<KeyboardContainer2>
    with SingleTickerProviderStateMixin {
  Stream<bool> get onChange => _keyboardController.onChange;
  StreamSubscription _keyboardSubscription;

  double _keyboardHeight = 0; //键盘高度
  final _bottomInset = getBottomViewInset();

  /// animation
  AnimationController _animationController;
  Animation _animation;

  KeyboardVisibilityController _keyboardController;

  /// extend index record
  FocusIndex preselectIndex = FocusIndex.none;
  void _animateTo(double to) {
    if (_animation.status == AnimationStatus.forward)
      _animationController.stop();
    _animation = Tween<double>(begin: _animation.value * 1.0, end: to).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.easeOutCirc));

    _animationController
      ..value = 0.0
      ..forward();
  }

  void animateTo(KeyboardStatus status) {
    if (_animationController == null) return;
    switch (status) {
      case KeyboardStatus.hide:
        _animateTo(_bottomInset);
        break;
      case KeyboardStatus.extend_keyboard:
        _animateTo(widget.childHeight + _bottomInset);
        break;
      case KeyboardStatus.input_keyboard:
        if (_keyboardHeight == 0)
          Future.delayed(const Duration(milliseconds: 200))
              .then((value) => _animateTo(_keyboardHeight));
        else
          _animateTo(_keyboardHeight);
        break;
    }
  }

  void _shouldUpdateKeyboardHeight() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    _keyboardHeight = bottomInset == 0 ? _keyboardHeight : bottomInset;
    if (widget.expand.value == KeyboardStatus.input_keyboard &&
        ((widget.titleFocusNode?.hasFocus ?? false) ||
            (widget.editorFocusNode?.hasFocus ?? false)))
      animateTo(KeyboardStatus.input_keyboard);
  }

  @override
  void initState() {
    _keyboardController = KeyboardVisibilityController();
    _animationController =
        AnimationController(duration: kThemeAnimationDuration, vsync: this);
    _animation = Tween(begin: _bottomInset, end: widget.childHeight)
        .animate(_animationController);

    widget.expand.addListener(() async {
      final expand = widget.expand.value;
      animateTo(expand);
    });
    _keyboardSubscription = onChange.listen((event) {
      if (event) {
        animateTo(KeyboardStatus.input_keyboard);
      } else if (!widget.editorFocusNode.hasFocus) {
        widget.editorFocusNode?.unfocus();
        widget.titleFocusNode?.unfocus();
        animateTo(widget.expand.value == KeyboardStatus.extend_keyboard
            ? KeyboardStatus.extend_keyboard
            : KeyboardStatus.hide);
      } else if (UniversalPlatform.isAndroid) {
        //iOS 的原生输入框有做焦点处理，这里需要去主动触发外包输入框的焦点获取，不然会失焦
        widget.editorController?.focus();
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _animationController = null;
    _keyboardSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _shouldUpdateKeyboardHeight();
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
            color: Theme.of(context).backgroundColor,
            child: SizedBox(
              height: widget.childHeight,
              child: widget.builder(context),
            ),
          );
        },
      ),
    );
  }
}
