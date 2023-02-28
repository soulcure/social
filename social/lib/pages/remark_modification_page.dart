import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:im/api/remark_api.dart';
import 'package:im/const.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/custom_inputbox.dart';
import 'package:oktoast/oktoast.dart';

import '../icon_font.dart';

/// UI 蓝湖：https://lanhuapp.com/web/#/item/project/board?pid=7a57b75d-f37e-49b8-98d9-6a7d29a1cc68
class RemarkModificationPage extends StatefulWidget {
  final String userId;

  const RemarkModificationPage(this.userId);

  @override
  _RemarkModificationPageState createState() => _RemarkModificationPageState();
}

class _RemarkModificationPageState extends State<RemarkModificationPage> {
  TextEditingController _controller;
  CancelToken token = CancelToken();
  bool _loading = false;
  bool _enableConfirm = false;

  @override
  void initState() {
    final user = Db.userInfoBox.get(widget.userId);
    final recordBean = Db.remarkBox.get(widget.userId);
    final remarkName = recordBean?.name;
    final isRemarkNameEmpty = remarkName == null || remarkName.isEmpty;
    // todo 优先显示备注名
    _controller = TextEditingController(
        text: isRemarkNameEmpty ? user.nickname : remarkName);
    updateEnableConfirm();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    token.cancel();
    super.dispose();
  }

  void _onNicknameChange(String value) {
    updateEnableConfirm();
  }

  void updateEnableConfirm() {
    final textLen = _controller.text.trim().characters.length;
    if (mounted) {
      setState(() {
        _enableConfirm = textLen <= maxFriendRemarkLength;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppbar(
        leadingIcon: IconFont.buffNavBarCloseItem,
        leadingCallback: () {
          FocusScope.of(context).unfocus();
          Navigator.pop(context);
        },
        title: '设置备注名'.tr,
        actions: [
          AppbarTextButton(
            loading: _loading,
            enable: _enableConfirm,
            onTap: () async {
              if (_loading) return;
              final friendId = widget.userId;
              if (friendId == null) return;
              final text = _controller.text;
              final isTextEmpty = text.isNotEmpty && text.trim().isEmpty;
              if (isTextEmpty) {
                showToast('备注名不能全为空格'.tr);
                return;
              }

              //审核文字
              final textRes = await CheckUtil.startCheck(
                  TextCheckItem(text, TextChannelType.NICKNAME),
                  toastError: false);
              if (!textRes) {
                showToast('此内容包含违规信息,请修改后重试'.tr);
                return;
              }

              final userId = Global.user.id;
              _loading = true;
              if (mounted) setState(() {});
              await RemarkApi.postRemarkUser(userId, friendId, text.trim(),
                      token: token)
                  .then((value) {
                _loading = false;
                if (mounted) setState(() {});
                if (value != null) {
                  Navigator.pop(context);
                }
              });
            },
            text: '确定'.tr,
          ),
        ],
      ),
      body: buildBody(context),
    );
  }

  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        CustomInputBox(
          fillColor: CustomColor(context).backgroundColor2,
          controller: _controller,
          hintText: '请输入备注名'.tr,
          maxLength: maxFriendRemarkLength,
          onChange: _onNicknameChange,
        ),
      ],
    );
  }
}
