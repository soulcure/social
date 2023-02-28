import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/web/utils/confirm_dialog/setting_dialog.dart';
import 'package:im/widgets/custom_inputbox_web.dart';

Future showEditLinkRemarkDialog(
  BuildContext context, {
  String initContent,
  Future Function(String content) saveCallback,
}) {
  return showDialog(
    context: context,
    builder: (_) => EditLinkRemarkContent(
      initContent: initContent,
      saveCallback: saveCallback,
    ),
  );
}

class EditLinkRemarkContent extends SettingDialog {
  final String initContent;
  final Future Function(String content) saveCallback;

  EditLinkRemarkContent({
    @required this.initContent,
    @required this.saveCallback,
  });

  @override
  _EditLinkRemarkContentState createState() => _EditLinkRemarkContentState();
}

class _EditLinkRemarkContentState
    extends SettingDialogState<EditLinkRemarkContent> {
  @override
  String get title => '设置备注'.tr;

  TextEditingController _remarkController;

  @override
  void initState() {
    super.initState();
    _remarkController = TextEditingController(text: widget.initContent ?? '');
  }

  @override
  bool get showSeparator => false;

  @override
  Future<void> finish() async {
    await widget.saveCallback(_remarkController.text.trim());
    Get.back();
  }

  @override
  Widget body() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: WebCustomInputBox(
        contentPadding: const EdgeInsets.fromLTRB(12, 13, 60, 13),
        controller: _remarkController,
        fillColor: Theme.of(context).backgroundColor,
        hintText: '输入备注名'.tr,
        placeholderColor: const Color(0xFFA3A8BF),
        maxLength: 12,
      ),
    );
  }
}
