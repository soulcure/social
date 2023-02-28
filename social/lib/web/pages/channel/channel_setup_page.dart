import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/web/pages/channel/channel_permission_page.dart';
import 'package:im/web/pages/channel/modify_channel_page.dart';
import 'package:im/web/widgets/button/web_hover_button.dart';
import 'package:im/web/widgets/web_form_detector/web_form_page_view.dart';
import 'package:im/web/widgets/web_form_detector/web_form_tab_item.dart';
import 'package:im/web/widgets/web_form_detector/web_form_tab_view.dart';

import '../../../routes.dart';

class ChannelSetupPage extends StatefulWidget {
  final ChatChannel channel;

  const ChannelSetupPage(this.channel);

  @override
  _ChannelSetupPageState createState() => _ChannelSetupPageState();
}

class _ChannelSetupPageState extends State<ChannelSetupPage> {
  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF0F1F2);
    return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: SizedBox(
            width: 1040,
            child: WebFormPage(
              tabItems: [
                WebFormTabItem.title(title: '频道设置'.tr),
                WebFormTabItem(
                    title: '编辑频道'.tr,
                    icon: IconFont.webChannelSetupEdit,
                    index: 0),
                WebFormTabItem(
                    title: '频道权限管理'.tr, icon: Icons.widgets_rounded, index: 1),
              ],
              tabViews: [
                WebFormTabView(
                  title: '编辑频道'.tr,
                  index: 0,
                  child: ModifyChannelPage(widget.channel),
                ),
                WebFormTabView(
                  title: '权限管理'.tr,
                  index: 1,
                  child: ChannelPermissionPage(widget.channel),
                )
              ],
              trailing: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 8, 12),
                    child: WebHoverButton(
                      color: Colors.transparent,
                      hoverColor: DefaultTheme.dangerColor.withOpacity(0.2),
                      borderRadius: 4,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      onTap: _removeChannel,
                      child: Row(
                        children: [
                          const Icon(IconFont.buffClose,
                              size: 20, color: DefaultTheme.dangerColor),
                          sizeWidth10,
                          Text(
                            '删除频道'.tr,
                            style: const TextStyle(
                                fontSize: 16, color: DefaultTheme.dangerColor),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Future<void> _removeChannel() async {
    final res = await showConfirmDialog(
        title: '删除频道'.tr,
        content: '确定将 %s 删除？一旦删除不可撤销。'.trArgs([widget.channel.name]));
    if (res == true) {
      final guildTarget =
          ChatTargetsModel.instance.selectedChatTarget as GuildTarget;
      final ChatChannel channel = guildTarget.channels.firstWhere(
          (element) => element.id == widget.channel.id,
          orElse: () => null);

      try {
        if (channel != null) await guildTarget.removeChannel(channel);
        Routes.backHome();
      } catch (e) {
        debugPrint("删除频道异常: $e");
      }
    }
  }
}
