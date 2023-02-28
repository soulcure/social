import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/widgets/button/back_button.dart';
import 'package:im/widgets/custom_inputbox_close.dart';
import 'package:oktoast/oktoast.dart';

Future<String> showSettingRemarkPopup(
  BuildContext context, {
  String initContent = '',
  Future<void> Function(String) saveAction,
}) async {
  return showBottomModal<String>(
    context,
    resizeToAvoidBottomInset: false,
    backgroundColor: CustomColor(context).backgroundColor6,
    builder: (c, s) => SizedBox(
      height: 500,
      child: ShareLinkSettingRemark(
        initContent: initContent,
        saveAction: saveAction,
      ),
    ),
  );
}

// 添加备注
class ShareLinkSettingRemark extends StatefulWidget {
  final Future<void> Function(String) saveAction;
  final String initContent;

  const ShareLinkSettingRemark({
    Key key,
    this.saveAction,
    this.initContent = '',
  }) : super(key: key);

  @override
  _ShareLinkSettingRemarkState createState() => _ShareLinkSettingRemarkState();
}

class _ShareLinkSettingRemarkState extends State<ShareLinkSettingRemark> {
  TextEditingController _remarkController;
  final FocusNode _focusNode = FocusNode();

  final ValueNotifier<bool> _loading = ValueNotifier<bool>(false);

  bool _canBack = true; // 防抖

  @override
  void initState() {
    _remarkController = TextEditingController(text: widget.initContent);
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
    final Widget _saveText = Text(
      '完成'.tr,
      style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 17,
          fontWeight: FontWeight.bold),
    );
    return Column(
      children: [
        AppBar(
          primary: false,
          leading: CustomBackButton(
            onPressed: () async {
              if (!_canBack) return;
              // 延时避免页面卡顿
              if (_focusNode.hasFocus) {
                _canBack = false;
                _focusNode.unfocus();
                await Future.delayed(const Duration(milliseconds: 200));
              }
              Get.back();
            },
          ),
          centerTitle: true,
          title: Text(
            '设置备注'.tr,
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
                onPressed: () async {
                  final remark = _remarkController.text.trim();
                  if (remark.characters.length > 12) {
                    showToast("备注内容限制12个字".tr);
                    return;
                  }
                  _loading.value = true;
                  _focusNode.unfocus();
                  //检测审核内容
                  if (remark.characters.isNotEmpty) {
                    //审核文字
                    final textRes = await CheckUtil.startCheck(
                        TextCheckItem(remark, TextChannelType.SERVICE_NAME),
                        toastError: false);
                    if (!textRes) {
                      showToast('此内容包含违规信息,请修改后重试'.tr);
                      return;
                    }
                  }
                  await widget.saveAction?.call(remark);
                  _loading.value = false;
                  if (widget.saveAction == null)
                    Navigator.of(context).pop(remark);
                },
                child: _saveText,
              ),
            )
          ],
        ),
        Container(
          // margin: const EdgeInsets.all(16),
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: CustomInputCloseBox(
            focusNode: _focusNode,
            // autofocus: true,
            borderRadius: 6,
            fillColor: const Color(0xFFF5F5F8),
            controller: _remarkController,
            hintText: '请输入备注内容'.tr,
            hintStyle: const TextStyle(color: Color(0xFF8F959E), fontSize: 16),
            maxLength: 12,
            onChange: (content) {},
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }
}
