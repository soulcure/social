import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/land_pop_app_bar.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../icon_font.dart';
import '../../../svg_icons.dart';

class LandCreateOrJoinServerPop extends StatelessWidget {
  final Future<bool> future;
  final Function(bool isWhite) onCreatePress;
  final VoidCallback onJoinPress;

  const LandCreateOrJoinServerPop(
      {Key key, this.future, this.onCreatePress, this.onJoinPress})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return popWrap(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LandPopAppBar(),
          SizedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FutureBuilder<bool>(
                    future: future,
                    initialData: false,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.done) {
                        final enable = snap.data ?? false;

                        /// 如果有创建服务器权限，展示"创建服务器"按钮，否则显示"申请创建服务器"按钮
                        return _customWidget(
                          title: '创建'.tr,
                          describe: '邀请玩家/好友加入，一 站式互动！'.tr,
                          icon: WebsafeSvg.asset(SvgIcons.create,
                              width: 40, height: 40),
                          butTitle: '创建服务器'.tr,
                          onPressed: () => onCreatePress(enable),
                        );
                      } else {
                        return Container();
                      }
                    }),
                _customWidget(
                  title: '加入'.tr,
                  describe: '有服务器邀请链接？在 这里使用！'.tr,
                  icon: Icon(
                    IconFont.buffInviteUser,
                    color: Get.theme.toggleableActiveColor,
                    size: 40,
                  ),
                  butTitle: '加入服务器'.tr,
                  onPressed: onJoinPress,
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 56,
          )
        ],
      ),
    );
  }

  Widget _customWidget(
      {String title,
      String describe,
      icon,
      String butTitle,
      VoidCallback onPressed}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 184,
        padding: const EdgeInsets.all(16),
        color: Get.theme.scaffoldBackgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            sizeHeight16,
            Text(
              title,
              style: Get.textTheme.headline5.copyWith(fontSize: 20),
            ),
            sizeHeight16,
            Text(
              describe,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Get.theme.disabledColor, fontSize: 14),
            ),
            sizeHeight16,
            icon,
            const SizedBox(height: 34),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TextButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      Get.theme.toggleableActiveColor),
                  minimumSize: MaterialStateProperty.all(const Size(152, 42)),
                ),
                onPressed: onPressed,
                child: Text(
                  butTitle,
                  style:
                      TextStyle(color: Get.theme.backgroundColor, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
