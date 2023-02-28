import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ScanLine extends StatefulWidget {
  final double width;
  final Duration duration;
  final double from;
  final double to;

  const ScanLine({
    Key key,
    this.width,
    this.duration,
    this.from,
    this.to,
  }) : super(key: key);

  @override
  _ScanLineState createState() => _ScanLineState();
}

class _ScanLineState extends State<ScanLine> with TickerProviderStateMixin {
  double width, height;
  AnimationController controller;
  Animation<Offset> anim;

  @override
  void initState() {
    super.initState();
    width = widget.width ?? window.physicalSize.width;
    height = width * 0.1;
    controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? const Duration(seconds: 3),
    )..repeat();
    final from = (widget.from ?? 0) / height;
    final to = (widget.to ?? width) / height;
    anim = Tween<Offset>(
      begin: Offset(0, from),
      end: Offset(0, to),
    ).animate(controller);
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: anim,
      child: _buildScanLine(),
    );
  }

  Widget _buildScanLine() {
    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        fit: BoxFit.fill,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Get.theme.primaryColor,
                Get.theme.primaryColor.withOpacity(0),
              ],
              stops: const [0, 1.0],
              center: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
