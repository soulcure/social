import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:im/api/remark_api.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/themes/const.dart';
import 'package:im/web/utils/confirm_dialog/setting_dialog.dart';
import 'package:im/widgets/normal_text_input.dart';
import 'package:oktoast/oktoast.dart';

class ModifyRemarkPage extends SettingDialog {
  final String userId;
  final String nickName;
  ModifyRemarkPage({this.userId, this.nickName});

  @override
  _CreateChannelCatePageState createState() => _CreateChannelCatePageState();
}

class _CreateChannelCatePageState extends SettingDialogState<ModifyRemarkPage> {
  CancelToken token = CancelToken();
  String _value = '';
  String _initText = '';

  @override
  void initState() {
    final recordBean = Db.remarkBox.get(widget.userId);
    _initText = recordBean?.name ?? widget.nickName ?? '';
    super.initState();
  }

  @override
  void dispose() {
    token.cancel();
    super.dispose();
  }

  @override
  bool get showSeparator => false;

  @override
  String get title => '修改备注名'.tr;

  @override
  Widget body() {
    final _theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: SizedBox(
        height: 80,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('昵称'.tr, style: _theme.textTheme.bodyText1),
                sizeHeight10,
                borderWraper(
                  child: NormalTextInput(
                      initText: _initText,
                      placeHolder: "请输入备注名".tr,
                      maxCnt: 30,
                      height: 40,
                      fontSize: 14,
                      backgroundColor: Colors.transparent,
                      contentPadding: const EdgeInsets.only(bottom: 10),
                      onChanged: (value) {
                        _value = value;
                        _updateConfirmEnable();
                      }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> finish() async {
    if (loading.value) return;
    final friendId = widget.userId;
    if (friendId == null) return;

    final name = _value.trim();
    final isTextEmpty = _value.isNotEmpty && _value.trim().isEmpty;
    if (isTextEmpty) {
      showToast('备注名不能全为空格'.tr);
      return;
    }
    final userId = Global.user.id;
    loading.value = true;

    try {
      await RemarkApi.postRemarkUser(userId, friendId, name, token: token)
          .then((value) {
        loading.value = false;
        Navigator.pop(context);
      });
    } catch (e) {
      loading.value = false;
    }
  }

  void _updateConfirmEnable() {
    enable.value = !(_value.isNotEmpty && _value.trim().isEmpty);
  }
}
