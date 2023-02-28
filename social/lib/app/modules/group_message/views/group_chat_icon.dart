import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';

int row = 0, column = 0;

// 群聊九宫格头像
class GroupChatIcon extends StatelessWidget {
  const GroupChatIcon(this.avatars,
      {Key key, this.size = 48, this.iconPadding = 1.0, this.iconMargin = 0.0})
      : assert(avatars != null),
        super(key: key);

  final List<DmGroupRecipientIcon> avatars;
  final double size;
  final double iconPadding;
  final double iconMargin;

  @override
  Widget build(BuildContext context) {
    final childCount = avatars.length >= 9 ? 9 : avatars.length;
    int columnMax;
    final List<Widget> icons = [];
    final List<Widget> stacks = [];
    final ratio = MediaQuery.of(context).devicePixelRatio;
    row = 0;
    column = 0;

    // 五张图片之后（包含5张），每行的最大列数是3
    double imgWidth;
    if (childCount == 0) {
      return Container(
        width: size,
        height: size,
        color: Colors.grey,
      );
    } else if (childCount == 1) {
      columnMax = 1;
      imgWidth = size / sqrt2;
    } else if (childCount > 1 && childCount < 5) {
      columnMax = 2;
      imgWidth =
          (size - (iconPadding * (columnMax - 1)) - iconMargin) / columnMax;
    } else if (childCount >= 5) {
      columnMax = 3;
      imgWidth = (size - (iconPadding * columnMax) - iconMargin) / columnMax;
    }

    for (var i = 0; i < childCount; i++) {
      icons.add(_groupChatChildIcon(avatars[i].avatar, imgWidth, ratio));
    }

    var centerTop = 0.0;
    if (childCount == 2 || childCount == 5 || childCount == 6) {
      centerTop = imgWidth / 2;
    }
    for (var i = 0; i < childCount; i++) {
      double left;
      double top;
      if (childCount == 1) {
        left = top = (size - imgWidth) / 2;
      } else {
        left = imgWidth * row + iconPadding * row;
        top = imgWidth * column + iconPadding * column + centerTop;
      }
      switch (childCount) {
        case 3:
        case 7:
          _topOneIcon(stacks, icons[i], childCount, i, imgWidth, left, top);
          break;
        case 5:
        case 8:
          _topTwoIcon(stacks, icons[i], childCount, i, imgWidth, left, top);
          break;
        default:
          _otherIcon(
              stacks, icons[i], childCount, i, imgWidth, left, top, columnMax);
          break;
      }
    }
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFE0E2E6),
      // padding: const EdgeInsets.all(2),
      alignment: AlignmentDirectional.bottomCenter,
      child: Stack(
        children: stacks,
      ),
    );
  }

  Widget _groupChatChildIcon(String avatar, double width, double ratio) {
    return ContainerImage(avatar,
        width: width,
        height: width,
        thumbHeight: (width * ratio).toInt(),
        thumbWidth: (width * ratio).toInt(),
        fit: BoxFit.fill);
  }

// 顶部为一张图片
  void _topOneIcon(List<Widget> stacks, Widget child, int childCount, i,
      imgWidth, left, top) {
    if (i == 0) {
      var firstLeft = imgWidth / 2 + left + iconMargin / 2;
      if (childCount == 7) {
        firstLeft = imgWidth + left + iconMargin;
      }
      stacks.add(Positioned(
        left: firstLeft,
        child: child,
      ));
      row = 0;
      // 换行
      column++;
    } else {
      stacks.add(Positioned(
        left: left,
        top: top,
        child: child,
      ));
      // 换列
      row++;
      if (i == 3) {
        // 第一例
        row = 0;
        // 换行
        column++;
      }
    }
  }

// 顶部为两张图片
  void _topTwoIcon(List<Widget> stacks, Widget child, int childCount, i,
      imgWidth, left, top) {
    if (i == 0 || i == 1) {
      stacks.add(Positioned(
        left: imgWidth / 2 + left + iconMargin / 2,
        top: childCount == 5 ? top : 0.0,
        child: child,
      ));
      row++;
      if (i == 1) {
        row = 0;
        // 换行
        column++;
      }
    } else {
      stacks.add(Positioned(
        left: left,
        top: top,
        child: child,
      ));
      // 换列
      row++;
      if (i == 4) {
        // 第一例
        row = 0;
        // 换行
        column++;
      }
    }
  }

  void _otherIcon(List<Widget> stacks, Widget child, int childCount, i,
      imgWidth, left, top, columnMax) {
    stacks.add(Positioned(
      left: left,
      top: top,
      child: child,
    ));
    // 换列
    row++;
    if ((i + 1) % columnMax == 0) {
      // 第一例
      row = 0;
      // 换行
      column++;
    }
  }
}
