import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/custom_inputbox.dart';
import 'package:oktoast/oktoast.dart';

import '../../../global.dart';
import '../../../icon_font.dart';
import '../../../loggers.dart';

class GuildEditNamePage extends StatefulWidget {
  final String guildId;

  const GuildEditNamePage({Key key, @required this.guildId}) : super(key: key);

  @override
  _GuildEditNamePageState createState() => _GuildEditNamePageState();
}

class _GuildEditNamePageState extends State<GuildEditNamePage> {
  TextEditingController controller;
  String name = '';
  GuildTarget target;
  bool loading = false;

  @override
  void initState() {
    target = ChatTargetsModel.instance.getChatTarget(widget.guildId);
    name = target.name;
    controller = TextEditingController(text: name);
    controller.addListener(refresh);
    super.initState();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(refresh);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppbar(
        title: '设置名称'.tr,
        leadingIcon: IconFont.buffNavBarCloseItem,
        actions: [
          AppbarTextButton(
            text: '完成'.tr,
            enable: canSubmit,
            loading: loading,
            onTap: () async {
              if (!canSubmit) return;
              if (name == null ||
                  name.isEmpty ||
                  name.replaceAll(' ', '') == '') {
                showToast('服务器名称不能为空'.tr);
                return;
              }
              try {
                _toggleLoading(true);
                await GuildApi.updateGuildInfo(
                  widget.guildId,
                  Global.user.id,
                  name: name.trim(),
                  showDefaultErrorToast: true,
                );
                target.updateInfo(name: name.trim());
                _toggleLoading(false);
                Get.back();
              } catch (e) {
                _toggleLoading(false);
                if (e is DioError && e.type != DioErrorType.cancel)
                  logger.warning('服务器名字设置失败:$e');
              }
            },
          )
        ],
      ),
      body: ListView(
        children: [
          sizeHeight16,
          CustomInputBox(
            controller: controller,
            fillColor: theme.backgroundColor,
            hintText: '请输入服务器名称'.tr,
            hintStyle: const TextStyle(fontSize: 16, color: Color(0xff8F959E)),
            maxLength: 30,
            onChange: (val) {
              setState(() {
                name = val;
              });
            },
          ),
        ],
      ),
    );
  }

  bool get canSubmit =>
      (controller.text != null) &&
      controller.text.isNotEmpty &&
      controller.text.trim().characters.length <= 30;

  void _toggleLoading(bool val) {
    setState(() {
      loading = val;
    });
  }
}
