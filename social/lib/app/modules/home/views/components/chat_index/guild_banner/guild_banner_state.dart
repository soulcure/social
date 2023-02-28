import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/image_builder.dart';
import 'package:im/utils/image_operator_collection/image_widget.dart';
import 'package:im/widgets/guild_popup.dart';
import 'package:im/widgets/shape/bubble_shape_border.dart';
import 'package:pedantic/pedantic.dart';

import 'guild_banner.dart';

abstract class GuildBannerState extends State<GuildBanner> {
  RxBool tipVisible;

  @override
  void initState() {
    tipVisible = RxBool(SpService.to.getBool(SP.guildNotification) ?? true);
    super.initState();
  }

  bool get needShowBanner => widget.target.banner.hasValue;

  Future showGuildMenu(BuildContext context) async {
    if (tipVisible.value) {
      tipVisible.value = false;
      unawaited(SpService.to.setBool(SP.guildNotification, false));
    }
    await showGuildPopUp(context,
        ChatTargetsModel.instance.selectedChatTarget.id.toString(), null);
  }

  Widget buildMenuIcon();

  Widget buildTip(BuildContext context) {
    return ObxValue<RxBool>((data) {
      return Visibility(
        visible: data.value,
        child: Container(
          width: 164,
          height: 40,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: Theme.of(context).primaryColor,
            shape: const BubbleShapeBorder(
              anglePositionX: 151,
            ),
          ),
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '在这里设置频道消息提醒'.tr,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      );
    }, tipVisible);
  }

  Widget buildBackground(BuildContext context) {
    return Positioned.fill(
      child: ValueListenableBuilder(
          valueListenable: widget.target.bannerNotifier,
          builder: (ctx, value, child) {
            return Container(
              width: MediaQuery.of(context).size.width,
              foregroundDecoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0),
                ], begin: Alignment.topCenter, end: Alignment.center),
              ),
              child: ImageWidget.fromCachedNet(
                CachedImageBuilder(
                    imageUrl: value ?? '',
                    cacheManager: CustomCacheManager.instance,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 250),
                    fadeOutDuration: const Duration(milliseconds: 500),
                    placeholder: (context, _) {
                      return Image.asset(
                        'assets/images/guild_background.jpg',
                        fit: BoxFit.cover,
                      );
                    }),
              ),
            );
          }),
    );
  }
}
