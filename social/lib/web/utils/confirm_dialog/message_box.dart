import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/utils/confirm_dialog/base_dialog.dart';

import '../../../icon_font.dart';

Future<bool> showWebMessageBox({
  @required String title,
  String content,
  Icon icon,
  double width = 400,
  double height,
  String confirmText = '确定',
  TextStyle confirmStyle,
  String cancelText = '取消',
  Function onCancel,
  Function onConfirm,
  bool showCancelButton = true,
  bool showCloseIcon = false,
}) async {
  return Get.dialog(
    WebMessageBox(
      title: title,
      content: content,
      icon: icon,
      width: width,
      height: height,
      confirmText: confirmText,
      confirmStyle: confirmStyle,
      cancelText: cancelText,
      onCancel: onCancel,
      onConfirm: onConfirm,
      showCancelButton: showCancelButton,
      showCloseIcon: showCloseIcon,
    ),
    barrierDismissible: false,
  );
}

class WebMessageBox extends StatefulWidget {
  final String title;
  final String content;
  final Icon icon;
  final double width;
  final double height;
  final bool showCloseIcon;
  final String confirmText;
  final String cancelText;
  final TextStyle confirmStyle;
  final Function onCancel;
  final Function onConfirm;
  final bool showCancelButton;

  const WebMessageBox({
    @required this.title,
    this.content,
    this.icon,
    this.width = 400,
    this.height,
    this.showCloseIcon = true,
    this.confirmText = '确定',
    this.cancelText = '取消',
    this.confirmStyle,
    this.onCancel,
    this.onConfirm,
    this.showCancelButton,
  });

  @override
  _WebMessageBoxState createState() => _WebMessageBoxState();
}

class _WebMessageBoxState extends State<WebMessageBox> {
  @override
  Widget build(BuildContext context) {
    return WebBaseDialog(
      width: widget.width,
      height: widget.height,
      header: _header(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isNotNullAndEmpty(widget.content))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.content.tr,
                style: Theme.of(context).textTheme.bodyText1,
              ),
            ),
          sizeHeight12,
        ],
      ),
      footer: _footer(),
    );
  }

  Widget _header() {
    final _theme = Theme.of(context);
    return Row(
      children: [
        widget.icon ??
            Icon(
              IconFont.buffChatError,
              size: 20,
              color: _theme.errorColor,
            ),
        sizeWidth8,
        Expanded(
          child: Text(
            widget.title.tr ?? "",
            style: _theme.textTheme.bodyText2
                .copyWith(fontSize: 16, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        )
      ],
    );
  }

  Widget _footer() {
    final _theme = Theme.of(context);
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        SizedBox(
          width: 88,
          height: 32,
          child: TextButton(
              onPressed:
                  widget.onConfirm ?? () => Navigator.of(context).pop(true),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _theme.errorColor,
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.confirmText.tr,
                  style: widget.confirmStyle ??
                      _theme.textTheme.bodyText2.copyWith(color: Colors.white),
                ),
              )),
        ),
        sizeWidth16,
        if (widget.showCancelButton)
          SizedBox(
            width: 88,
            height: 32,
            child: TextButton(
                onPressed:
                    widget.onCancel ?? () => Navigator.of(context).pop(false),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: Theme.of(context).dividerTheme.color),
                    color: _theme.backgroundColor,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.cancelText.tr,
                    style: _theme.textTheme.bodyText2,
                  ),
                )),
          ),
      ],
    );
  }
}
