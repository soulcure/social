import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/svg_icons.dart';
import 'package:im/widgets/button/primary_button.dart';
import 'package:im/widgets/svg_tip_widget.dart';

class CircleDetailReloadLayout extends StatelessWidget {
  final VoidCallback onPressed;

  const CircleDetailReloadLayout({Key key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgTipWidget(
              svgName: SvgIcons.noNetState,
              text: '加载失败，请重试'.tr,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              borderRadius: 18,
              onPressed: onPressed,
              label: '重新加载'.tr,
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
}

/// * 加载态-灰色圆圈
Widget loadingCircle(double size, {EdgeInsets margin}) {
  return Container(
    margin: margin ?? EdgeInsets.zero,
    width: size,
    height: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: appThemeData.dividerColor,
      ),
    ),
  );
}
