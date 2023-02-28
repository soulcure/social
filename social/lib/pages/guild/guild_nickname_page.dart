import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/const.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/button/back_button.dart';
import 'package:im/widgets/custom_inputbox_close.dart';
import 'package:oktoast/oktoast.dart';

import '../../api/guild_api.dart';
import '../../db/db.dart';
import '../../global.dart';
import '../../loggers.dart';

class GuildNicknameSettingPage extends StatefulWidget {
  final String guildId;

  const GuildNicknameSettingPage({Key key, @required this.guildId})
      : super(key: key);

  @override
  _GuildNicknameSettingPageState createState() =>
      _GuildNicknameSettingPageState();
}

class _GuildNicknameSettingPageState extends State<GuildNicknameSettingPage> {
  TextEditingController _controller;
  bool _loading = false;
  bool _enableConfirm = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    final user = Db.userInfoBox.get(Global.user.id);
    final initialText = user.showName();
    Characters char = Characters(initialText ?? '');
    if (char.length >= maxServerNickNameLength) {
      char = char.getRange(0, maxServerNickNameLength);
    }
    _controller = TextEditingController(text: char.toString());
    updateEnableConfirm();
    // 延时获取焦点，避免页面卡顿
    Future.delayed(const Duration(milliseconds: 350)).then((_) {
      if (mounted) _focusNode.requestFocus();
    });
    super.initState();
  }

  void _onNicknameChange(String value) {
    updateEnableConfirm();
  }

  void updateEnableConfirm() {
    final textLen = _controller.text.trim().characters.length;
    if (mounted) {
      setState(() {
        ///服务器昵称长度：要么为空，要么限制2-12
        _enableConfirm = textLen == 0 ||
            (textLen >= minServerNickNameLength &&
                textLen <= maxServerNickNameLength);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 560,
      child: Column(
        children: [
          AppBar(
            primary: false,
            leading: CustomBackButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(context);
              },
            ),
            centerTitle: true,
            title: Text(
              '我在本服务器的昵称'.tr,
              style: Theme.of(context).textTheme.headline5,
            ),
            elevation: 0,
            actions: [
              AppbarTextButton(
                text: '确定'.tr,
                loading: _loading,
                enable: _enableConfirm,
                onTap: () async {
                  if (_loading) return;
                  final text = _controller.text;
                  final isTextEmpty = text.isNotEmpty && text.trim().isEmpty;
                  if (isTextEmpty) {
                    showToast('服务器昵称不能全为空格'.tr);
                    return;
                  }

                  //检测服务器昵称名称
                  final textRes = await CheckUtil.startCheck(
                      TextCheckItem(text, TextChannelType.CHANNEL_NAME),
                      toastError: false);
                  if (!textRes) {
                    showToast('此内容包含违规信息,请修改后重试'.tr);
                    return;
                  }

                  changeLoading(true);
                  try {
                    await GuildApi.setGuildNickname(widget.guildId, nick: text);
                    final user = Db.userInfoBox.get(Global.user.id);
                    if (text.isNotEmpty)
                      user.updateGuildNickNames({widget.guildId: text});
                    else
                      user.removeGuildNickName(widget.guildId);
                    Get.back();
                  } catch (e) {
                    logger.finer('修改服务器昵称失败:$e');
                  } finally {
                    changeLoading(false);
                  }
                },
              )
            ],
          ),
          buildBody(context),
        ],
      ),
    );
  }

  Widget buildBody(BuildContext context) {
    return Container(
      // margin: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: CustomInputCloseBox(
        focusNode: _focusNode,
        borderRadius: 6,
        fillColor: const Color(0xFFF5F5F8),
        controller: _controller,
        hintText: '请输入昵称'.tr,
        hintStyle: const TextStyle(color: Color(0xFF8F959E), fontSize: 16),
        maxLength: maxServerNickNameLength,
        onChange: _onNicknameChange,
      ),
    );
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void changeLoading(bool isLoading) {
    if (isLoading == _loading) return;
    _loading = isLoading;
    refresh();
  }
}
