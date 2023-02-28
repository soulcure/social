import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:tuple/tuple.dart';

const minSizeConstraint = 75.0;
const maxSizeConstraint = 225.0;

Tuple3 _resizeDimen(double _width, double _height) {
  double width = _width ?? 75;
  width = width > 0 ? width : 75;
  double height = _height ?? 225;
  height = height > 0 ? height : 225;
  BoxFit fit = BoxFit.contain;
  if (width / height > 3) {
    // 横线长图
    height = height > maxSizeConstraint ? maxSizeConstraint : height;
    height = height < minSizeConstraint ? minSizeConstraint : height;
    width = height;
    fit = BoxFit.fitHeight;
  } else if (height / width > 3) {
    // 纵向长图
    width = width > maxSizeConstraint ? maxSizeConstraint : width;
    width = width < minSizeConstraint ? minSizeConstraint : width;
    height = width;
    fit = BoxFit.fitWidth;
  } else if (width > maxSizeConstraint || height > maxSizeConstraint) {
    final s = min(maxSizeConstraint / width, maxSizeConstraint / height);
    width = _width * s;
    height = _height * s;
  } else if (width < minSizeConstraint || height < minSizeConstraint) {
    final s = max(minSizeConstraint / width, minSizeConstraint / height);
    width = _width * s;
    height = _height * s;
  }
  return Tuple3(width, height, fit);
}

void main() {
  for (int i = 0; i < 100; i++) {
    final double width = Random().nextInt(10000) * 1.0;
    final double height = Random().nextInt(10000) * 1.0;
    final size = _resizeDimen(width, height);
    print(
        'width: $width height: $height - (${size.item1},${size.item2},${size.item3})');
  }
}
