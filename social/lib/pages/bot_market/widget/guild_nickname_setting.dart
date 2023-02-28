import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/bot_api.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/const.dart';
import 'package:im/db/db.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/custom_inputbox.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import '../../../loggers.dart';

Future showGuildNicknameSettingPopup(BuildContext context,
    {@required String guildId, @required String botId}) {
  return showBottomModal(context,
      backgroundColor: Get.theme.backgroundColor,
      resizeToAvoidBottomInset: false,
      builder: (c, s) => _GuildNicknameSetting(
            guildId: guildId,
            botId: botId,
          ));
}

class _GuildNicknameSetting extends StatefulWidget {
  final String guildId;
  final String botId;

  const _GuildNicknameSetting(
      {Key key, @required this.guildId, @required this.botId})
      : super(key: key);

  @override
  _GuildNicknameSettingState createState() => _GuildNicknameSettingState();
}

class _GuildNicknameSettingState extends State<_GuildNicknameSetting> {
  TextEditingController _controller;
  FocusNode _focusNode;
  AppBarTextPureActionModel _appBarActionModel;
  @override
  void initState() {
    _appBarActionModel = AppBarTextPureActionModel(
      "保存",
      actionBlock: onConfirm,
    );
    final user = Db.userInfoBox.get(widget.botId);
    final guildNickname = user?.guildNickname(widget.guildId) ?? '';
    Characters char = guildNickname.characters;
    if (char.length >= maxServerNickNameLength) {
      char = char.getRange(0, maxServerNickNameLength);
    }
    _controller = TextEditingController(text: char.toString());
    updateEnableConfirm();
    _focusNode = FocusNode();

    /// 解决SlidingSheet组件里面使用原生输入框，并且自动聚焦的时候，内容会滑动，所以延迟聚焦
    delay(() {
      _focusNode.requestFocus();
    }, 350);
    super.initState();
  }

  void _onNicknameChange(String value) {
    updateEnableConfirm();
  }

  void updateEnableConfirm() {
    final textLen = _controller.text.trim().characters.length;
    if (mounted) {
      setState(() {
        _appBarActionModel.isEnable = textLen <= maxServerNickNameLength;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildBody(context);
  }

  Widget buildBody(BuildContext context) {
    return SizedBox(
      height: 560,
      child: Column(
        children: [
          FbAppBar.forSheet(
            "修改机器人昵称",
            pageStep: 0,
            actions: [_appBarActionModel],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomInputBox(
              focusNode: _focusNode,
              fillColor: Get.theme.scaffoldBackgroundColor,
              borderRadius: 8,
              controller: _controller,
              hintText: '请输入昵称'.tr,
              maxLength: maxServerNickNameLength,
              onChange: _onNicknameChange,
            ),
          ),
        ],
      ),
    );
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void changeLoading(bool isLoading) {
    if (isLoading == _appBarActionModel.isLoading) return;
    _appBarActionModel.isLoading = isLoading;
    refresh();
  }

  Future<void> onConfirm() async {
    if (_appBarActionModel.isLoading) return;
    final text = _controller.text;
    final isTextEmpty = text.isNotEmpty && text.trim().isEmpty;
    if (isTextEmpty) {
      showToast('服务器昵称不能全为空格'.tr);
      return;
    }
    changeLoading(true);
    try {
      //检测服务器昵称名称
      final textRes = await CheckUtil.startCheck(
          TextCheckItem(text, TextChannelType.CHANNEL_NAME),
          toastError: false);
      if (!textRes) {
        changeLoading(false);
        showToast('此内容包含违规信息,请修改后重试'.tr);
        return;
      }
      await BotApi.setBotGuildNickname(widget.guildId, widget.botId, text);
      unawaited(UserInfo.get(widget.botId).then((user) {
        if (text.isNotEmpty)
          user?.updateGuildNickNames({widget.guildId: text});
        else
          user?.removeGuildNickName(widget.guildId);
      }));

      changeLoading(false);
      Get.back();
    } catch (e) {
      logger.finer('修改服务器昵称失败:$e');
    } finally {
      changeLoading(false);
    }
  }
}
