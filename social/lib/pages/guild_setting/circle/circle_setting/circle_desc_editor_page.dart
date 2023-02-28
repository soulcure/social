import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im/const.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/pages/guild_setting/circle/circle_setting/model/circle_management_model.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/text_field/native_input.dart';
import 'package:oktoast/oktoast.dart';

class CircleDescEditorPage extends StatefulWidget {
  final CircleInfoModel circleInfoState;

  const CircleDescEditorPage(this.circleInfoState, {Key key}) : super(key: key);

  @override
  _CircleDescEditorPageState createState() => _CircleDescEditorPageState();
}

class _CircleDescEditorPageState extends State<CircleDescEditorPage> {
  TextEditingController _textEditController;
  String _desc;
  bool _enableConfirm = true;

  @override
  void initState() {
    super.initState();
    _desc = widget.circleInfoState.description ?? "";
    _textEditController = TextEditingController.fromValue(
      TextEditingValue(text: widget.circleInfoState.description ?? ""),
    );
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _updateConfirmEnable();
    });
  }

  void _updateConfirmEnable() {
    if (mounted) {
      setState(() {
        _enableConfirm = _textEditController.text.trim().characters.length <=
            maxCircleDescLength;
      });
    }
  }

  Widget buildCount(int currentLength, int maxLength) {
    return RichText(
      text: TextSpan(
          text: '$currentLength',
          style: Theme.of(context).textTheme.bodyText1.copyWith(
                fontSize: 12,
                color: currentLength > maxLength
                    ? DefaultTheme.dangerColor
                    : const Color(0xFF8F959E),
              ),
          children: [
            TextSpan(
              text: '/$maxLength',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8F959E),
              ),
            )
          ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF0F1F2);
    return Scaffold(
      appBar: CustomAppbar(
        title: '修改简介'.tr,
        elevation: 0.5,
        backgroundColor: bgColor,
        actions: [
          AppbarTextButton(
              text: '完成'.tr,
              enable: _enableConfirm,
              onTap: _editCircleDescription)
        ],
      ),
      backgroundColor: bgColor,
      body: Container(
        height: 168,
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: NativeInput(
          maxLines: 7,
          height: 168,
          maxLengthEnforcement: MaxLengthEnforcement.none,
          decoration: InputDecoration.collapsed(
            hintText: "请描述圈子的用途、公告、规则等信息".tr,
            hintStyle: const TextStyle(color: Color(0xFF8F959E), fontSize: 17),
          ),
          maxLength: maxCircleDescLength,
          // 撑满父容器高度
          onChanged: (value) {
            _desc = value;
            _updateConfirmEnable();
          },
          controller: _textEditController,
          buildCounter: (_, {currentLength, maxLength, isFocused}) {
            return buildCount(currentLength, maxLength);
          },
          style: const TextStyle(fontSize: 17, color: Color(0xFF1F2125)),
        ),
      ),
    );
  }

  Future _editCircleDescription() async {
    final isTextEmpty = _desc.isNotEmpty && _desc.trim().isEmpty;
    if (isTextEmpty) {
      showToast('圈子简介不能全为空格'.tr);
      return;
    }
    if (_desc.characters.length > maxCircleDescLength) {
      showToast("圈子描述不能超过%s个字".trArgs([maxCircleDescLength.toString()]));
      return;
    }
    try {
      Loading.show(context);
      await widget.circleInfoState.updateCircleDesc(_desc.trim() ?? "");
      Loading.hide();
      Navigator.of(context).pop(_desc);
    } catch (e) {
      print(e);
      Loading.hide();
    }
  }
}
