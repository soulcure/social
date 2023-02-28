// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:im/app/theme/app_theme.dart';

class RedPackTransitionConfiguration extends ModalConfiguration {
  RedPackTransitionConfiguration({Duration transitionDuration})
      : super(
          barrierColor: appThemeData.backgroundColor.withOpacity(0.75),
          barrierDismissible: true,
          barrierLabel: "Dismiss",
          transitionDuration: transitionDuration,
          reverseTransitionDuration: const Duration(milliseconds: 200),
        );

  @override
  Widget transitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeScaleTransition(
      animation: animation,
      child: child,
    );
  }
}

class FadeScaleTransition extends StatelessWidget {
  const FadeScaleTransition({
    Key key,
    @required this.animation,
    this.child,
  }) : super(key: key);

  final Animation<double> animation;

  final Widget child;

  static final Animatable<double> _fadeInTransition = CurveTween(
    curve: const Interval(0, 0.3),
  );
  static final Animatable<double> _scaleInTransition = Tween<double>(
    begin: 0.80,
    end: 1,
  ).chain(CurveTween(curve: Curves.elasticOut));
  static final Animatable<double> _fadeOutTransition = Tween<double>(
    begin: 1,
    end: 0,
  );
  static final Animatable<double> _scaleOutTransition = Tween<double>(
    begin: 1,
    end: 0,
  );

  @override
  Widget build(BuildContext context) {
    return DualTransitionBuilder(
      animation: animation,
      forwardBuilder: (
        context,
        animation,
        child,
      ) {
        return FadeTransition(
          opacity: _fadeInTransition.animate(animation),
          child: ScaleTransition(
            scale: _scaleInTransition.animate(animation),
            child: child,
          ),
        );
      },
      reverseBuilder: (
        context,
        animation,
        child,
      ) {
        return FadeTransition(
          opacity: _fadeOutTransition.animate(animation),
          child: ScaleTransition(
            scale: _scaleOutTransition.animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
