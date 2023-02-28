import 'package:flutter/material.dart';

class Crop extends StatefulWidget {
  final Widget child;
  final CropController cropController;

  const Crop({
    this.child,
    this.cropController,
  });

  @override
  _CropState createState() => _CropState();
}

class _CropState extends State<Crop> {
//  CropShape shape = CropShape.box;
  Offset _offset = Offset.zero;
  Offset _preOffset;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Matrix4 get transform => Matrix4.identity()
    ..translate(_offset.dx, _offset.dy, 0)
    ..scale(1, 1, 1);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: GestureDetector(
        onScaleStart: (details) {
          _preOffset = details.focalPoint;
        },
        onScaleUpdate: (details) {
          _offset += details.focalPoint - _preOffset;
          _preOffset = details.focalPoint;
          setState(() {});
        },
        onScaleEnd: (details) {},
        child: CustomSingleChildLayout(
            delegate: const _CenterWithOriginalSizeDelegate(
              Size(444, 274),
              Alignment.center,
              true,
            ),
            child: Transform(
              transform: transform,
              child: widget.child,
            )),
//        child: Transform(
//          transform: transform,
//          child: widget.child,
//        ),
      ),
    );
  }
}

class CropController extends ChangeNotifier {}

class _CenterWithOriginalSizeDelegate extends SingleChildLayoutDelegate {
  const _CenterWithOriginalSizeDelegate(
    this.subjectSize,
    this.basePosition,
    this.useImageScale,
  );

  final Size subjectSize;
  final Alignment basePosition;
  final bool useImageScale;

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final childWidth = useImageScale ? childSize.width : subjectSize.width;
    final childHeight = useImageScale ? childSize.height : subjectSize.height;

    final halfWidth = (size.width - childWidth) / 2;
    final halfHeight = (size.height - childHeight) / 2;

    final double offsetX = halfWidth * (basePosition.x + 1);
    final double offsetY = halfHeight * (basePosition.y + 1);
    return Offset(offsetX, offsetY);
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return useImageScale
        ? const BoxConstraints()
        : BoxConstraints.tight(subjectSize);
  }

  @override
  bool shouldRelayout(_CenterWithOriginalSizeDelegate oldDelegate) {
    return oldDelegate != this;
  }

//  @override
//  bool operator ==(Object other) =>
//      identical(this, other) ||
//      other is _CenterWithOriginalSizeDelegate &&
//          runtimeType == other.runtimeType &&
//          subjectSize == other.subjectSize &&
//          basePosition == other.basePosition &&
//          useImageScale == other.useImageScale;
//
//  @override
//  int get hashCode =>
//      subjectSize.hashCode ^ basePosition.hashCode ^ useImageScale.hashCode;
}
