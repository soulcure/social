import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/channel_api.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/custom_inputbox.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

class UpdateChannelCatePage extends StatefulWidget {
  final String guildId;
  final ChatChannel channelCate;

  const UpdateChannelCatePage(this.guildId, {this.channelCate});

  @override
  _UpdateChannelCatePageState createState() => _UpdateChannelCatePageState();
}

class _UpdateChannelCatePageState extends State<UpdateChannelCatePage> {
  TextEditingController _nameController;
  bool _loading = false;
  bool _enableConfirm = false;

  @override
  void initState() {
    _nameController =
        TextEditingController(text: widget.channelCate?.name ?? '');
    super.initState();
    _updateConfirmEnable();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: CustomAppbar(
          title: widget.channelCate == null ? '创建频道分类'.tr : '编辑分类名称'.tr,
          actions: [
            AppbarTextButton(
              text: '确定'.tr,
              loading: _loading,
              enable: _enableConfirm,
              onTap: _onConfirm,
            )
          ],
        ),
        body: ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, bottom: 8),
              child: Text(
                '分类名称'.tr,
                style: _theme.textTheme.bodyText1.copyWith(fontSize: 13),
              ),
            ),
            CustomInputBox(
              controller: _nameController,
              fillColor: _theme.backgroundColor,
              hintText: '输入分类名称'.tr,
              hintStyle:
                  const TextStyle(fontSize: 16, color: Color(0xff8F959E)),
              maxLength: 30,
              onChange: (val) {
                _updateConfirmEnable();
              },
            ),
            sizeHeight32,
          ],
        ),
      ),
    );
  }

  Future<void> _onConfirm() async {
    FocusScope.of(context).unfocus();
    final cateName = _nameController.text.trim();
    if (cateName == widget.channelCate?.name) {
      Routes.pop(context);
      return;
    }
    if (cateName.isEmpty) return;
    _toggleLoading(true);
    try {
      final guild = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
      if (widget.channelCate != null) {
        // 编辑
        final auditResult = await ChannelApi.updateChannel(
          Global.user.id,
          widget.channelCate.guildId,
          widget.channelCate.id,
          name: cateName,
        );
        _toggleLoading(false);
        if (auditResult == null) {
          return;
        }

        final ChatChannel channelCate = guild.channels.firstWhere(
            (element) => element.id == widget.channelCate.id,
            orElse: () => null);
        if (channelCate != null) {
          channelCate.name = cateName;
        }
        unawaited(Db.channelBox.put(channelCate.id, channelCate));
      } else {
        // 新增
        final res = await ChannelApi.createChannel(widget.guildId,
            Global.user.id, cateName, ChatChannelType.guildCategory, '');
        _toggleLoading(false);
        final channelId = res['channel_id'];
        if (res != null && isNotNullAndEmpty(channelId)) {
          showToast('创建成功'.tr);
          final channel = ChatChannel(
              id: channelId,
              guildId: widget.guildId,
              name: cateName,
              type: ChatChannelType.guildCategory,
              parentId: '');
          final guild =
              ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
          guild
            ..channelOrder.add(channelId)
            ..addChannel(channel);
          unawaited(Db.channelBox.put(channel.id, channel));
        }
      }
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      guild.notifyListeners();
      Routes.pop(context);
    } catch (e) {
      _toggleLoading(false);
    }
  }

  void _toggleLoading(bool value) {
    setState(() {
      _loading = value;
    });
  }

  void _updateConfirmEnable() {
    final nameLen = _nameController.text.trim().characters.length;
    setState(() {
      _enableConfirm = nameLen > 0 && nameLen <= 30;
    });
  }
}
