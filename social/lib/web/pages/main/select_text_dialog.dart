import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/themes/const.dart';

import '../../../icon_font.dart';

Future showSelectTextDialog(
  BuildContext context, {
  @required String content,
}) async {
  return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return SelectTextDialog(
          content: content,
        );
      });
}

class SelectTextDialog extends StatefulWidget {
  final String content;

  const SelectTextDialog({
    @required this.content,
  });

  @override
  _SelectTextDialogState createState() => _SelectTextDialogState();
}

class _SelectTextDialogState extends State<SelectTextDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    final double top = (MediaQuery.of(context).size.height - 340) / 2;
    final double left = (MediaQuery.of(context).size.width - 440) / 2;
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          margin: EdgeInsets.fromLTRB(
              left.ceil().toDouble(), top.ceil().toDouble(), 0, 0),
          child: Container(
            width: 440,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _theme.backgroundColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 24),
                    child: _header()),
                divider,
                _body(),
              ],
            ),
          ),
        ));
  }

  Widget _header() {
    final _theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              "文字内容".tr,
              style: _theme.textTheme.bodyText2
                  .copyWith(fontSize: 16, fontWeight: FontWeight.w500),
            )
          ],
        ),
        SizedBox(
          width: 24,
          height: 24,
          child: TextButton(
              onPressed: Get.back,
              child: Icon(
                IconFont.buffNavBarCloseItem,
                size: 16,
                color: _theme.textTheme.bodyText1.color,
              )),
        ),
      ],
    );
  }

  Widget _body() {
    _controller.text = widget.content;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        widget.content,
        maxLines: 10,
        scrollPhysics: const ClampingScrollPhysics(),
      ),
    );
  }
}
