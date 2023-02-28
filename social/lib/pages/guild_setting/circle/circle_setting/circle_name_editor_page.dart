import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/const.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/pages/guild_setting/circle/circle_setting/model/circle_management_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/text_field/native_input.dart';
import 'package:oktoast/oktoast.dart';

class CircleNameEditorPage extends StatefulWidget {
  final CircleInfoModel circleInfoState;

  const CircleNameEditorPage(this.circleInfoState, {Key key}) : super(key: key);

  @override
  _CircleNameEditorPageState createState() => _CircleNameEditorPageState();
}

class _CircleNameEditorPageState extends State<CircleNameEditorPage> {
  String _name;

  int get _currentCount {
    if (_name == null)
      return 0;
    else
      return _name.characters.length;
  }

  bool get _canSave =>
      _name.characters.isNotEmpty &&
      _name.characters.length <= maxCircleNameLength;

  TextEditingController _textEditController;

  @override
  void initState() {
    super.initState();
    _name = widget.circleInfoState.circleName;
    _textEditController = TextEditingController.fromValue(
      TextEditingValue(text: widget.circleInfoState.circleName ?? ""),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF0F1F2);
    return Scaffold(
      appBar: CustomAppbar(
        title: '设置名称'.tr,
        elevation: 0.5,
        backgroundColor: bgColor,
        actions: [
          AppbarTextButton(
            text: '完成'.tr,
            onTap: _editCircleName,
            enable: _canSave,
          )
        ],
      ),
      backgroundColor: bgColor,
      body: Container(
        height: 52,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: NativeInput(
                style: const TextStyle(fontSize: 17, color: Color(0xFF1F2125)),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: "",
                ),
                maxLength: maxCircleNameLength,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                controller: _textEditController,
                onChanged: (value) {
                  // if (value.characters.length > _total) {
                  //   value = value.substring(0, _total);
                  //   _textEditController.value = TextEditingValue(
                  //     text: _name,
                  //     selection: TextSelection.collapsed(offset: _total),
                  //   );
                  // }
                  setState(() => _name = value);
                },
              ),
            ),
            sizeWidth8,
            RichText(
              text: TextSpan(
                  text: '$_currentCount',
                  style: TextStyle(
                    fontSize: 12,
                    color: _currentCount > maxCircleNameLength
                        ? Theme.of(context).errorColor
                        : const Color(0xFF8F959E),
                  ),
                  children: const [
                    TextSpan(
                      text: '/$maxCircleNameLength',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8F959E)),
                    )
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  Future _editCircleName() async {
    if (_name.noValue || _name.trim().noValue) {
      showToast("圈子名称不能为空".tr);
      return;
    }

    if (_name.trim().characters.length > maxCircleNameLength) {
      showToast("圈子名称不能超过%s个字".trArgs([maxCircleNameLength.toString()]));
      return;
    }

    try {
      Loading.show(context);
      await widget.circleInfoState.updateCircleName(_name.trim());
      Get.back();
      Loading.hide();
    } catch (e) {
      print(e);
      Loading.hide();
    }
  }
}
