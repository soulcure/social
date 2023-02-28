import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:im/icon_font.dart';

const List<Color> _colors = [
  Color(0xFF06A8F4),
  Color(0xFF1375F2),
  Color(0xFF6179F2),
  Color(0xFF5560DD),
  Color(0xFF00CBCC),
  Color(0xFF14C79D),
  Color(0xFFFFD500),
  Color(0xFFFFA526),
  Color(0xFFFF8127),
  Color(0xFFFF4080),
  Color(0xFFF24965),
  Color(0xFFFF5000),
  Color(0xFF98A9FF),
  Color(0xFF9898FF),
  Color(0xFF6D7FDA),
  Color(0xFF9966FF),
  Color(0xFF7E00FC),
  Color(0xFFA3A8BF),
];

typedef OnPickColor = Function(Color color);

class ColorPicker extends StatefulWidget {
  final int value;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final OnPickColor onPickColor;

  const ColorPicker(
      {this.value,
      this.onPickColor,
      this.crossAxisCount = 7,
      this.mainAxisSpacing = 20,
      this.crossAxisSpacing = 20});

  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  int colorValue;

  @override
  void initState() {
    super.initState();

    colorValue = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _colors.length,
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          mainAxisSpacing: widget.mainAxisSpacing,
          crossAxisSpacing: widget.crossAxisSpacing,
        ),
        itemBuilder: (context, index) {
          //Widget Function(BuildContext context, int index)
          return _buildItem(_colors[index]);
        });
  }

  Widget _buildItem(Color color) {
    return GestureDetector(
      onTap: () {
        widget.onPickColor(color);
        colorValue = color.value;
        if (color.value == colorValue) {
          return;
        }
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        child: Color(color.value).value != Color(colorValue).value
            ? const SizedBox()
            : LayoutBuilder(builder: (context, constraint) {
                return Icon(IconFont.buffAudioVisualRight,
                    color: Colors.white, size: constraint.biggest.height);
              }),
      ),
    );
  }
}
