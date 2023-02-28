import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../../svg_icons.dart';

class NotInviteBottom extends StatelessWidget {
  final VoidCallback onPressed;

  const NotInviteBottom({Key key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 31),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: WebsafeSvg.asset(SvgIcons.fanbookNotInvite),
                  ),
                ),
                sizeWidth12,
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    WebsafeSvg.asset(SvgIcons.fanbookText,
                        width: 77, height: 14),
                    sizeHeight5,
                    Text(
                      '创作者协作空间'.tr,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF646A73)),
                    ),
                  ],
                ),
              ],
            ),
            MaterialButton(
              onPressed: onPressed,
              color: Get.theme.backgroundColor,
              minWidth: 84,
              height: 37,
              elevation: 0,
              child: Text('了解更多'.tr,
                  style: TextStyle(color: primaryColor, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
