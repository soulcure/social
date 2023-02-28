import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/home/views/components/chat_index/guild_banner/guild_banner_state.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/widgets/certification_icon.dart';
import 'package:im/widgets/mouse_hover_builder.dart';
import '../guild_member_statistics.dart';
import 'guild_banner_title.dart';

class LandscapeGuildBannerState extends GuildBannerState {
  RxBool more = false.obs;

  @override
  Widget build(BuildContext context) {
    if (widget.target == null) return _buildDirectMessageListHeader();
    final color = needShowBanner ? Colors.white : Get.textTheme.bodyText2.color;

    return AspectRatio(
        aspectRatio: 2,
        child: Stack(children: [
          if (needShowBanner) buildBackground(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Column(
              children: [
                MouseHoverBuilder(
                  builder: (context, selected) => FadeButton(
                    decoration: BoxDecoration(
                        color: selected ? Colors.black.withOpacity(.5) : null,
                        borderRadius: BorderRadius.circular(4)),
                    onTap: () => showGuildMenu(context),
                    padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(),
                        CertificationIconWithText(
                          profile: certificationProfile,
                          textColor: Colors.white,
                          fillColor: const Color(0xff1F2125).withOpacity(0.5),
                          showBg: false,
                          padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                          fontWeight: FontWeight.w500,
                          showShadow: true,
                          shadows: [
                            if (needShowBanner)
                              const Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GuildMemberStatistics(
                    guildId: widget.target.id,
                    needShadow: needShowBanner,
                    dotColor: color,
                    textStyle: TextStyle(
                      color: color,
                      fontSize: 12,
                    ),
                  ),
                )
              ],
            ),
          ),
        ]));
  }

  @override
  Future showGuildMenu(BuildContext context) async {
    more.value = true;
    await super.showGuildMenu(context);
    more.value = false;
  }

  @override
  Widget buildMenuIcon() {
    return ObxValue<RxBool>(
      (data) => Icon(
        data.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        size: 16,
        color: needShowBanner
            ? Colors.white
            : Theme.of(context).textTheme.bodyText2.color,
      ),
      more,
    );
  }

  Container _buildDirectMessageListHeader() {
    return Container(
      height: 56,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 16, top: 16, right: 12, bottom: 16),
      child: Text(
        '频道'.tr,
        style: Theme.of(context).textTheme.headline5.copyWith(height: 1.1),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Expanded(
          child: GuildBannerName(
              style: Get.textTheme.bodyText2
                  .copyWith(color: Colors.white, fontSize: 17),
              textShadows: const [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 2,
                )
              ]),
        ),
        buildMenuIcon(),
      ],
    );
  }
}
