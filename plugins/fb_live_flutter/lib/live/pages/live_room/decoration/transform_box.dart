import 'dart:math' as math;

import 'package:flutter/material.dart';

class TransformBox extends StatelessWidget {
  final bool isTransForm;
  final Widget? child;

  const TransformBox(this.isTransForm, {this.child});

  @override
  Widget build(BuildContext context) {
    return isTransForm
        ? Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(math.pi),
            child: AbsorbPointer(
              child: child,
            ),
          )
        : child!;
  }
}
