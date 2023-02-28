import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/bot_info.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';

class BotCommandCardItem extends StatelessWidget {
  final BotCommandItem command;
  final bool showUseBtn;
  final bool showSetBtn;
  final VoidCallback onUse;
  final VoidCallback onSet;
  const BotCommandCardItem({
    Key key,
    @required this.command,
    this.showUseBtn = false,
    this.showSetBtn = false,
    this.onUse,
    this.onSet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(6)),
        color: Colors.white,
      ),
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        command.command,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Get.textTheme.bodyText2.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (command.isAdminVisible) _commandTag()
                  ],
                ),
                sizeHeight8,
                Text(
                  command.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF919499),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (showSetBtn || showUseBtn) ...[
            divider,
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showUseBtn)
                    Flexible(
                      child: _buttonItem(
                          icon: IconFont.buffSetting, text: '使用', onTap: onUse),
                    ),
                  if (showUseBtn && showSetBtn)
                    const VerticalDivider(indent: 6, endIndent: 6),
                  if (showSetBtn)
                    Flexible(
                      child: _buttonItem(
                          icon: IconFont.buffSetShortcutCommand,
                          text: '设置快捷指令',
                          onTap: onSet),
                    ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buttonItem(
      {@required IconData icon, @required String text, VoidCallback onTap}) {
    return FadeButton(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      onTap: onTap,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style:
            Get.textTheme.bodyText2.copyWith(color: primaryColor, fontSize: 14),
      ),
    );
  }

  Widget _commandTag() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(3)),
      child: Text(
        "管理员可见".tr,
        style: TextStyle(
            color: const Color(0xFF5C6273).withOpacity(0.75), fontSize: 10),
      ),
    );
  }
}
