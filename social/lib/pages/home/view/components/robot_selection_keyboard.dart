import 'package:flutter/material.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/widgets/image.dart';

class RobotSelectionKeyboard extends StatefulWidget {
  final List<List<BotCommandParameter>> parameters;

  const RobotSelectionKeyboard(this.parameters);

  @override
  _RobotSelectionKeyboardState createState() => _RobotSelectionKeyboardState();
}

class _RobotSelectionKeyboardState extends State<RobotSelectionKeyboard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CustomColor(context).backgroundColor3,
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildGrid(context),
    );
  }

  Column _buildGrid(BuildContext context) {
    final List<Widget> rows = [];
    for (final row in widget.parameters) {
      final List<Widget> children = [];
      for (final cell in row) {
        children.add(Expanded(
            child: FadeButton(
          onTap: () {
            Navigator.of(context).pop(cell.v);
          },
          child: cell.icon != null
              ? _buildCellWithIcon(cell)
              : _buildCellJustText(cell),
        )));
        if (cell != row.last) children.add(const SizedBox(width: 16));
      }
      rows.add(Row(children: children.toList()));
      if (row != widget.parameters.last) rows.add(const SizedBox(height: 16));
    }
    return Column(children: rows);
  }

  Widget _buildCellWithIcon(BotCommandParameter cell) {
    return Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xffDEE0E3))),
        alignment: Alignment.center,
        child: Column(
          children: [
            if (cell.icon != null)
              AspectRatio(
                  aspectRatio: 163.5 / 122.5,
                  child: NetworkImageWithPlaceholder(
                    cell.icon,
                    imageBuilder: (_, image) {
                      return Container(
                          decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8)),
                              image: DecorationImage(
                                  image: image, fit: BoxFit.cover)));
                    },
                  )),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                height: 34,
                child: Text(
                  cell.k,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFF1F2329),
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                )),
          ],
        ));
  }

  Widget _buildCellJustText(BotCommandParameter cell) {
    return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        // margin: const EdgeInsets.all(2.5),
        alignment: Alignment.center,
        decoration: const ShapeDecoration(
          shape: StadiumBorder(),
          color: Color(0xFFDEE0E3),
        ),
        child: Text(
          cell.k,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ));
  }
}
