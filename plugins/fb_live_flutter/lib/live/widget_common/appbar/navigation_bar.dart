import 'package:flutter/cupertino.dart';

/// 创建者：王增阳
/// 开发者：王增阳
/// 版本：1.0
/// 创建日期：2020-02-12
///
/// AppBar封装
import 'package:flutter/material.dart';
import '../../utils/ui/frame_size.dart';

class NavigationBar extends StatelessWidget implements PreferredSizeWidget {
  const NavigationBar({
    this.title = '',
    this.showBackIcon = true,
    this.rightDMActions,
    this.backgroundColor = Colors.white,
    this.mainColor,
    this.titleW,
    this.bottom,
    this.leading,
    this.isCenterTitle = true,
    this.brightness,
    this.automaticallyImplyLeading = true,
    this.icons,
    this.elevation = 0.0,
    this.isLeftChevron = false,
  });

  final String title;
  final bool showBackIcon;
  final List<Widget>? rightDMActions;
  final Color backgroundColor;
  final Color? mainColor;
  final Widget? titleW;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final bool isCenterTitle;
  final Brightness? brightness;
  final bool automaticallyImplyLeading;
  final IconData? icons;
  final double elevation;
  final bool isLeftChevron;

  @override
  Size get preferredSize => Size(100, bottom != null ? 100 : 48);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleW ??
          Text(
            title,
            style: TextStyle(
                fontSize: FrameSize.px(17),
                fontWeight: FontWeight.w600,
                color: mainColor),
          ),
      backgroundColor: backgroundColor,
      elevation: elevation,
      // ignore: deprecated_member_use
      brightness: brightness ?? Brightness.light,
      leading: leading ??
          (showBackIcon
              ? Navigator.canPop(context)
                  ? InkWell(
                      onTap: () {
                        FocusScope.of(context).requestFocus(FocusNode());
                        Navigator.maybePop(context);
                      },
                      child: Container(
                        width: FrameSize.px(40),
                        height: FrameSize.px(40),
                        color: Colors.transparent,
                        alignment: Alignment.center,
                        child: icons != null
                            ? Icon(icons, color: mainColor)
                            : Image(
                                width: FrameSize.px(20),
                                height: FrameSize.px(20),
                                fit: BoxFit.cover,
                                color: mainColor,
                                image: AssetImage(isLeftChevron
                                    ? "assets/live/main/ic_left_chevron.png"
                                    : "assets/live/CreateRoom/close_black_btn.png"),
                              ),
                      ),
                    )
                  : null
              : null),
      centerTitle: isCenterTitle,
      bottom: bottom,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: rightDMActions ?? [const Center()],
    );
  }
}
