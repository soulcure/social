import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:websafe_svg/websafe_svg.dart';

class CertificationIcon extends StatelessWidget {
  final double size;
  final CertificationProfile profile;
  final EdgeInsetsGeometry margin;
  final bool showShadow;

  const CertificationIcon({
    Key key,
    this.size = 24,
    this.profile,
    this.margin,
    this.showShadow = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget child = WebsafeSvg.asset(
      // 'assets/icon-font/buff/other_vip.svg',
      profile.logo,
      height: 16,
      width: 16,
    );

    if (showShadow) {
      child = SimpleShadow(
        color: Colors.black.withOpacity(0.3),
        offset: const Offset(0, 0),
        child: child,
      );
    }

    return child;
  }
}

class CertificationIconWithText extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final Color textColor;
  final Color fillColor;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry padding;
  final CertificationProfile profile;
  final EdgeInsetsGeometry innerPadding;
  final EdgeInsetsGeometry margin;
  final bool showShadow;
  final bool showBg;
  final List<Shadow> shadows;

  const CertificationIconWithText({
    Key key,
    this.iconSize = 16,
    this.profile,
    this.innerPadding = const EdgeInsets.all(0),
    this.margin = const EdgeInsets.all(0),
    this.showShadow = false,
    this.fontSize = 12,
    this.textColor,
    this.fillColor,
    this.padding = const EdgeInsets.fromLTRB(6, 2, 6, 2),
    this.fontWeight = FontWeight.normal,
    this.showBg = true,
    this.shadows,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (profile == null) return sizedBox;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CertificationIcon(
          size: iconSize,
          profile: profile,
          margin: innerPadding,
          showShadow: showShadow,
        ),
        const SizedBox(
          width: 4,
        ),
        Text(
          profile.description,
          style: TextStyle(
            fontSize: fontSize,
            color: textColor ?? profile.textColor,
            fontWeight: fontWeight,
            shadows: shadows,
          ),
        )
      ],
    );
    return Container(
      height: 24,
      decoration: showBg
          ? BoxDecoration(
              color: fillColor ?? profile.fillColor,
              borderRadius: const BorderRadius.all(Radius.circular(2)))
          : null,
      padding: padding,
      margin: margin,
      child: child,
    );
  }
}

// bool get showIcon {
//   ///0=未认证  1=个人  2=企业
//   String iconType = '0';
//   final target = ChatTargetsModel.instance.selectedChatTarget;
//   if (target is GuildTarget) iconType = target.authenticate;
//   return iconType == '2';
// }

enum CertificationType {
  none,
  personal,
  officialIn,
  officialCoo,
  officialInCoo,
}

class CertificationProfile {
  final CertificationType type;
  final String description;
  final String logo;
  final Color textColor;
  final Color fillColor;

  const CertificationProfile({
    this.type,
    this.description,
    this.logo,
    this.textColor = Colors.black,
    this.fillColor = Colors.white,
  });
}

/// 默认获取当前选中服务器的认证标识
CertificationProfile get certificationProfile {
  final target = ChatTargetsModel.instance.selectedChatTarget;
  if (target is! GuildTarget) return null;
  final GuildTarget guildTarget = target;
  return certificationProfileWith(guildTarget?.authenticate ?? '');
}

/// 根据服务器认证属性获取认证标识
/// '1' 用户认证
/// '2' 官方入驻（企业认证)
/// '4' 官方合作
/// '6' 官方入驻 + 合作  优先显示入驻
CertificationProfile certificationProfileWith(String authenticate) {
  if ('1' == authenticate) {
    // TODO 有这个值，但还没方案
    return null;
  }

  if ('2' == authenticate || '6' == authenticate)
    return CertificationProfile(
      type: '2' == authenticate
          ? CertificationType.officialIn
          : CertificationType.officialInCoo,
      description: '官方入驻'.tr,
      logo: SvgIcons.officialIn,
      textColor: const Color(0xFF11CD75),
      fillColor: const Color(0xFF11CD75).withOpacity(0.15),
    );

  if ('4' == authenticate)
    return CertificationProfile(
      type: CertificationType.officialCoo,
      description: '官方合作'.tr,
      logo: SvgIcons.officialCoo,
      textColor: const Color(0xff6179F2),
      fillColor: const Color(0xff6179F2).withOpacity(0.15),
    );

  return null;
}
