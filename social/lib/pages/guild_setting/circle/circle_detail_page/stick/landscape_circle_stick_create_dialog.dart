import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/themes/const.dart';
import 'package:im/web/utils/confirm_dialog/confirm_dialog.dart';
import 'package:im/web/widgets/radio.dart';
import 'package:im/widgets/custom_inputbox_web.dart';

Future<Map<String, String>> showLandscapeCircleStickCreateDialog(
    BuildContext context,
    {String title}) async {
  return showDialog(
      context: context,
      builder: (context) => LandscapeCircleStickCreateDialog(
            title: title,
          ));
}

class LandscapeCircleStickCreateDialog extends StatefulWidget {
  final String title;

  const LandscapeCircleStickCreateDialog({this.title});

  @override
  _LandscapeCircleStickCreateDialogState createState() =>
      _LandscapeCircleStickCreateDialogState();
}

class _LandscapeCircleStickCreateDialogState
    extends State<LandscapeCircleStickCreateDialog> {
  int _selectValue = 0;
  TextEditingController _controller;
  final ValueNotifier<bool> _disableConfirm = ValueNotifier(true);

  @override
  void initState() {
    _controller = TextEditingController(text: widget.title ?? "");
    _updateConfirmEnable(_controller.text);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WebConfirmDialog2(
      title: '设置置顶'.tr,
      width: 440,
      confirmText: '保存'.tr,
      disableConfirm: _disableConfirm,
      onCancel: () => Get.back,
      onConfirm: () => Navigator.of(context).pop({
        "type": _selectValue.toString(),
        "title": _controller.text.trim(),
      }),
      body: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  _buildRadioItem(0, '精华'.tr),
                  sizeWidth32,
                  _buildRadioItem(1, '活动'.tr),
                  sizeWidth32,
                  _buildRadioItem(2, '公告'.tr),
                ],
              ),
            ),
            sizeHeight12,
            Text(
              '置顶标题'.tr,
              style: Theme.of(context).textTheme.bodyText1,
            ),
            sizeHeight8,
            WebCustomInputBox(
              controller: _controller,
              fillColor: Theme.of(context).backgroundColor,
              hintText: '请输入置顶标题'.tr,
              placeholderColor: const Color(0xFF919499),
              maxLength: 20,
              onChange: _updateConfirmEnable,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioItem(int value, String content) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectValue = value;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          WebRadio(
            value: _selectValue,
            groupValue: value,
            onChanged: (value) {},
          ),
          sizeWidth16,
          Text(
            content.tr,
            style: Theme.of(context).textTheme.bodyText2,
          ),
        ],
      ),
    );
  }

  void _updateConfirmEnable(String value) {
    _disableConfirm.value = value.trim().isEmpty;
  }
}
