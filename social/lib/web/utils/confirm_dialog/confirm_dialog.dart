import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/themes/const.dart';
import 'package:im/web/utils/confirm_dialog/base_dialog.dart';

import '../../../icon_font.dart';

Future<bool> showWebConfirmDialog(
  BuildContext context, {
  @required String title,
  @required Widget body,
  double width = 800,
  double height = 400,
  String confirmText = '确定',
  TextStyle confirmStyle,
  String cancelText = '取消',
  Function onCancel,
  Function onConfirm,
  bool showCancelButton = true,
  bool showCloseIcon = false,
  bool hideFooter = false,
}) async {
  return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return WebConfirmDialog2(
            title: title,
            width: width,
            height: height,
            confirmText: confirmText,
            body: body,
            confirmStyle: confirmStyle,
            cancelText: cancelText,
            onCancel: onCancel,
            onConfirm: onConfirm,
            showCancelButton: showCancelButton,
            showCloseIcon: showCloseIcon,
            hideFooter: hideFooter);
      });
}

class WebConfirmDialog2 extends StatefulWidget {
  final String title;
  final Widget body;
  final double width;
  final double height;
  final bool showCloseIcon;
  final String confirmText;
  final String cancelText;
  final TextStyle confirmStyle;
  final Function onCancel;
  final Function onConfirm;
  final bool showCancelButton;
  final ValueNotifier<bool> disableConfirm;
  final bool showSeparator;
  final bool hideFooter;
  const WebConfirmDialog2({
    @required this.title,
    @required this.body,
    this.width = 800,
    this.height,
    this.showCloseIcon = true,
    this.confirmText = '确定',
    this.cancelText = '取消',
    this.confirmStyle,
    this.onCancel,
    this.onConfirm,
    this.showCancelButton = true,
    this.disableConfirm,
    this.showSeparator = false,
    this.hideFooter = false,
  });
  @override
  _WebConfirmDialog2State createState() => _WebConfirmDialog2State();
}

class _WebConfirmDialog2State extends State<WebConfirmDialog2> {
  ValueNotifier<bool> _disableConfirm;
  ValueNotifier<bool> _confirmLoading;

  @override
  void initState() {
    _disableConfirm = widget.disableConfirm ?? ValueNotifier(false);
    _confirmLoading = ValueNotifier(false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: WebBaseDialog(
        width: widget.width,
        height: widget.height,
        header: _header(),
        body: widget.body,
        footer: widget.hideFooter ? null : _footer(),
        showSeparator: widget.showSeparator,
      ),
    );
  }

  Widget _header() {
    final _theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              widget.title.tr ?? "",
              style: _theme.textTheme.bodyText2
                  .copyWith(fontSize: 16, fontWeight: FontWeight.w500),
            )
          ],
        ),
        Visibility(
          visible: widget.showCloseIcon,
          child: SizedBox(
            width: 24,
            height: 24,
            child: TextButton(
                onPressed: Get.back,
                child: Icon(
                  IconFont.webClose,
                  size: 20,
                  color: _theme.textTheme.bodyText1.color,
                )),
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
          child: ValueListenableBuilder<bool>(
              valueListenable: _disableConfirm,
              builder: (context, disableConfirm, child) {
                return TextButton(
                    onPressed: disableConfirm
                        ? null
                        : () async {
                              try {
                                _confirmLoading.value = true;
                                await widget.onConfirm?.call();
                                _confirmLoading.value = false;
                              } catch (e) {
                                _confirmLoading.value = false;
                              }
                            } ??
                            () => Navigator.of(context).pop(true),
                    child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: disableConfirm
                              ? const Color(0xFF6179f2).withOpacity(0.4)
                              : _theme.primaryColor,
                        ),
                        alignment: Alignment.center,
                        child: ValueListenableBuilder(
                          valueListenable: _confirmLoading,
                          builder: (context, loading, child) {
                            return loading
                                ? const SizedBox(
                                    height: 15,
                                    width: 15,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        backgroundColor: Colors.white),
                                  )
                                : Text(
                                    widget.confirmText.tr,
                                    style: widget.confirmStyle ??
                                        _theme.textTheme.bodyText2
                                            .copyWith(color: Colors.white),
                                  );
                          },
                        )));
              }),
        ),
        sizeWidth16,
        if (widget.showCancelButton)
          SizedBox(
            width: 88,
            height: 32,
            child: TextButton(
                onPressed: widget.onCancel ?? Get.back,
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
