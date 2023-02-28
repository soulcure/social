import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/widgets/custom_inputbox_close.dart';

Future<String> showEditStringPopup(
  BuildContext context, {
  String initContent = '',
  String title = '',
  String placeholder,
  int maxLength = 10,
  Future<void> Function(String) saveAction,
}) async {
  return showBottomModal<String>(
    context,
    resizeToAvoidBottomInset: false,
    backgroundColor: CustomColor(context).backgroundColor6,
    builder: (c, s) => SizedBox(
      height: 500,
      child: EditStringPopup(
        title: title,
        initContent: initContent,
        placeholder: placeholder,
        maxLength: maxLength,
        saveAction: saveAction,
      ),
    ),
  );
}

// 添加备注
class EditStringPopup extends StatefulWidget {
  final String title;
  final String initContent;
  final String placeholder;
  final int maxLength;
  final Future<void> Function(String) saveAction;

  const EditStringPopup({
    Key key,
    this.title,
    this.placeholder,
    this.initContent = '',
    this.maxLength,
    this.saveAction,
  }) : super(key: key);

  @override
  _EditStringPopupState createState() => _EditStringPopupState();
}

class _EditStringPopupState extends State<EditStringPopup> {
  TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final ValueNotifier<bool> _loading = ValueNotifier<bool>(false);

  bool _canBack = true; // 防抖
  bool _enable = false;

  @override
  void initState() {
    _controller = TextEditingController(text: widget.initContent);
    // 延时获取焦点，避免页面卡顿
    Future.delayed(const Duration(milliseconds: 300)).then((_) {
      if (mounted) _focusNode.requestFocus();
    });
    super.initState();
  }

  @override
  void dispose() {
    _loading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          primary: false,
          leading: IconButton(
              icon: const Icon(
                IconFont.buffNavBarCloseItem,
                size: 24,
              ),
              onPressed: () async {
                if (!_canBack) return;
                // 延时避免页面卡顿
                if (_focusNode.hasFocus) {
                  _canBack = false;
                  _focusNode.unfocus();
                  await Future.delayed(const Duration(milliseconds: 200));
                }
                Get.back();
              }),
          centerTitle: true,
          title: Text(
            widget.title,
            style: Theme.of(context).textTheme.headline5,
          ),
          elevation: 0,
          actions: [
            ValueListenableBuilder(
              valueListenable: _loading,
              builder: (context, isLoading, child) {
                return isLoading
                    ? Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: DefaultTheme.defaultLoadingIndicator(),
                      )
                    : child;
              },
              child: CupertinoButton(
                onPressed: _enable
                    ? () async {
                        _loading.value = true;
                        _focusNode.unfocus();
                        await widget.saveAction?.call(_controller.text);
                        _loading.value = false;
                      }
                    : null,
                child: Text(
                  '保存'.tr,
                  style: TextStyle(
                      color: _enable
                          ? appThemeData.primaryColor
                          : appThemeData.primaryColor.withOpacity(0.4),
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: CustomInputCloseBox(
            focusNode: _focusNode,
            borderRadius: 6,
            fillColor: appThemeData.scaffoldBackgroundColor,
            controller: _controller,
            hintText: widget.placeholder,
            hintStyle: TextStyle(
                color: appThemeData.textTheme.headline2.color, fontSize: 16),
            maxLength: widget.maxLength,
            onChange: (str) {
              _enable =
                  str.isNotEmpty && str.characters.length <= widget.maxLength;
              if (mounted) setState(() {});
            },
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }
}
