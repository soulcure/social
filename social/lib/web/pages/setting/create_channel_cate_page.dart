import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:im/api/channel_api.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/utils/confirm_dialog/confirm_dialog.dart';
import 'package:im/widgets/custom_inputbox_web.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

class CreateChannelCatePage extends StatefulWidget {
  final String guildId;
  final ChatChannel channelCate;
  const CreateChannelCatePage({@required this.guildId, this.channelCate});
  @override
  _CreateChannelCatePageState createState() => _CreateChannelCatePageState();
}

class _CreateChannelCatePageState extends State<CreateChannelCatePage> {
  final ValueNotifier<bool> _disableConfirm = ValueNotifier(true);
  TextEditingController _controller;
  @override
  void initState() {
    _controller = TextEditingController(text: widget.channelCate?.name ?? "");
    _updateConfirmEnable();
    super.initState();
  }

  Future<void> _onConfirm() async {
    final cateName = _controller.text.trim();
    if (cateName == widget.channelCate?.name) {
      Routes.pop(context);
      return;
    }
    if (cateName.isEmpty) return;
    final guild = ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
    if (widget.channelCate != null) {
      // 编辑
      await ChannelApi.updateChannel(
        Global.user.id,
        widget.channelCate.guildId,
        widget.channelCate.id,
        name: cateName,
      );
      final ChatChannel channelCate = guild.channels.firstWhere(
          (element) => element.id == widget.channelCate.id,
          orElse: () => null);
      if (channelCate != null) {
        channelCate.name = cateName;
      }
      unawaited(Db.channelBox.put(channelCate.id, channelCate));
    } else {
      // 新增
      final res = await ChannelApi.createChannel(widget.guildId, Global.user.id,
          cateName, ChatChannelType.guildCategory, '');
      showToast('创建成功'.tr);
      final channelId = res['channel_id'];
      if (res != null && isNotNullAndEmpty(channelId)) {
        final channel = ChatChannel(
            id: channelId,
            guildId: widget.guildId,
            name: cateName,
            type: ChatChannelType.guildCategory,
            parentId: '');
        guild
          ..channelOrder.add(channelId)
          ..addChannel(channel);
        unawaited(Db.channelBox.put(channel.id, channel));
      }
    }
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    guild.notifyListeners();
    Routes.pop(context);
  }

  void _updateConfirmEnable() {
    _disableConfirm.value = _controller.text.trim().isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData _theme = Theme.of(context);
    return WebConfirmDialog2(
      width: 440,
      title: widget.channelCate == null ? '创建频道分类'.tr : '编辑频道分类'.tr,
      disableConfirm: _disableConfirm,
      showCancelButton: false,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('分类名称'.tr, style: _theme.textTheme.bodyText1),
            sizeHeight10,
            WebCustomInputBox(
              controller: _controller,
              fillColor: _theme.backgroundColor,
              hintText: '输入分类名称'.tr,
              placeholderColor: const Color(0xFF919499),
              maxLength: 30,
              onChange: (val) {
                _updateConfirmEnable();
              },
            ),
          ],
        ),
      ),
      onConfirm: _onConfirm,
    );
  }
}
