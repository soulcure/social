import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/image_builder.dart';
import 'package:websafe_svg/websafe_svg.dart';
import 'package:im/utils/image_operator_collection/image_widget.dart';

import '../../../../../svg_icons.dart';

class InviteBottom extends StatelessWidget {
  final VoidCallback onPressed;
  final String serverName;
  final String serverImageUrl;

  const InviteBottom(
      {Key key, this.serverName, this.serverImageUrl, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 31),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            SizedBox(
              height: 76,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: ImageWidget.fromCachedNet(
                          CachedImageBuilder(
                            width: 44,
                            height: 44,
                            imageUrl: serverImageUrl,
                            cacheManager: CustomCacheManager.instance,
                          ),
                        ),
                      ),
                      sizeWidth12,
                      Text(serverName ?? '',
                          style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF363940),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  MaterialButton(
                    onPressed: onPressed,
                    color: Get.theme.backgroundColor,
                    minWidth: 54,
                    height: 37,
                    elevation: 0,
                    child: Text('??????'.tr,
                        style: TextStyle(color: primaryColor, fontSize: 15)),
                  ),
                ],
              ),
            ),
            Divider(
                height: 1,
                thickness: 1,
                color: const Color(0xFF919499).withOpacity(0.2)),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2.5),
                      child: WebsafeSvg.asset(SvgIcons.fanbookNotInvite),
                    ),
                  ),
                  sizeWidth6,
                  WebsafeSvg.asset(SvgIcons.fanbookText,
                      width: 54.5, height: 10),
                  sizeWidth5,
                  Text('- ?????????????????????'.tr,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF646A73))),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
