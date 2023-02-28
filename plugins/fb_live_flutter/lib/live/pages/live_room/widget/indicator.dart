import 'package:flutter/material.dart';

class Indicator extends StatelessWidget {
  const Indicator({
    this.itemCount = 0,
    this.selectIndex = 0,
  });

  /// 指示器的个数
  final int itemCount;

  /// 普通的颜色
  static Color normalColor = const Color(0xFF1C2040);

  /// 选中的颜色
  static Color selectedColor = const Color(0xFF30397A);

  /// 点的大小
  static double size = 8;

  /// 点的间距
  static double spacing = 4;

  final int selectIndex;

  /// 点的Widget
  Widget _buildIndicator(
      int index, int pageCount, double dotSize, double spacing) {
    // 是否是当前页面被选中
    final bool isCurrentPageSelected =
        index == (selectIndex.round() % pageCount);

    return Container(
      alignment: Alignment.center,
      height: size,
      width: size + (2 * spacing),
      child: Material(
        color: isCurrentPageSelected ? selectedColor : normalColor,
        type: MaterialType.circle,
        child: SizedBox(
          width: dotSize,
          height: dotSize,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(itemCount, (index) {
        return _buildIndicator(index, itemCount, size, spacing);
      }),
    );
  }
}
