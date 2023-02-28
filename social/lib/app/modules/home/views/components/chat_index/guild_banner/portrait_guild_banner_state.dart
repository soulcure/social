import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/home/views/components/chat_index/guild_banner/guild_banner_state.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/quest/fb_quest.dart';
import 'package:im/svg_icons.dart';
import 'package:im/widgets/certification_icon.dart';
import 'package:quest_system/quest_system.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../../../../icon_font.dart';
import '../guild_member_statistics.dart';

class PortraitGuildBannerState extends GuildBannerState {
  static BorderRadius borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(8), topRight: Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    final color = needShowBanner ? Colors.white : Get.textTheme.bodyText2.color;
    return GestureDetector(
      onTap: () => showGuildMenu(context),
      child: Stack(
        children: [
          buildBackground(context),
          Positioned(
            left: 12,
            top: 40,
            right: 12,
            child: CertificationIconWithText(
              profile: certificationProfile,
              textColor: Colors.white,
              fillColor: const Color(0xff1F2125).withOpacity(0.5),
              showBg: false,
              padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
              fontWeight: FontWeight.w500,
              showShadow: true,
              shadows: [
                if (needShowBanner)
                  Shadow(
                    color: Colors.black.withOpacity(.3),
                    blurRadius: 2,
                  )
              ],
            ),
          ),
          if (widget.target != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: GuildMemberStatistics(
                guildId: widget.target.id,
                needShadow: needShowBanner,
                dotColor: color,
                textStyle: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
        ],
      ),
    );
  }

  @override
  Widget buildMenuIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          IconFont.buffMoreHorizontal,
          size: 24,
          color: needShowBanner
              ? Colors.white
              : Theme.of(context).textTheme.bodyText2.color,
        ),
        QuestBuilder<Quest>.id(
            QuestId([
              QIDSegGuildQuickStart.moreGuildSettings,
              "-",
              ChatTargetsModel.instance.selectedChatTarget.id,
            ]), builder: (q) {
          if (q == null || q.status != QuestStatus.activated)
            return const SizedBox();

          return Positioned(
            top: 21,
            right: 8,
            child: _businessManagerTips(),
          );
        }),
      ],
    );
  }

  Widget _businessManagerTips() {
    return SizedBox(
      width: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          WebsafeSvg.asset(SvgIcons.guideTips,
              width: 150, color: const Color(0xFF1F2126).withOpacity(.9)),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              '更多服务器设置在这里'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
