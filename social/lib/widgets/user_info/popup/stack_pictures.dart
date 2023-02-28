import 'package:flutter/material.dart';
import 'package:im/app/theme/app_theme.dart';

enum StackPictureType {
  circle,
  square,
}

class StackPictures extends StatelessWidget {
  final List<Widget> children;
  final int totalNum;
  final int maxDisplayNum;
  final double height;
  final BoxShape itemShape;
  final double itemRadius;
  const StackPictures({
    @required this.children,
    @required this.totalNum,
    this.maxDisplayNum = 4,
    this.height = 28,
    this.itemShape = BoxShape.circle,
    this.itemRadius = 6,
  });

  static const double _itemPadding = 2;

  @override
  Widget build(BuildContext context) {
    final int displayNum =
        children.length >= maxDisplayNum ? maxDisplayNum : children.length;
    final double _width = displayNum * height - (displayNum - 1) * 10.0;
    final List<Widget> _list = [];
    for (var i = 0; i < displayNum; i++) {
      Widget item;
      if (i == maxDisplayNum - 1 && totalNum > maxDisplayNum) {
        item = Container(
            width: height,
            height: height,
            decoration: BoxDecoration(
              shape: itemShape,
              borderRadius: itemShape == BoxShape.circle
                  ? null
                  : BorderRadius.all(Radius.circular(itemRadius)),
              border: Border.all(
                  color: appThemeData.backgroundColor, width: _itemPadding),
              color: appThemeData.scaffoldBackgroundColor,
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: appThemeData.dividerColor.withOpacity(.2),
                  width: .5,
                ),
                borderRadius: itemShape == BoxShape.circle
                    ? null
                    : BorderRadius.all(Radius.circular(itemRadius)),
                shape: itemShape,
                color: appThemeData.scaffoldBackgroundColor,
              ),
              alignment: Alignment.center,
              width: height - 4,
              height: height - 4,
              child: Text(
                totalNum - (maxDisplayNum - 1) <= 99
                    ? '+${totalNum - (maxDisplayNum - 1)}'
                    : '99+',
                style: appThemeData.textTheme.bodyText1.copyWith(fontSize: 11),
              ),
            ));
      } else {
        item = Container(
            decoration: BoxDecoration(
              shape: itemShape,
              border: Border.all(
                  color: appThemeData.backgroundColor, width: _itemPadding),
              borderRadius: itemShape == BoxShape.circle
                  ? null
                  : BorderRadius.all(Radius.circular(itemRadius)),
              // color: appThemeData.backgroundColor,
            ),
            child: children[i]);
      }
      _list.add(Positioned(
        // top: paddingTop,
        // bottom: paddingBottom,
        left: i * 16.0,
        child: item,
      ));
    }
    return Container(
      alignment: Alignment.centerLeft,
      width: _width,
      height: height,
      child: Stack(children: _list),
    );
  }
}
