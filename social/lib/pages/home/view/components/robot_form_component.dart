import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/themes/custom_color.dart';

import '../../../../routes.dart';

class RobotFormComponent extends StatefulWidget {
  final List<List<BotCommandParameter>> parameters;
  final String title;

  const RobotFormComponent(this.title, this.parameters);

  @override
  _RobotFormComponentState createState() => _RobotFormComponentState();
}

class _RobotFormComponentState extends State<RobotFormComponent> {
  List<List<TextEditingController>> textControllers;

  @override
  void initState() {
    textControllers = [];
    for (final a in widget.parameters) {
      textControllers.add([]);
      for (final _ in a) {
        textControllers.last.add(TextEditingController());
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    for (final a in textControllers) {
      for (final b in a) {
        b.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CustomColor(context).backgroundColor3,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    int colIndex = -1;
    int rowIndex = -1;
    final List<Widget> columnChildren = [
      AppBar(
        primary: false,
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.headline5,
        ),
        elevation: 0,
        actions: [
          CupertinoButton(
            onPressed: () {
              final value = textControllers
                  .fold<List<TextEditingController>>(
                      [],
                      (previousValue, element) =>
                          previousValue..addAll(element))
                  .map((e) => e.text)
                  .join(" ");
              Routes.pop(context, value);
            },
            child: Text(
              '完成'.tr,
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w500),
            ),
          )
        ],
      ),
      ...widget.parameters.map((row) {
        rowIndex++;
        colIndex = -1;

        final children = row.map((cell) {
          colIndex++;

          final inputBorder = OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFDEE0E3)),
              borderRadius: BorderRadius.circular(20));
          return Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cell.k,
                style: const TextStyle(
                    color: Color(0xFF1F2329),
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              SizedBox(
                  height: 40,
                  child: TextField(
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        hintText: "请输入".tr,
                        hintStyle: const TextStyle(
                            fontSize: 14, color: Color(0xFF8F959E)),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                      ),
                      controller: textControllers[rowIndex][colIndex])),
              const SizedBox(height: 16),
            ],
          ));
        });
        return Row(children: children.toList());
      }),
      const SizedBox(height: 24),
    ];
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columnChildren,
      ),
    );
  }
}
